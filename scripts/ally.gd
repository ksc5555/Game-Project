extends "res://scripts/unit.gd"
# Party members (follow the leader, random skills) and garrison units
# (walk to a post and use their one basic skill).

var role := "soldier"
var is_party := false
var slot := 0
var skills: Array = []
var cds: Array = []
var gcd := 0.0
var post := {"x": 0.0, "y": 0.0}
var post_t := 0.0


func setup(main_, role_: String, tex: String, party: bool, slot_: int = 0) -> void:
	main = main_
	role = role_
	is_party = party
	slot = slot_
	var d: Dictionary = Cfg.UNITS[role]
	max_hp = float(d.hp) * (Cfg.PARTY_HP_MULT if party else 1.0)
	hp = max_hp
	speed = d.speed
	skills = Cfg.SKILLS[role]
	for i in skills.size():
		cds.append(randf_range(0.0, 1.0))
	free_on_death = not party
	init_sprite(tex)
	add_to_group("allies")


func _process(dt: float) -> void:
	if dead:
		return
	tick_visual(dt)
	if main.game_over:
		moving = false
		return
	for i in cds.size():
		cds[i] = maxf(0.0, float(cds[i]) - dt)
	gcd = maxf(0.0, gcd - dt)

	var goal_x := position.x
	var goal_y := 0.0
	if is_party:
		var p = main.player
		goal_x = p.position.x - p.facing * (14.0 + slot * 13.0)
		if role == "soldier":
			# Step out to meet anything close, but stay near the leader.
			var e = main.nearest_demon(position.x, 60.0)
			if e != null and absf(e.position.x - p.position.x) < 110.0:
				goal_x = e.position.x - signf(e.position.x - position.x) * 16.0
	else:
		post_t -= dt
		if post_t <= 0.0:
			post_t = 0.5
			post = main.get_post(self)
		goal_x = post.x
		goal_y = post.y
		if role == "soldier" and not main.wall_standing():
			# No wall to hide behind: soldiers become the wall.
			var e2 = main.nearest_demon(goal_x, 70.0)
			if e2 != null:
				goal_x = e2.position.x - signf(e2.position.x - position.x) * 16.0

	_walk_to(goal_x, goal_y, dt)
	_try_cast()


func _walk_to(goal_x: float, goal_y: float, dt: float) -> void:
	var dx := goal_x - position.x
	var dead_zone := 5.0 if is_party else 1.5
	if absf(dx) > dead_zone:
		if position.y < -0.5:
			# Climb down before walking anywhere.
			position.y = minf(0.0, position.y + 80.0 * dt)
			moving = false
		else:
			var sp := speed * (2.2 if absf(dx) > 45.0 else 1.0)
			position.x += signf(dx) * minf(absf(dx), sp * dt)
			facing = 1 if dx > 0.0 else -1
			moving = true
	else:
		moving = false
		position.y = move_toward(position.y, goal_y, 80.0 * dt)
		if is_party:
			facing = main.player.facing
		else:
			facing = 1
	elevated = position.y < -8.0


func _rng(s: Dictionary) -> float:
	var r: float = s.get("rng", 0.0)
	if elevated:
		r += Cfg.TOWER_RANGE_BONUS
	return r


func _usable(s: Dictionary) -> bool:
	match s.kind:
		"heal":
			return main.most_wounded_ally(position.x, s.rng) != null
		"bless":
			return main.wounded_in(position.x, s.radius).size() >= 2
		_:
			return main.nearest_demon(position.x, _rng(s)) != null


func _try_cast() -> void:
	if gcd > 0.0:
		return
	var avail: Array = []
	var n: int = skills.size() if is_party else 1
	for i in n:
		if float(cds[i]) <= 0.0 and _usable(skills[i]):
			avail.append(i)
	if avail.is_empty():
		return
	var pick: int = avail[randi() % avail.size()]
	var s: Dictionary = skills[pick]
	_cast(s)
	cds[pick] = float(s.cd) * randf_range(0.9, 1.15)
	gcd = 0.7
	if pick > 0:
		main.add_fx("text", position + Vector2(0, -sprite_h - 8.0), {"text": s["name"], "color": Color(1.0, 0.9, 0.55)})


func _cast(s: Dictionary) -> void:
	var e = main.nearest_demon(position.x, _rng(s))
	if e != null:
		facing = 1 if e.position.x >= position.x else -1
	var muzzle := position + Vector2(facing * 6.0, -sprite_h * 0.55)
	match s.kind:
		"melee":
			play_attack(0.5)
			main.add_fx("slash", e.position + Vector2(0, -18), {"dir": facing})
			e.take_damage(s.dmg)
		"bash":
			play_attack(0.5)
			main.add_fx("burst", e.position + Vector2(0, -18), {"radius": 10.0, "color": Color(1, 1, 0.8)})
			e.stun_t = s.stun
			e.knockback(facing * float(s.knock))
			e.take_damage(s.dmg)
		"cleave":
			play_attack(0.5)
			main.add_fx("slash", position + Vector2(facing * 16.0, -18), {"dir": facing, "radius": 18.0})
			for d in main.demons_in(position.x, s.rng):
				d.take_damage(s.dmg)
		"arrow":
			main.shoot("arrow", muzzle, e, s.dmg, {})
		"volley":
			var list: Array = main.demons_in(position.x, _rng(s))
			for k in int(s.count):
				main.shoot("arrow", muzzle + Vector2(0, -k * 3.0), list[k % list.size()], s.dmg, {"speed": 210.0 + k * 30.0})
		"pierce":
			main.shoot("pierce", muzzle, null, s.dmg, {"dir": facing})
		"heal":
			var a = main.most_wounded_ally(position.x, s.rng)
			if a != null:
				a.heal(s.amt)
		"bless":
			main.add_fx("burst", position + Vector2(0, -18), {"radius": s.radius, "color": Color(1.0, 0.95, 0.6), "life": 0.5})
			for a2 in main.wounded_in(position.x, s.radius):
				a2.heal(s.amt)
		"smite":
			main.add_fx("beam", e.position, {})
			e.take_damage(s.dmg)
		"fireball":
			main.shoot("fireball", muzzle, e, s.dmg, {"radius": s.radius})
		"frost":
			main.add_fx("burst", e.position + Vector2(0, -10), {"radius": s.radius, "color": Color(0.6, 0.85, 1.0), "life": 0.5})
			for d2 in main.demons_in(e.position.x, s.radius):
				d2.slow_t = s.dur
				d2.take_damage(s.dmg)


func _on_death() -> void:
	main.spawn_coin(position.x, 1)
	main.on_ally_died(self)
