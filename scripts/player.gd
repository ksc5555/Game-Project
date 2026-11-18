extends "res://scripts/unit.gd"
# The leader. A/D move, Shift sprint, Space attack (hold to keep swinging).

var atk_t := 0.0
var respawn_t := 0.0
var hurt_t := 0.0
var hit_t := -1.0


func setup(main_) -> void:
	main = main_
	var d: Dictionary = Cfg.PLAYER
	max_hp = d.hp
	hp = max_hp
	free_on_death = false
	init_sprite("anim:" + str(d.anim))
	add_to_group("allies")


func _process(dt: float) -> void:
	if dead:
		respawn_t -= dt
		if respawn_t <= 0.0 and not main.game_over:
			revive(main.keep.position.x + 40.0)
		return
	tick_visual(dt)
	if main.game_over:
		moving = false
		return
	var d: Dictionary = Cfg.PLAYER
	atk_t = maxf(0.0, atk_t - dt)
	hurt_t = maxf(0.0, hurt_t - dt)
	if hurt_t <= 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + float(d.regen) * dt)
		queue_redraw()

	blocking = Input.is_action_pressed("block")
	var dir := 0.0 if blocking else Input.get_axis("move_left", "move_right")
	moving = absf(dir) > 0.1
	if moving:
		facing = 1 if dir > 0.0 else -1
		var sp: float = d.sprint if Input.is_action_pressed("sprint") else d.walk
		position.x = clampf(position.x + dir * sp * dt, Cfg.WORLD_LEFT + 10.0, Cfg.WORLD_RIGHT - 10.0)

	if Input.is_action_pressed("attack") and atk_t <= 0.0 and not blocking:
		atk_t = d.atk_cd
		play_attack(d.atk_cd)
		hit_t = float(d.atk_cd) * float(d.hit_at)
	if hit_t >= 0.0:
		hit_t -= dt
		if hit_t < 0.0:
			_strike(d)


func _strike(d: Dictionary) -> void:
	main.add_fx("slash", position + Vector2(facing * 14.0, -18.0), {"dir": facing})
	var hits := 0
	for e in main.demons_in(position.x, d.atk_range):
		# Only what is in front of the sword (with a little forgiveness).
		if hits < int(d.max_hits) and (e.position.x - position.x) * facing >= -6.0:
			hits += 1
			e.take_damage(d.dmg)
			e.knockback(facing * float(d.knock))


func take_damage(amount: float, silent: bool = false) -> void:
	hurt_t = 4.0
	super.take_damage(amount, silent)


func _on_death() -> void:
	respawn_t = Cfg.PLAYER.respawn
	main.on_player_down()


func _bar_color() -> Color:
	return Color(0.95, 0.8, 0.3)
