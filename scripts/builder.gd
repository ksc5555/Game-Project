extends "res://scripts/unit.gd"
# Walks out to anything that has been paid for and builds it. Repairs damage
# by day. Hides in the keep at night. Demons ignore builders.
# PLACEHOLDER ART: tinted soldier until a real builder sprite exists.

var home_x := 0.0
var job = null
var swing_t := 0.0


func setup(main_, home: float) -> void:
	main = main_
	home_x = home
	speed = 46.0
	targetable = false
	base_tint = Color(1.0, 0.82, 0.55)
	init_sprite("anim:soldier2")
	position.x = home


func _process(dt: float) -> void:
	tick_visual(dt)
	if main.game_over:
		moving = false
		return
	if not main.is_day:
		_release()
		var kx: float = main.keep.position.x
		_step(kx, dt)
		visible = absf(position.x - kx) > 4.0
		return
	visible = true
	if job != null and not (job.pending or job.needs_repair()):
		_release()
	if job == null:
		job = main.claim_job(self)
	if job == null:
		_step(home_x, dt)
		return
	if _step(job.position.x - job.half_w - 7.0, dt):
		facing = 1
		swing_t -= dt
		if swing_t <= 0.0:
			swing_t = 0.45
			play_attack(0.45)
		if job.pending:
			job.work(dt)
		else:
			job.repair(dt)


func _step(gx: float, dt: float) -> bool:
	var dx := gx - position.x
	if absf(dx) <= 1.5:
		moving = false
		return true
	position.x += signf(dx) * minf(absf(dx), speed * dt)
	facing = 1 if dx > 0.0 else -1
	moving = true
	return false


func _release() -> void:
	if job != null and job.builder == self:
		job.builder = null
	job = null
