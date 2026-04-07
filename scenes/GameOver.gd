extends Node2D


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Glow layer
	_add_label("GAME OVER", 300, 110, Color(1, 0.15, 0.3, 0.2))
	_add_label("GAME OVER", 300, 106, Color(1, 0.15, 0.3))

	_add_label("DU FÖRLORADE", 430, 28, Color(0.6, 0.6, 0.7))

	if GameState.last_score > 0:
		_add_label("POÄNG: " + str(GameState.last_score).lpad(6, "0"), 478, 26, Color(1, 0.87, 0))

	var retry := Button.new()
	retry.text = "[ FÖRSÖK IGEN ]"
	retry.size = Vector2(400, 70)
	retry.position = Vector2(GameData.GAME_WIDTH / 2.0 - 200, 580)
	retry.add_theme_font_size_override("font_size", 34)
	retry.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	_style_button(retry)
	add_child(retry)

	var menu := Button.new()
	menu.text = "HUVUDMENY"
	menu.size = Vector2(400, 70)
	menu.position = Vector2(GameData.GAME_WIDTH / 2.0 - 200, 680)
	menu.add_theme_font_size_override("font_size", 28)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_style_button(menu)
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


func _style_button(btn: Button) -> void:
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.3)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.2, 0.6, 1.0, 0.8)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.15, 0.25, 0.55)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(0.3, 0.8, 1.0)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.05, 0.1, 0.2)
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color(0.0, 1.0, 0.8)
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
