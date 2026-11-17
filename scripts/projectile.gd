extends Node2D
# arrow: flies to one target. fireball: flies to a target, hurts everything
# near it. pierce: flies flat and hits every demon it passes.

var main
var kind := "arrow"
var target = null
var target_pos := Vector2.ZERO
var dmg := 1.0
var radius := 0.0
var speed := 230.0
var dir := 1
var travelled := 0.0
var hit: Array = []


func _process(dt: float) -> void:
	if kind == "pierce":
		var step := speed * dt
		position.x += dir * step
		travelled += step
		for d in main.demons_in(position.x, 7.0):
			if not hit.has(d):
				hit.append(d)
				d.take_damage(dmg)
		if travelled > 230.0:
			queue_free()
		return
	if target != null and is_instance_valid(target) and not target.dead:
		target_pos = target.position + Vector2(0, -18)
	var to := target_pos - position
	var st := speed * dt
	if to.length() <= st:
		_impact()
		return
	position += to.normalized() * st
	rotation = to.angle()


func _impact() -> void:
	if kind == "fireball":
		main.add_fx("burst", target_pos, {"radius": radius, "color": Color(1.0, 0.55, 0.15), "life": 0.35})
		for d in main.demons_in(target_pos.x, radius):
			d.take_damage(dmg)
	elif target != null and is_instance_valid(target) and not target.dead:
		target.take_damage(dmg)
	queue_free()


func _draw() -> void:
	match kind:
		"fireball":
			draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.45, 0.1))
			draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.9, 0.5))
			draw_line(Vector2(-7, 0), Vector2(-2, 0), Color(1.0, 0.5, 0.1, 0.6), 2.0)
		"pierce":
			draw_line(Vector2(-9 * dir, 0), Vector2(3 * dir, 0), Color(1.0, 0.95, 0.7), 1.5)
		_:
			draw_line(Vector2(-6, 0), Vector2(0, 0), Color(0.75, 0.62, 0.4), 1.0)
			draw_line(Vector2(0, 0), Vector2(2, 0), Color(0.85, 0.85, 0.85), 1.0)
