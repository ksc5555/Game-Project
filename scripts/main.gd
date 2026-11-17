extends Node2D
# Builds the whole lane in code and runs the rules: coins, day and night,
# demon waves, win and lose. Tuning numbers are in cfg.gd.

const Cfg = preload("res://scripts/cfg.gd")
const PlayerS = preload("res://scripts/player.gd")
const AllyS = preload("res://scripts/ally.gd")
const DemonS = preload("res://scripts/demon.gd")
const BuilderS = preload("res://scripts/builder.gd")
const BuildingS = preload("res://scripts/building.gd")
const CoinS = preload("res://scripts/coin.gd")
const ProjS = preload("res://scripts/projectile.gd")
const FxS = preload("res://scripts/fx.gd")
const BackdropS = preload("res://scripts/backdrop.gd")
const HudS = preload("res://scripts/hud.gd")

const NIGHT_TINT := Color(0.6, 0.64, 0.92)

var coins := 0
var day := 1
var is_day := true
var phase_t := 0.0
var game_over := false
var night_amt := 0.0
var pay_t := 0.0
var spawn_queue: Array = []

var player
var keep
var buildings := {}
var party: Array = []
var garrison: Array = []

var cam: Camera2D
var tint: CanvasModulate
var hud
var l_build: Node2D
var l_coins: Node2D
var l_units: Node2D
var l_fx: Node2D


func _ready() -> void:
	randomize()
	_setup_input()

	var bg = BackdropS.new()
	add_child(bg)
	l_build = _layer()
	l_coins = _layer()
	l_units = _layer()
	l_fx = _layer()
	tint = CanvasModulate.new()
	add_child(tint)
	cam = Camera2D.new()
	cam.position = Vector2(40, -100)
	add_child(cam)
	cam.make_current()
	bg.cam = cam
	hud = HudS.new()
	add_child(hud)

	for key in Cfg.BUILDINGS:
		var b = BuildingS.new()
		l_build.add_child(b)
		b.setup(self, key)
		buildings[key] = b
	keep = buildings["keep"]
	for pr in Cfg.PROPS:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/props/%s.png" % pr[0])
		sp.centered = false
		sp.offset = Vector2(-sp.texture.get_width() / 2.0, -sp.texture.get_height() + 1)
		sp.position = Vector2(pr[1], 0)
		l_build.add_child(sp)
		var tw := sp.create_tween().set_loops()
		tw.tween_property(sp, "modulate", Color(1.15, 1.05, 0.95), 0.18)
		tw.tween_property(sp, "modulate", Color(0.92, 0.9, 0.9), 0.23)

	player = PlayerS.new()
	l_units.add_child(player)
	player.setup(self)
	player.position.x = keep.position.x + 220.0

	for i in Cfg.PARTY.size():
		var a = AllyS.new()
		l_units.add_child(a)
		a.setup(self, Cfg.PARTY[i][0], Cfg.PARTY[i][1], true, i)
		a.position.x = keep.position.x + 200.0 - i * 13.0
		party.append(a)

	for i in 2:
		var w = BuilderS.new()
		l_units.add_child(w)
		w.setup(self, keep.position.x + 40.0 - i * 14.0)

	coins = Cfg.START_COINS
	hud.flash("Day 1 - build before nightfall", 3.5)

	if OS.has_environment("DW_AUTOTEST"):
		add_child(load("res://tests/autotest.gd").new())


func _layer() -> Node2D:
	var n := Node2D.new()
	add_child(n)
	return n


func _setup_input() -> void:
	# Actions are made here so touch buttons can press the same actions later.
	_action("move_left", [KEY_A, KEY_LEFT])
	_action("move_right", [KEY_D, KEY_RIGHT])
	_action("sprint", [KEY_SHIFT])
	_action("attack", [KEY_SPACE])
	_action("block", [KEY_S, KEY_DOWN])
	_action("interact", [KEY_E])
	_action("skip", [KEY_N])
	_action("restart", [KEY_R])


func _action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _process(dt: float) -> void:
	_camera(dt)
	_tint(dt)
	hud.refresh(self, dt)
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return

	phase_t += dt
	if is_day:
		if phase_t >= Cfg.DAY_LEN or Input.is_action_just_pressed("skip"):
			_start_night()
	else:
		while not spawn_queue.is_empty() and float(spawn_queue[0].t) <= phase_t:
			_spawn_demon(spawn_queue.pop_front().kind)
		if phase_t >= Cfg.NIGHT_LEN:
			_start_day()
	_paying(dt)


# ---------------- day / night ----------------

func _start_night() -> void:
	is_day = false
	phase_t = 0.0
	spawn_queue.clear()
	var w: Dictionary = Cfg.wave(day)
	var packs: int = Cfg.packs(day)
	var gap: float = Cfg.NIGHT_LEN * 0.6 / packs
	for kind in w:
		for i in int(w[kind]):
			var pack := i % packs
			spawn_queue.append({"t": 2.0 + pack * gap + randf_range(0.0, 3.5), "kind": kind})
	spawn_queue.sort_custom(func(a, b): return a.t < b.t)
	hud.flash("Night %d" % day)


func _start_day() -> void:
	is_day = true
	phase_t = 0.0
	if day >= Cfg.NIGHTS_TO_WIN:
		_end("VICTORY\nThe keep held for %d nights.   R to play again" % Cfg.NIGHTS_TO_WIN)
		return
	day += 1
	hud.flash("Day %d" % day)
	spawn_coin(keep.position.x + 20.0, Cfg.DAWN_PAYOUT)
	for a in party:
		if a.dead:
			a.revive(keep.position.x + 20.0)


func _spawn_demon(kind: String) -> void:
	var d = DemonS.new()
	l_units.add_child(d)
	d.setup(self, kind)
	d.position.x = Cfg.SPAWN_X + randf_range(0.0, 20.0)


func defeat() -> void:
	_end("DEFEAT\nThe keep has fallen.   R to try again")


func _end(text: String) -> void:
	if game_over:
		return
	game_over = true
	hud.flash(text, 9999.0)


# ---------------- coins and paying ----------------

func _paying(dt: float) -> void:
	pay_t = maxf(0.0, pay_t - dt)
	var best = null
	var best_d := 1e9
	for b in buildings.values():
		b.focused = false
		if player.dead or b.offer().is_empty():
			continue
		var d := absf(b.position.x - player.position.x)
		if d <= b.half_w + 14.0 and d < best_d:
			best = b
			best_d = d
	if best == null:
		return
	best.focused = true
	if Input.is_action_pressed("interact") and pay_t <= 0.0 and coins > 0:
		coins -= 1
		pay_t = Cfg.PAY_INTERVAL
		best.pay_coin()


func spawn_coin(at_x: float, n: int) -> void:
	for i in n:
		var c = CoinS.new()
		l_coins.add_child(c)
		c.setup(self, at_x)


func on_player_down() -> void:
	var lost: int = mini(coins, 3)
	coins -= lost
	spawn_coin(player.position.x, lost)
	hud.flash("You are down - back at the keep in %ds" % int(Cfg.PLAYER.respawn), 3.0)


# ---------------- recruiting and posts ----------------

func can_recruit(role: String) -> bool:
	var n := 0
	for g in garrison:
		if g.role == role and not g.dead:
			n += 1
	return n < int(Cfg.UNITS[role].cap)


func recruit(role: String, at_x: float) -> void:
	var sprites: Array = Cfg.UNITS[role].sprites
	var a = AllyS.new()
	l_units.add_child(a)
	a.setup(self, role, sprites[randi() % sprites.size()], false)
	a.position.x = at_x
	garrison.append(a)
	add_fx("text", Vector2(at_x, -50), {"text": role.capitalize() + " joined", "color": Color(0.7, 1.0, 0.7)})


func on_ally_died(a) -> void:
	garrison.erase(a)


func wall_standing() -> bool:
	return buildings["wall"].standing()


# Where a garrison unit should stand. y below zero means "on top of a tower".
func get_post(a) -> Dictionary:
	var idx := 0
	for g in garrison:
		if g == a:
			break
		if g.role == a.role and not g.dead:
			idx += 1
	var wx: float = buildings["wall"].position.x
	match a.role:
		"soldier":
			return {"x": wx - buildings["wall"].half_w - 6.0 - idx * 8.0, "y": 0.0}
		"priest":
			return {"x": wx - buildings["wall"].half_w - 70.0 - idx * 10.0, "y": 0.0}
		"archer":
			return _tower_post(buildings["archer_tower"], idx, wx - buildings["wall"].half_w - 40.0)
		_:
			return _tower_post(buildings["mage_tower"], idx, wx - buildings["wall"].half_w - 90.0)


func _tower_post(t, idx: int, ground_x: float) -> Dictionary:
	var slots: int = t.def.slots
	if t.standing() and idx < slots:
		var post: Array = t.def.get("post", [0.0, t.height()])
		return {"x": t.position.x + float(post[0]) + idx * 10.0, "y": -float(post[1])}
	return {"x": ground_x - maxi(0, idx - slots) * 9.0, "y": 0.0}


func claim_job(builder):
	var best = null
	var best_score := 1e9
	for b in buildings.values():
		if b.builder != null or not (b.pending or b.needs_repair()):
			continue
		var score := absf(b.position.x - builder.position.x) + (0.0 if b.pending else 2000.0)
		if score < best_score:
			best = b
			best_score = score
	if best != null:
		best.builder = builder
	return best


# ---------------- lookups (the lane is one-dimensional: only x matters) ----------------

func demon_count() -> int:
	var n := spawn_queue.size()
	for d in get_tree().get_nodes_in_group("demons"):
		if not d.dead:
			n += 1
	return n


func nearest_demon(x: float, rng: float):
	var best = null
	var best_d := rng
	for d in get_tree().get_nodes_in_group("demons"):
		if d.dead:
			continue
		var dist := absf(d.position.x - x)
		if dist <= best_d:
			best = d
			best_d = dist
	return best


func demons_in(x: float, rng: float) -> Array:
	var out: Array = []
	for d in get_tree().get_nodes_in_group("demons"):
		if not d.dead and absf(d.position.x - x) <= rng:
			out.append(d)
	out.sort_custom(func(a, b): return absf(a.position.x - x) < absf(b.position.x - x))
	return out


# Nearest unit a demon can hit: alive, on the ground, in reach.
func nearest_ally(x: float, rng: float):
	var best = null
	var best_d := rng
	for a in get_tree().get_nodes_in_group("allies"):
		if a.dead or a.elevated or not a.targetable:
			continue
		var dist := absf(a.position.x - x)
		if dist <= best_d:
			best = a
			best_d = dist
	return best


func wounded_in(x: float, rng: float) -> Array:
	var out: Array = []
	for a in get_tree().get_nodes_in_group("allies"):
		if not a.dead and a.hp < a.max_hp and absf(a.position.x - x) <= rng:
			out.append(a)
	return out


func most_wounded_ally(x: float, rng: float):
	var best = null
	var best_r := 0.999
	for a in wounded_in(x, rng):
		var r: float = a.hp / a.max_hp
		if r < best_r:
			best = a
			best_r = r
	return best


# First standing wall, tower or keep whose right face the demon has reached.
func blocking_structure(x: float, reach: float):
	var best = null
	for b in buildings.values():
		if not b.blocks() or b.position.x > x:
			continue
		if x - (b.position.x + b.half_w) <= reach:
			if best == null or b.position.x > best.position.x:
				best = b
	return best


# ---------------- projectiles and effects ----------------

func shoot(kind: String, from: Vector2, target, dmg: float, opts: Dictionary) -> void:
	var p = ProjS.new()
	p.main = self
	p.kind = kind
	p.position = from
	p.target = target
	p.dmg = dmg
	p.radius = opts.get("radius", 0.0)
	p.speed = opts.get("speed", 230.0)
	p.dir = opts.get("dir", 1)
	if target != null:
		p.target_pos = target.position + Vector2(0, -18)
	l_fx.add_child(p)


func add_fx(kind: String, at: Vector2, opts: Dictionary) -> void:
	var f = FxS.new()
	f.kind = kind
	f.position = at
	f.radius = opts.get("radius", 10.0)
	f.color = opts.get("color", Color.WHITE)
	f.text = opts.get("text", "")
	f.dir = opts.get("dir", 1)
	f.life = opts.get("life", 0.9 if kind == "text" else (0.6 if kind == "heal" else 0.22))
	l_fx.add_child(f)


# ---------------- camera and light ----------------

func _camera(dt: float) -> void:
	var want: float = player.position.x + player.facing * 30.0
	var half := get_viewport_rect().size.x / 2.0
	want = clampf(want, Cfg.WORLD_LEFT + half, Cfg.WORLD_RIGHT - half)
	cam.position.x = lerpf(cam.position.x, want, 1.0 - exp(-4.0 * dt))


func _tint(dt: float) -> void:
	var dusk: bool = is_day and phase_t > Cfg.DAY_LEN - 6.0
	var want := 0.0 if (is_day and not dusk) else 1.0
	night_amt = move_toward(night_amt, want, dt / 5.0)
	tint.color = Color.WHITE.lerp(NIGHT_TINT, night_amt)
