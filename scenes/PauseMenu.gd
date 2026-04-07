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
	resume.add_theme_color_override("font_color", Color(0, 1, 0.53))
	resume.flat = true
	resume.pressed.connect(func(): resume_pressed.emit())
	add_child(resume)

	var audio_btn := Button.new()
	audio_btn.text = "LJUD:  PÅ" if AudioSystem._enabled else "LJUD:  AV"
	audio_btn.size = Vector2(320, 55)
	audio_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 90)
	audio_btn.add_theme_font_size_override("font_size", 24)
	audio_btn.add_theme_color_override("font_color",
		Color(0.4, 0.8, 1.0) if AudioSystem._enabled else Color(0.7, 0.3, 0.3))
	audio_btn.flat = true
	audio_btn.pressed.connect(func():
		AudioSystem.set_enabled(not AudioSystem._enabled)
		audio_btn.text = "LJUD:  PÅ" if AudioSystem._enabled else "LJUD:  AV"
		audio_btn.add_theme_color_override("font_color",
			Color(0.4, 0.8, 1.0) if AudioSystem._enabled else Color(0.7, 0.3, 0.3))
	)
	add_child(audio_btn)

	var quit := Button.new()
	quit.text = "AVSLUTA UPPDRAG"
	quit.size = Vector2(320, 60)
	quit.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 162)
	quit.add_theme_font_size_override("font_size", 24)
	quit.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	quit.flat = true
	quit.pressed.connect(func(): quit_pressed.emit())
	add_child(quit)


func _make_border(pos: Vector2, sz: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	var drawer := _BorderDraw.new()
	drawer.sz = sz
	n.add_child(drawer)
	return n


class _BorderDraw extends Node2D:
	var sz: Vector2 = Vector2.ZERO
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0.8, 1.0, 0.5), false, 1.5)
