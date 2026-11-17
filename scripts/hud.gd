extends CanvasLayer
# Coins, day/night clock, keep health, big centre messages.

var coins_l: Label
var phase_l: Label
var keep_l: Label
var msg_l: Label
var hint_l: Label
var msg_t := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	coins_l = _label(root, Control.PRESET_TOP_WIDE, HORIZONTAL_ALIGNMENT_LEFT, 10)
	phase_l = _label(root, Control.PRESET_TOP_WIDE, HORIZONTAL_ALIGNMENT_CENTER, 10)
	keep_l = _label(root, Control.PRESET_TOP_WIDE, HORIZONTAL_ALIGNMENT_RIGHT, 10)
	msg_l = _label(root, Control.PRESET_FULL_RECT, HORIZONTAL_ALIGNMENT_CENTER, 20)
	msg_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_l.offset_bottom = -90.0
	hint_l = _label(root, Control.PRESET_BOTTOM_WIDE, HORIZONTAL_ALIGNMENT_CENTER, 8)
	hint_l.offset_top = -16.0
	hint_l.offset_bottom = -4.0
	hint_l.text = "A/D move   Shift sprint   Space attack   S block   hold E pay coins   N skip to night"
	coins_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))


func _label(root: Control, preset: int, align: int, size: int) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(preset)
	l.offset_left = 6.0
	l.offset_right = -6.0
	if preset == Control.PRESET_TOP_WIDE:
		l.offset_top = 3.0
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func flash(text: String, secs: float = 2.5) -> void:
	msg_l.text = text
	msg_l.modulate.a = 1.0
	msg_t = secs


func refresh(m, dt: float) -> void:
	coins_l.text = "Coins  %d" % m.coins
	var k = m.keep
	keep_l.text = "Keep  %d / %d" % [int(ceil(k.hp)), int(k.max_hp)]
	if m.game_over:
		phase_l.text = ""
		return
	if m.is_day:
		phase_l.text = "Day %d   night in %ds" % [m.day, int(ceil(m.Cfg.DAY_LEN - m.phase_t))]
	else:
		phase_l.text = "Night %d of %d   demons %d   dawn in %ds" % [m.day, m.Cfg.NIGHTS_TO_WIN, m.demon_count(), int(ceil(maxf(0.0, m.Cfg.NIGHT_LEN - m.phase_t)))]
	if msg_t > 0.0:
		msg_t -= dt
		msg_l.modulate.a = clampf(msg_t / 0.6, 0.0, 1.0)
