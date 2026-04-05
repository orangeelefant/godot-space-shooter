extends Node2D


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Glow layer
	_add_label("GAME OVER", 300, 110, Color(1, 0.15, 0.3, 0.2))
	_add_label("GAME OVER", 300, 106, Color(1, 0.15, 0.3))

	_add_label("DU FÖRLORADE", 440, 28, Color(0.6, 0.6, 0.7))

	var retry := Button.new()
	retry.text = "[ FÖRSÖK IGEN ]"
	retry.size = Vector2(400, 70)
	retry.position = Vector2(GameData.GAME_WIDTH / 2.0 - 200, 580)
	retry.add_theme_font_size_override("font_size", 34)
	retry.add_theme_color_override("font_color", Color(1, 0.27, 0.4))
	retry.flat = true
	retry.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	add_child(retry)

	var menu := Button.new()
	menu.text = "HUVUDMENY"
	menu.size = Vector2(400, 70)
	menu.position = Vector2(GameData.GAME_WIDTH / 2.0 - 200, 680)
	menu.add_theme_font_size_override("font_size", 28)
	menu.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	menu.flat = true
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(menu)


func _add_label(text: String, y: float, size: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(GameData.GAME_WIDTH, size + 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
