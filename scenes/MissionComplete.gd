extends Node2D


func _ready() -> void:
	var result := GameState.level_result
	var score: int = int(result.get("score", 0))
	var world_id: String = result.get("world_id", "world-1")
	var is_world_complete: bool = bool(result.get("is_world_complete", false))

	_draw_background()

	var header := "VÄRLD SLUTFÖRD!" if is_world_complete else "UPPDRAG SLUTFÖRT!"
	_add_label(header, 280, 60, Color(0, 1, 1))
	_add_label("POÄNG: " + str(score).lpad(6, "0"), 380, 36, Color(1, 0.87, 0))

	var coins := int(score / 10)
	_add_label("+" + str(coins) + " MYNT", 450, 28, Color(0.27, 1.0, 0.53))

	# Continue button
	var cont := Button.new()
	cont.text = "FORTSÄTT"
	cont.size = Vector2(300, 70)
	cont.position = Vector2(GameData.GAME_WIDTH / 2.0 - 150, 600)
	cont.add_theme_font_size_override("font_size", 32)
	cont.add_theme_color_override("font_color", Color(0, 1, 0.53))
	cont.flat = true
	cont.pressed.connect(func():
		if is_world_complete:
			get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")
		else:
			GameState.current_world_id = world_id
			get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	)
	add_child(cont)

	var hangar_btn := Button.new()
	hangar_btn.text = "HANGAREN"
	hangar_btn.size = Vector2(300, 70)
	hangar_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 150, 700)
	hangar_btn.add_theme_font_size_override("font_size", 32)
	hangar_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	hangar_btn.flat = true
	hangar_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Hangar.tscn")
	)
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
