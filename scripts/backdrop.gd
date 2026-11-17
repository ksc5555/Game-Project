extends Node2D
# Backdrop: the dusk-ruins painting, repeated sideways with parallax,
# plus the dirt ground the lane is played on.

const Cfg = preload("res://scripts/cfg.gd")
const PARALLAX := 0.45          # 0 = moves with the world, 1 = stuck to the camera
var cam: Camera2D
var tex: Texture2D = preload("res://art/backdrop/ruins_dusk.png")
var sky_top: Color
var sky_low: Color


func _ready() -> void:
	var img := tex.get_image()
	sky_top = img.get_pixel(2, 0)
	sky_low = img.get_pixel(2, 2)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if cam == null:
		return
	var cx := cam.position.x
	var half := 560.0
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	draw_rect(Rect2(cx - half, -700, half * 2, 700), sky_top * Color(0.62, 0.62, 0.72))
	# Tile the painting; its bottom row sits on the ground line.
	var shift := cx * PARALLAX
	var first := floorf((cx - half - shift) / w)
	var i := first
	while (i * w + shift) < cx + half:
		draw_texture(tex, Vector2(i * w + shift, -h + 2), Color(0.62, 0.62, 0.72))   # pushed back with a cool haze
		i += 1.0
	# Rift the demons come out of
	var rx := Cfg.SPAWN_X + 14.0
	draw_rect(Rect2(rx - 10, -60, 26, 60), Color(0.16, 0.05, 0.12))
	draw_rect(Rect2(rx - 5, -52, 12, 52), Color(0.5, 0.12, 0.2))
	draw_rect(Rect2(rx - 1, -44, 4, 44), Color(0.9, 0.35, 0.25))
	# Ground
	draw_rect(Rect2(cx - half, 0, half * 2, 400), Color(0.12, 0.1, 0.08))
	draw_rect(Rect2(cx - half, 0, half * 2, 2), Color(0.2, 0.17, 0.13))
	draw_rect(Rect2(cx - half, 2, half * 2, 3), Color(0.16, 0.13, 0.1))
