extends Node2D


func _ready() -> void:
	_draw_background()
	_draw_title()
	_draw_levels()
	_draw_back_button()


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 150:
		var dot := ColorRect.new()
		var r := rng.randf_range(0.5, 2.0)
		dot.color = Color(1, 1, 1, rng.randf_range(0.15, 0.6))
		dot.size = Vector2(r * 2, r * 2)
		dot.position = Vector2(rng.randf() * GameData.GAME_WIDTH, rng.randf() * GameData.GAME_HEIGHT)
		add_child(dot)


func _draw_title() -> void:
	# Find world name
	var world_name := ""
	for world in GameData.WORLDS:
		if world.id == GameState.current_world_id:
			world_name = world.name
			break

	var lbl := Label.new()
	lbl.text = world_name.to_upper()
	lbl.position = Vector2(0, 60)
	lbl.size = Vector2(GameData.GAME_WIDTH, 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 54)
	lbl.add_theme_color_override("font_color", Color(0, 1, 1))
	add_child(lbl)

	var sub := Label.new()
	sub.text = "VÄLJ NIVÅ"
	sub.position = Vector2(0, 145)
	sub.size = Vector2(GameData.GAME_WIDTH, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	add_child(sub)


func _draw_levels() -> void:
	var world: Dictionary = {}
	for w in GameData.WORLDS:
		if w.id == GameState.current_world_id:
			world = w
			break
	if world.is_empty():
		return

	var levels: Array = world.levels
	var cx := GameData.GAME_WIDTH / 2.0
	var start_x := cx - (levels.size() - 1) * 320.0 / 2.0

	for i in levels.size():
		var level: Dictionary = levels[i]
		var lx := start_x + i * 320.0
		var completed := SaveSystem.is_level_complete(level.id)
		var btn := _LevelCard.new()
		btn.level_data = level
		btn.is_completed = completed
		btn.position = Vector2(lx, 540)
		btn.level_pressed.connect(func(): _start_level(level.id))
		add_child(btn)


func _start_level(level_id: String) -> void:
	GameState.current_level_id = level_id
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _draw_back_button() -> void:
	var btn := Button.new()
	btn.text = "< TILLBAKA"
	btn.size = Vector2(200, 50)
	btn.position = Vector2(40, 40)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	btn.flat = true
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/WorldMap.tscn"))
	add_child(btn)


class _LevelCard extends Node2D:
	signal level_pressed

	var level_data: Dictionary = {}
	var is_completed: bool = false

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var w := 280.0
		var h := 180.0
		var bg := Color(0, 0.08, 0.15) if is_completed else Color(0.02, 0.02, 0.06)
		var border := Color(0, 0.8, 1.0, 0.7) if is_completed else Color(0.15, 0.25, 0.35)
		draw_rect(Rect2(-w/2, -h/2, w, h), bg)
		draw_rect(Rect2(-w/2, -h/2, w, h), border, false, 2.0)

		if is_completed:
			# Green checkmark accent
			draw_rect(Rect2(-w/2, -h/2, w, 3), Color(0.27, 1.0, 0.53))

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var local := to_local(event.global_position)
			if abs(local.x) < 140.0 and abs(local.y) < 90.0:
				level_pressed.emit()
