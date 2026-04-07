extends Node2D


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	for i in 180:
		var dot := ColorRect.new()
		var r := rng.randf_range(0.5, 2.5)
		dot.color = Color(1, 1, 1, rng.randf_range(0.2, 0.8))
		dot.size = Vector2(r * 2, r * 2)
		dot.position = Vector2(rng.randf() * GameData.GAME_WIDTH, rng.randf() * GameData.GAME_HEIGHT)
		add_child(dot)

	_add_label("SEGER!", 260, 106, Color(0, 1, 0.8, 0.2))
	var title_lbl := _add_label("SEGER!", 260, 102, Color(0, 1, 0.8))
	_add_label("DU HAR RÄDDAT GALAXEN", 390, 26, Color(0.67, 0.73, 0.8))

	# Separator
	var line := ColorRect.new()
	line.color = Color(0, 1, 0.8, 0.3)
	line.size = Vector2(500, 1)
	line.position = Vector2(GameData.GAME_WIDTH / 2.0 - 250, 440)
	add_child(line)

	var btn := Button.new()
	btn.text = "[ TILLBAKA TILL MENYN ]"
	btn.size = Vector2(500, 70)
	btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 250, 560)
	btn.add_theme_font_size_override("font_size", 32)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_style_button(btn)
	add_child(btn)

	# Pulse animation on title
	var tween := create_tween().set_loops()
	tween.tween_property(title_lbl, "scale", Vector2(1.04, 1.04), 0.9)
	tween.tween_property(title_lbl, "scale", Vector2(1.0, 1.0), 0.9)


func _add_label(text: String, y: float, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(GameData.GAME_WIDTH, size + 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl


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
