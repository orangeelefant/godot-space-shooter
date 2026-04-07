extends CanvasLayer

signal resume_pressed
signal quit_pressed

var _overlay: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.72)
	_overlay.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(_overlay)

	var panel := ColorRect.new()
	panel.color = Color(0, 0.04, 0.1)
	panel.size = Vector2(480, 380)
	panel.position = Vector2(GameData.GAME_WIDTH / 2.0 - 240, GameData.GAME_HEIGHT / 2.0 - 190)
	add_child(panel)

	var border := _make_border(panel.position, panel.size)
	add_child(border)

	var title := Label.new()
	title.text = "PAUS"
	title.position = Vector2(GameData.GAME_WIDTH / 2.0 - 240, GameData.GAME_HEIGHT / 2.0 - 150)
	title.size = Vector2(480, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	add_child(title)

	var resume := Button.new()
	resume.text = "FORTSÄTT"
	resume.size = Vector2(320, 60)
	resume.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 10)
	resume.add_theme_font_size_override("font_size", 30)
	resume.pressed.connect(func(): resume_pressed.emit())
	_style_button(resume)
	add_child(resume)

	var audio_btn := Button.new()
	audio_btn.text = "LJUD:  PÅ" if AudioSystem._enabled else "LJUD:  AV"
	audio_btn.size = Vector2(320, 55)
	audio_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 90)
	audio_btn.add_theme_font_size_override("font_size", 24)
	audio_btn.pressed.connect(func():
		AudioSystem.set_enabled(not AudioSystem._enabled)
		audio_btn.text = "LJUD:  PÅ" if AudioSystem._enabled else "LJUD:  AV"
	)
	_style_button(audio_btn)
	add_child(audio_btn)

	var quit := Button.new()
	quit.text = "AVSLUTA UPPDRAG"
	quit.size = Vector2(320, 60)
	quit.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 162)
	quit.add_theme_font_size_override("font_size", 24)
	quit.pressed.connect(func(): quit_pressed.emit())
	_style_button(quit)
	add_child(quit)


func _make_border(pos: Vector2, sz: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var drawer := _BorderDraw.new()
	drawer.sz = sz
	n.add_child(drawer)
	return n


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


class _BorderDraw extends Node2D:
	var sz: Vector2 = Vector2.ZERO
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0.8, 1.0, 0.5), false, 1.5)
