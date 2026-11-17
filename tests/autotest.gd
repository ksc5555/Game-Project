extends Node
# Headless smoke test. Run with:  DW_AUTOTEST=1 godot --headless --path .
# Buys everything, walks the leader to the wall, swings non-stop, and prints
# the state every 20 game-seconds until the game ends.
# DW_NOBUILD=1 skips buying, DW_SHOT=<dir> saves screenshots (needs a display).

var main
var t := 0.0
var next_log := 0.0
var shots := 0


func _ready() -> void:
	main = get_parent()
	Engine.time_scale = float(OS.get_environment("DW_SPEED")) if OS.has_environment("DW_SPEED") else 4.0
	if not OS.has_environment("DW_NOBUILD"):
		main.coins = int(OS.get_environment("DW_COINS")) if OS.has_environment("DW_COINS") else 400
	Input.action_press("attack")
	if OS.has_environment("DW_BUILT"):
		for b in main.buildings.values():
			if not b.def.get("locked", false):
				b._complete(b.max_level())
		for r in ["soldier", "soldier", "soldier", "soldier"]:
			main.recruit(r, main.keep.position.x)


func _process(dt: float) -> void:
	t += dt
	if not OS.has_environment("DW_NOBUILD"):
		for b in main.buildings.values():
			if main.coins > 0 and not b.offer().is_empty():
				main.coins -= 1
				b.pay_coin()
	if OS.has_environment("DW_LOOK"):
		main.player.position.x = float(OS.get_environment("DW_LOOK"))
	elif main.player.position.x < main.buildings["wall"].position.x - main.buildings["wall"].half_w - 14.0 and not main.player.dead:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
	if main.is_day and main.phase_t > 25.0 and not main.game_over:
		main.phase_t = main.Cfg.DAY_LEN      # no need to sit through daylight
	if OS.has_environment("DW_SHOT") and shots < 14 and t >= 10.0 + shots * 7.0:
		shots += 1
		get_viewport().get_texture().get_image().save_png("%s/shot%d.png" % [OS.get_environment("DW_SHOT"), shots])
	if t >= next_log or main.game_over:
		next_log = t + 20.0
		var allies := 0
		for a in get_tree().get_nodes_in_group("allies"):
			if not a.dead:
				allies += 1
		var w = main.buildings["wall"]
		print("t=%4d  %s %d  coins=%d  demons=%d  allies=%d  garrison=%d  keep=%d  wall L%d %d  player=%d" % [
			int(t), "day" if main.is_day else "night", main.day, main.coins, main.demon_count(),
			allies, main.garrison.size(), int(main.keep.hp), w.level, int(w.hp), int(main.player.hp)])
	if main.game_over:
		print("RESULT: ", main.hud.msg_l.text.split("\n")[0])
		get_tree().quit()
