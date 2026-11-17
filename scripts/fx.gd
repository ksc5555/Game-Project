extends Node2D
# Short-lived effects, all drawn in code: slash, burst, heal, beam, text.

var kind := "burst"
var t := 0.0
var life := 0.3
var radius := 10.0
var color := Color.WHITE
var text := ""
var dir := 1


func _process(dt: float) -> void:
	t += dt
	if kind == "text" or kind == "heal":
		position.y -= 16.0 * dt
	if t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(t / life, 0.0, 1.0)
	var a := 1.0 - k
	match kind:
		"slash":
			var c := Color(1, 1, 1, a)
			var from := -0.9 if dir > 0 else PI - 0.9
			draw_arc(Vector2.ZERO, radius * (0.7 + 0.5 * k), from, from + 1.8, 8, c, 1.5)
		"burst":
			draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * k), 0.0, TAU, 20, Color(color.r, color.g, color.b, a), 1.5)
			draw_circle(Vector2.ZERO, radius * 0.5 * (1.0 - k), Color(color.r, color.g, color.b, a * 0.5))
		"heal":
			var g := Color(0.5, 1.0, 0.55, a)
			for o in [Vector2(-4, 2), Vector2(3, -2), Vector2(0, 6)]:
				draw_rect(Rect2(o.x - 0.5, o.y - 2, 1, 4), g)
				draw_rect(Rect2(o.x - 2, o.y - 0.5, 4, 1), g)
		"beam":
			draw_rect(Rect2(-1.5, -160, 3, 160), Color(1.0, 0.95, 0.6, a))
			draw_circle(Vector2(0, -4), 6.0 * a, Color(1.0, 0.95, 0.6, a))
		"text":
			draw_string(ThemeDB.fallback_font, Vector2(-40, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 6, Color(color.r, color.g, color.b, a))
