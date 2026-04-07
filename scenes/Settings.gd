extends Node2D


func _ready() -> void:
	_draw_background()
	_draw_title()
	_draw_options()
	_draw_back()


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0.04)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i in 100:
		var dot := ColorRect.new()
		var r := rng.randf_range(0.5, 1.5)
		dot.color = Color(1, 1, 1, rng.randf_range(0.1, 0.35))
		dot.size = Vector2(r * 2, r * 2)
		dot.position = Vector2(rng.randf() * GameData.GAME_WIDTH, rng.randf() * GameData.GAME_HEIGHT)
		add_child(dot)


func _draw_title() -> void:
	var lbl := Label.new()
	lbl.text = "INSTÄLLNINGAR"
	lbl.position = Vector2(0, 60)
	lbl.size = Vector2(GameData.GAME_WIDTH, 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(0, 1, 1))
	add_child(lbl)

	var sep := ColorRect.new()
	sep.color = Color(0, 1, 0.8, 0.25)
	sep.size = Vector2(500, 1)
	sep.position = Vector2(GameData.GAME_WIDTH / 2.0 - 250, 160)
	add_child(sep)


func _draw_options() -> void:
	var cx := GameData.GAME_WIDTH / 2.0

	# Audio toggle
	var audio_lbl := Label.new()
	audio_lbl.text = "LJUD"
	audio_lbl.position = Vector2(0, 240)
	audio_lbl.size = Vector2(GameData.GAME_WIDTH, 36)
	audio_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_lbl.add_theme_font_size_override("font_size", 22)
	audio_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	add_child(audio_lbl)

	var audio_btn := Button.new()
	audio_btn.text = "PÅ" if AudioSystem._enabled else "AV"
	audio_btn.size = Vector2(300, 64)
	audio_btn.position = Vector2(cx - 150, 290)
	audio_btn.add_theme_font_size_override("font_size", 34)
	audio_btn.add_theme_color_override("font_color",
		Color(0, 1, 0.53) if AudioSystem._enabled else Color(0.7, 0.2, 0.2))
	audio_btn.flat = true
	audio_btn.pressed.connect(func():
		AudioSystem.set_enabled(not AudioSystem._enabled)
		audio_btn.text = "PÅ" if AudioSystem._enabled else "AV"
		audio_btn.add_theme_color_override("font_color",
			Color(0, 1, 0.53) if AudioSystem._enabled else Color(0.7, 0.2, 0.2))
	)
	add_child(audio_btn)

	# Divider
	var div := ColorRect.new()
	div.color = Color(0.1, 0.15, 0.25)
	div.size = Vector2(500, 1)
	div.position = Vector2(cx - 250, 420)
	add_child(div)

	# Reset progress section
	var reset_lbl := Label.new()
	reset_lbl.text = "SPARDATA"
	reset_lbl.position = Vector2(0, 445)
	reset_lbl.size = Vector2(GameData.GAME_WIDTH, 36)
	reset_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_lbl.add_theme_font_size_override("font_size", 22)
	reset_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	add_child(reset_lbl)

	var reset_btn := Button.new()
	reset_btn.text = "NOLLSTÄLL ALL FRAMSTEG"
	reset_btn.size = Vector2(480, 64)
	reset_btn.position = Vector2(cx - 240, 494)
	reset_btn.add_theme_font_size_override("font_size", 26)
	reset_btn.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))
	reset_btn.flat = true
	reset_btn.pressed.connect(_confirm_reset)
	add_child(reset_btn)

	var warn := Label.new()
	warn.text = "Raderar alla slutförda nivåer, mynt och uppgraderingar"
	warn.position = Vector2(0, 568)
	warn.size = Vector2(GameData.GAME_WIDTH, 28)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", 14)
	warn.add_theme_color_override("font_color", Color(0.45, 0.25, 0.25))
	add_child(warn)


func _confirm_reset() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 50
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0, 0.03, 0.1)
	panel.size = Vector2(520, 230)
	panel.position = Vector2(GameData.GAME_WIDTH / 2.0 - 260, GameData.GAME_HEIGHT / 2.0 - 115)
	overlay.add_child(panel)

	var border_draw := _BorderRect.new()
	border_draw.panel_pos = panel.position
	border_draw.panel_size = panel.size
	overlay.add_child(border_draw)

	var lbl := Label.new()
	lbl.text = "NOLLSTÄLL ALL SPARDATA?"
	lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 250, GameData.GAME_HEIGHT / 2.0 - 72)
	lbl.size = Vector2(500, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	overlay.add_child(lbl)

	var yes_btn := Button.new()
	yes_btn.text = "JA, NOLLSTÄLL"
	yes_btn.size = Vector2(220, 58)
	yes_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 240, GameData.GAME_HEIGHT / 2.0 + 16)
	yes_btn.add_theme_font_size_override("font_size", 20)
	yes_btn.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	yes_btn.flat = true
	yes_btn.pressed.connect(func():
		SaveSystem.reset()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	overlay.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "AVBRYT"
	no_btn.size = Vector2(220, 58)
	no_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 + 20, GameData.GAME_HEIGHT / 2.0 + 16)
	no_btn.add_theme_font_size_override("font_size", 20)
	no_btn.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	no_btn.flat = true
	no_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(no_btn)


func _draw_back() -> void:
	var btn := Button.new()
	btn.text = "< TILLBAKA"
	btn.size = Vector2(200, 50)
	btn.position = Vector2(40, 40)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	btn.flat = true
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	add_child(btn)


class _BorderRect extends Node2D:
	var panel_pos: Vector2 = Vector2.ZERO
	var panel_size: Vector2 = Vector2.ZERO

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(panel_pos, panel_size), Color(0, 0.8, 1.0, 0.45), false, 1.5)
