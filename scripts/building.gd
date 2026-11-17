extends Node2D
# One plot of land. Starts empty; pay coins to build it, pay again to
# upgrade (wall) or recruit (barracks, range, church, mage tower).
# PLACEHOLDER ART: everything here is drawn with rectangles in _draw().

const Cfg = preload("res://scripts/cfg.gd")

var main
var key := ""
var def: Dictionary
var level := 0
var target_level := 0
var hp := 0.0
var max_hp := 0.0
var paid := 0
var pending := false            # paid for, waiting on / being worked by a builder
var progress := 0.0
var builder = null
var focused := false
var half_w := 10.0
var _flash := 0.0
var art: Sprite2D


func setup(main_, key_: String) -> void:
	main = main_
	key = key_
	def = Cfg.BUILDINGS[key]
	position = Vector2(def.x, 0.0)
	if def.has("art"):
		art = Sprite2D.new()
		art.texture = load("res://art/buildings/%s.png" % def.art)
		art.centered = false
		art.region_enabled = true
		art.show_behind_parent = true
		add_child(art)
		half_w = art.texture.get_width() / 2.0
	else:
		half_w = float(def.w) / 2.0
	_update_art()
	if def.get("start_built", false):
		_complete(1)


func max_level() -> int:
	return def.levels.size()


func height() -> float:
	return _level_h(clampi(level, 1, max_level()))


func _level_h(lv: int) -> float:
	if art != null:
		var full := float(art.texture.get_height())
		var h: float = def.levels[lv - 1].h
		return minf(full, h) if h > 0.0 else full
	return def.levels[lv - 1].h


# Built: full colour. Being built: half see-through. Empty plot: faint ghost.
func _update_art() -> void:
	if art == null:
		return
	var lv := level if level > 0 else (target_level if pending else 1)
	var h := _level_h(maxi(1, lv))
	var w := float(art.texture.get_width())
	var full := float(art.texture.get_height())
	art.region_rect = Rect2(0, full - h, w, h)
	art.position = Vector2(-w / 2.0, -h + 1)
	if standing():
		art.modulate = Color(1.6, 1.4, 1.4) if _flash > 0.0 else Color.WHITE
	elif pending:
		art.modulate = Color(1, 1, 1, 0.35 + 0.5 * progress / maxf(0.1, float(def.levels[target_level - 1].time)))
	else:
		art.modulate = Color(1, 1, 1, 0.0 if def.get("locked", false) else 0.16)


func standing() -> bool:
	return level > 0 and hp > 0.0


func blocks() -> bool:
	return def.get("blocks", false) and standing()


func needs_repair() -> bool:
	return standing() and hp < max_hp


# What a coin buys here right now. Empty = nothing for sale.
func offer() -> Dictionary:
	if def.get("locked", false) or pending or main.game_over:
		return {}
	if level == 0:
		return {"kind": "build", "label": "Build " + str(def.name), "cost": def.levels[0].cost}
	if level < max_level():
		return {"kind": "build", "label": "Upgrade " + str(def.name), "cost": def.levels[level].cost}
	if def.has("recruit") and main.can_recruit(def.recruit):
		return {"kind": "recruit", "label": "Recruit " + str(def.recruit).capitalize(), "cost": Cfg.UNITS[def.recruit].cost}
	return {}


func pay_coin() -> void:
	var o := offer()
	if o.is_empty():
		return
	paid += 1
	if paid < int(o.cost):
		return
	paid = 0
	if o.kind == "build":
		pending = true
		target_level = level + 1
		progress = 0.0
	else:
		main.recruit(def.recruit, position.x)


func work(dt: float) -> void:
	if not pending:
		return
	progress += dt
	if progress >= float(def.levels[target_level - 1].time):
		_complete(target_level)


func repair(dt: float) -> void:
	hp = minf(max_hp, hp + Cfg.BUILD_REPAIR_RATE * dt)


func _complete(lv: int) -> void:
	level = lv
	max_hp = def.levels[lv - 1].hp
	hp = max_hp
	pending = false
	builder = null


func take_damage(amount: float) -> void:
	if not standing():
		return
	hp -= amount
	_flash = 0.1
	if hp > 0.0:
		return
	hp = 0.0
	main.add_fx("burst", position + Vector2(0, -height() / 2.0), {"radius": 22.0, "color": Color(0.8, 0.7, 0.6), "life": 0.5})
	if key == "keep":
		main.defeat()
	else:
		level = 0
		pending = false
		builder = null
		paid = 0


func _process(dt: float) -> void:
	_flash = maxf(0.0, _flash - dt)
	_update_art()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w: float = half_w * 2.0
	var col: Color = def.get("color", Color.GRAY)
	var top := 16.0
	if art != null:
		top = height() if level > 0 else _level_h(maxi(1, target_level if pending else 1))
	elif level == 0:
		var c := Color(1, 1, 1, 0.12 if def.get("locked", false) else 0.3)
		draw_rect(Rect2(-half_w, -2, w, 2), c)
		draw_line(Vector2(0, -2), Vector2(0, -12), c, 1.0)
		draw_rect(Rect2(-5, -16, 10, 5), c)
	else:
		var h := height()
		top = h
		var body := col.lightened(0.5) if _flash > 0.0 else col
		var dark := col.darkened(0.45)
		draw_rect(Rect2(-half_w, -h, w, h), body)
		draw_rect(Rect2(-half_w, -h, w, h), dark, false, 1.0)
		_details(h, w, col, dark)
	if pending:
		var th: float = _level_h(target_level)
		top = maxf(top, th)
		if art == null:
			draw_rect(Rect2(-half_w - 2, -th, w + 4, th), Color(0.9, 0.8, 0.5, 0.7), false, 1.0)
		var k: float = progress / maxf(0.1, float(def.levels[target_level - 1].time))
		draw_rect(Rect2(-10, -th - 5, 20, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-9, -th - 4, 18 * k, 1), Color(0.95, 0.8, 0.35))
	if art != null:
		top = minf(top, 165.0)   # keep labels and prompts on screen for tall buildings
	if standing() and hp < max_hp:
		draw_rect(Rect2(-11, -top - 6, 22, 4), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-10, -top - 5, 20 * hp / max_hp, 2), Color(0.5, 0.7, 0.9))
	var label: String = def.name
	if key == "wall" and level > 0:
		label += " " + ["I", "II", "III"][level - 1]
	draw_string(font, Vector2(-50, -top - 9), label, HORIZONTAL_ALIGNMENT_CENTER, 100, 6, Color(1, 1, 1, 0.5))
	if focused:
		_prompt(font, top)


func _details(h: float, w: float, col: Color, dark: Color) -> void:
	match key:
		"keep":
			for i in 4:
				draw_rect(Rect2(-half_w + i * 18.0, -h - 6, 10, 6), col)
			draw_rect(Rect2(-7, -20, 14, 20), dark)
			draw_rect(Rect2(-22, -46, 6, 9), dark)
			draw_rect(Rect2(16, -46, 6, 9), dark)
		"wall":
			for i in range(1, int(h / 8.0) + 1):
				draw_line(Vector2(-half_w, -i * 8.0), Vector2(half_w, -i * 8.0), dark, 1.0)
			if level == 1:
				draw_colored_polygon(PackedVector2Array([Vector2(-half_w, -h), Vector2(0, -h - 6), Vector2(half_w, -h)]), col)
		"archer_tower":
			draw_rect(Rect2(-half_w - 4, -h - 3, w + 8, 4), dark)
			draw_rect(Rect2(-half_w - 4, -h - 9, 3, 6), dark)
			draw_rect(Rect2(half_w + 1, -h - 9, 3, 6), dark)
		"mage_tower":
			draw_rect(Rect2(-half_w - 3, -h - 3, w + 6, 4), dark)
			draw_rect(Rect2(-3, -h + 12, 6, 9), Color(0.55, 0.5, 0.9))
		"church":
			draw_colored_polygon(PackedVector2Array([Vector2(-half_w - 2, -h), Vector2(0, -h - 14), Vector2(half_w + 2, -h)]), dark)
			draw_rect(Rect2(-1, -h - 24, 2, 10), col)
			draw_rect(Rect2(-4, -h - 21, 8, 2), col)
			draw_rect(Rect2(-5, -16, 10, 16), dark)
		"barracks":
			draw_rect(Rect2(-half_w - 2, -h - 4, w + 4, 5), dark)
			draw_rect(Rect2(-6, -16, 12, 16), dark)
			draw_rect(Rect2(half_w - 8, -h - 16, 1, 12), dark)
			draw_rect(Rect2(half_w - 7, -h - 16, 7, 5), Color(0.6, 0.2, 0.15))
		"range":
			draw_circle(Vector2(half_w - 9, -h - 8), 7.0, Color(0.85, 0.85, 0.8))
			draw_circle(Vector2(half_w - 9, -h - 8), 4.5, Color(0.7, 0.2, 0.15))
			draw_circle(Vector2(half_w - 9, -h - 8), 2.0, Color(0.85, 0.85, 0.8))
		_:
			pass


func _prompt(font: Font, top: float) -> void:
	var o := offer()
	if o.is_empty():
		return
	var y := -top - 28.0
	draw_string(font, Vector2(-70, y), "[E] " + str(o.label), HORIZONTAL_ALIGNMENT_CENTER, 140, 7, Color(1, 0.95, 0.75))
	var n: int = o.cost
	var x0 := -(n - 1) * 3.0
	for i in n:
		var p := Vector2(x0 + i * 6.0, y + 6.0)
		draw_circle(p, 2.5, Color(0, 0, 0, 0.7))
		draw_circle(p, 1.8, Color(1.0, 0.82, 0.25) if i < paid else Color(0.35, 0.32, 0.25))
