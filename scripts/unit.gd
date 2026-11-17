extends Node2D
# Base for everything that walks: player, party, garrison, builders, demons.
# The art is one still frame per unit, so motion is faked in code
# (walk bob, attack lunge, white flash on hit, topple on death).

const Cfg = preload("res://scripts/cfg.gd")
const FLASH = preload("res://scripts/flash.gdshader")

var main
var hp := 10.0
var max_hp := 10.0
var speed := 40.0
var facing := 1
var dead := false
var targetable := true
var elevated := false           # standing on a tower: melee can't reach
var free_on_death := true
var moving := false
var stun_t := 0.0
var slow_t := 0.0
var base_tint := Color.WHITE
var sprite: Sprite2D
var sprite_h := 40.0
var _flash := 0.0
var _lunge := 0.0
var _walk_t := 0.0
# Animated sheets (6 x 3 grid of 64 px cells: walk, attack, block; feet on row 54)
var animated := false
var _anim_t := 0.0
var _atk_anim := -1.0
var _hit_anim := 0.0
var blocking := false


func init_sprite(tex_name: String) -> void:
	if tex_name.begins_with("anim:"):
		init_anim(tex_name.substr(5))
		return
	sprite = Sprite2D.new()
	var tex: Texture2D = load("res://art/units/%s.png" % tex_name)
	sprite.texture = tex
	sprite.centered = false
	sprite_h = float(tex.get_height())
	# Origin at the feet, so position.y = 0 means "standing on the ground".
	sprite.offset = Vector2(-tex.get_width() / 2.0, -sprite_h)
	var mat := ShaderMaterial.new()
	mat.shader = FLASH
	sprite.material = mat
	add_child(sprite)


func init_anim(sheet: String) -> void:
	animated = true
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/anim/%s.png" % sheet)
	sprite.centered = false
	sprite.hframes = 6
	sprite.vframes = 3
	sprite.offset = Vector2(-32, -55)
	sprite_h = 40.0
	var mat := ShaderMaterial.new()
	mat.shader = FLASH
	sprite.material = mat
	add_child(sprite)


# Play the 6-frame attack row once over `secs` seconds.
func play_attack(secs: float = 0.5) -> void:
	if animated:
		_atk_anim = 0.0
		_atk_len = secs
	else:
		lunge()

var _atk_len := 0.5


func _anim_frame(dt: float) -> int:
	if _atk_anim >= 0.0:
		_atk_anim += dt
		if _atk_anim < _atk_len:
			return 6 + mini(5, int(_atk_anim / _atk_len * 6.0))
		_atk_anim = -1.0
	if blocking:
		return 12 + (3 if _hit_anim > 0.0 else 2)
	if _hit_anim > 0.0:
		return 15
	if moving:
		_anim_t += dt
		return int(_anim_t * 8.0) % 6
	_anim_t = 0.0
	return 0


func tick_visual(dt: float) -> void:
	_flash = maxf(0.0, _flash - dt)
	_lunge = maxf(0.0, _lunge - dt)
	slow_t = maxf(0.0, slow_t - dt)
	(sprite.material as ShaderMaterial).set_shader_parameter("flash", 1.0 if _flash > 0.0 else 0.0)
	if moving:
		_walk_t += dt * 13.0
	else:
		_walk_t = 0.0
	_hit_anim = maxf(0.0, _hit_anim - dt)
	if animated:
		sprite.frame = _anim_frame(dt)
		sprite.position = Vector2.ZERO
	else:
		sprite.position = Vector2(facing * 3.0 * (_lunge / 0.12), -absf(sin(_walk_t)) * 1.5)
	sprite.flip_h = facing < 0      # all source sprites face right
	sprite.modulate = base_tint.lerp(Color(0.55, 0.75, 1.0), 0.6) if slow_t > 0.0 else base_tint


func speed_mult() -> float:
	return 0.5 if slow_t > 0.0 else 1.0


func lunge() -> void:
	_lunge = 0.12


func take_damage(amount: float, silent: bool = false) -> void:
	if dead:
		return
	if blocking:
		amount *= 1.0 - Cfg.BLOCK_REDUCTION
	hp -= amount
	if not silent:
		_flash = 0.1
		if animated and _atk_anim < 0.0:
			_hit_anim = 0.2
	queue_redraw()
	if hp <= 0.0:
		die()


func heal(amount: float) -> void:
	if dead or hp >= max_hp:
		return
	hp = minf(max_hp, hp + amount)
	queue_redraw()
	main.add_fx("heal", position + Vector2(0, -sprite_h * 0.6), {})


func knockback(dx: float) -> void:
	position.x = clampf(position.x + dx, Cfg.WORLD_LEFT, Cfg.SPAWN_X)


func die() -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	moving = false
	queue_redraw()
	_on_death()
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", -facing * PI / 2.0, 0.25)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	if free_on_death:
		tw.tween_callback(queue_free)
	else:
		tw.tween_callback(func(): visible = false)


func revive(at_x: float) -> void:
	dead = false
	hp = max_hp
	visible = true
	modulate.a = 1.0
	sprite.rotation = 0.0
	position = Vector2(at_x, 0.0)
	queue_redraw()


func _on_death() -> void:
	pass


func _draw() -> void:
	if dead or hp >= max_hp:
		return
	var w := 14.0
	var y := -sprite_h - 5.0
	draw_rect(Rect2(-w / 2.0 - 1.0, y - 1.0, w + 2.0, 4.0), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-w / 2.0, y, w * clampf(hp / max_hp, 0.0, 1.0), 2.0), _bar_color())


func _bar_color() -> Color:
	return Color(0.45, 0.85, 0.4)
