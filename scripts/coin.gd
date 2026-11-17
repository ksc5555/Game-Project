extends Node2D
# A dropped coin. Pops up, lands, waits for the leader to walk over it.

var main
var vel := Vector2.ZERO
var age := 0.0


func setup(main_, at_x: float) -> void:
	main = main_
	position = Vector2(at_x, -10.0)
	vel = Vector2(randf_range(-16.0, 16.0), randf_range(-90.0, -55.0))


func _process(dt: float) -> void:
	age += dt
	if position.y < -2.0 or vel.y < 0.0:
		vel.y += 300.0 * dt
		position += vel * dt
		if position.y >= -2.0:
			position.y = -2.0
			vel = Vector2.ZERO
	var p = main.player
	if age > 0.5 and not p.dead and absf(p.position.x - position.x) < 14.0:
		main.coins += 1
		main.add_fx("text", position + Vector2(0, -10), {"text": "+1", "color": Color(1.0, 0.85, 0.3)})
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.5, Color(0.45, 0.3, 0.05))
	draw_circle(Vector2.ZERO, 1.8, Color(1.0, 0.82, 0.25))
