extends Node2D


func _ready() -> void:
	var result := GameState.level_result
	var score: int = int(result.get("score", 0))
	var world_id: String = result.get("world_id", "world-1")
	var is_world_complete: bool = bool(result.get("is_world_complete", false))
	var is_new_record: bool = bool(result.get("is_new_record", false))
	var high_score: int = int(result.get("high_score", score))

	_draw_background()

	var header := "VÄRLD SLUTFÖRD!" if is_world_complete else "UPPDRAG SLUTFÖRT!"
	_add_label(header, 280, 60, Color(0, 1, 1))
	_add_label("POÄNG: " + str(score).lpad(6, "0"), 380, 36, Color(1, 0.87, 0))

	var coins := int(score / 10)
	_add_label("+" + str(coins) + " MYNT", 450, 28, Color(0.27, 1.0, 0.53))

	if is_new_record:
		_add_label("NYTT REKORD!", 510, 26, Color(1.0, 0.87, 0.0))
	elif high_score > 0:
		_add_label("REKORD: " + str(high_score).lpad(6, "0"), 510, 20, Color(0.5, 0.55, 0.65))

	# Continue button
	var cont := Button.new()
	cont.text = "FORTSÄTT"
	cont.size = Vector2(300, 70)
	cont.position = Vector2(GameData.GAME_WIDTH / 2.0 - 150, 600)
	cont.add_theme_font_size_override("font_size", 32)
	cont.pressed.connect(func():
		if is_world_complete:
			get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")
		else:
			GameState.current_world_id = world_id
			get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	)
	_style_button(cont)
	add_child(cont)

	var hangar_btn := Button.new()
	hangar_btn.text = "HANGAREN"
	hangar_btn.size = Vector2(300, 70)
	hangar_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 150, 700)
	hangar_btn.add_theme_font_size_override("font_size", 32)
	hangar_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Hangar.tscn")
	)
	_style_button(hangar_btn)
	add_child(hangar_btn)


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)


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
