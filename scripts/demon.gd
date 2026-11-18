extends "res://scripts/unit.gd"
# Walks left. Attacks any ground unit in reach, otherwise the first standing
# structure in its way (wall, towers, then the keep).

var kind := "thrall"
var def: Dictionary
var atk_t := 0.0
var jitter := 0.0


func setup(main_, kind_: String) -> void:
	main = main_
	kind = kind_
	def = Cfg.DEMONS[kind]
	max_hp = def.hp
	hp = max_hp
	speed = float(def.speed) * randf_range(0.9, 1.1)
	jitter = randf_range(0.0, 7.0)
	facing = -1
	init_sprite(def.sprite)
	add_to_group("demons")


func _process(dt: float) -> void:
	if dead:
		return
	tick_visual(dt)
	if main.game_over:
		moving = false
		return
	if main.is_day:
		take_damage(Cfg.SUN_BURN * dt, true)
		if dead:
			return
	atk_t = maxf(0.0, atk_t - dt)
	if stun_t > 0.0:
		stun_t -= dt
		moving = false
		return

	var u = main.nearest_ally(position.x, def.reach)
	if u != null:
		moving = false
		facing = 1 if u.position.x > position.x else -1
		if atk_t <= 0.0:
			atk_t = def.atk_cd
			play_attack(float(def.atk_cd) * 0.9)
			u.take_damage(def.dmg)
		return

	facing = -1
	var s = main.blocking_structure(position.x, 4.0 + jitter)
	if s != null:
		moving = false
		if atk_t <= 0.0:
			atk_t = def.atk_cd
			play_attack(float(def.atk_cd) * 0.9)
			s.take_damage(float(def.dmg) * float(def.struct_mult))
		return

	moving = true
	position.x -= speed * speed_mult() * dt


func _on_death() -> void:
	if randf() <= float(def.coin_chance):
		main.spawn_coin(position.x, int(def.coins))


func _bar_color() -> Color:
	return Color(0.9, 0.3, 0.25)
