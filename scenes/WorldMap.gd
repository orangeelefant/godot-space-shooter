extends Node2D

const WORLD_POSITIONS: Array[Vector2] = [
	Vector2(200, 540),
	Vector2(500, 300),
	Vector2(800, 700),
	Vector2(1100, 350),
	Vector2(1400, 620),
]


func _ready() -> void:
	_draw_background()
	_draw_worlds()
	_draw_title()


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 200:
		var dot := ColorRect.new()
		var r := rng.randf_range(0.5, 2.0)
		dot.color = Color(1, 1, 1, rng.randf_range(0.2, 0.7))
		dot.size = Vector2(r * 2, r * 2)
		dot.position = Vector2(rng.randf() * GameData.GAME_WIDTH, rng.randf() * GameData.GAME_HEIGHT)
		add_child(dot)


func _draw_title() -> void:
	var lbl := Label.new()
	lbl.text = "VÄLJ VÄRLD"
	lbl.position = Vector2(0, 30)
	lbl.size = Vector2(GameData.GAME_WIDTH, 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 60)
	lbl.add_theme_color_override("font_color", Color(0, 1, 1))
	add_child(lbl)


func _draw_worlds() -> void:
	# Draw connection lines first
	for i in mini(GameData.WORLDS.size() - 1, WORLD_POSITIONS.size() - 1):
		var line := Line2D.new()
		line.add_point(WORLD_POSITIONS[i])
		line.add_point(WORLD_POSITIONS[i + 1])
		line.width = 2.0
		line.default_color = Color(0.2, 0.3, 0.5, 0.5)
		add_child(line)

	for i in mini(GameData.WORLDS.size(), WORLD_POSITIONS.size()):
		var world: Dictionary = GameData.WORLDS[i]
		var pos := WORLD_POSITIONS[i]
		var unlocked := SaveSystem.is_world_unlocked(world.id)
		_add_world_node(world, pos, i, unlocked)


func _add_world_node(world: Dictionary, pos: Vector2, index: int, unlocked: bool) -> void:
	var node := _WorldNode.new()
	node.world_data = world
	node.is_unlocked = unlocked
	node.position = pos
	node.world_selected.connect(func(): _on_world_selected(world.id))
	add_child(node)


func _on_world_selected(world_id: String) -> void:
	GameState.current_world_id = world_id
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


class _WorldNode extends Node2D:
	signal world_selected

	var world_data: Dictionary = {}
	var is_unlocked: bool = false
	var _hover: bool = false

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var color := Color(0, 0.8, 1.0) if is_unlocked else Color(0.3, 0.3, 0.4)
		draw_circle(Vector2.ZERO, 32.0, color.darkened(0.4))
		draw_arc(Vector2.ZERO, 32.0, 0, TAU, 48, color, 2.5)

		if not is_unlocked:
			# Lock icon
			draw_rect(Rect2(-8, -4, 16, 12), Color(0.4, 0.4, 0.5))
			draw_arc(Vector2(0, -4), 8, PI, TAU, 16, Color(0.4, 0.4, 0.5), 3.0)

	func _input(event: InputEvent) -> void:
		if not is_unlocked:
			return
		if event is InputEventMouseButton and event.pressed:
			var local := to_local(event.global_position)
			if local.length() < 36.0:
				world_selected.emit()
