extends CanvasLayer

var _lives_label: Label
var _gas_label: Label
var _score_label: Label
var _mission_label: Label
var _timer_label: Label
var _frozen_overlay: ColorRect
var _shield_label: Label
var _combo_label: Label
var _lives_display: _LivesDisplay
var _combo_display: _ComboDisplay


class _LivesDisplay extends Node2D:
	var lives: int = 3

	func _draw() -> void:
		for i in lives:
			var x := float(i) * 24.0
			# Small arrowhead ship icon (same shape as player)
			var pts := PackedVector2Array([
				Vector2(x + 8, 0),
				Vector2(x - 4, -5),
				Vector2(x - 2, 0),
				Vector2(x - 4, 5),
			])
			draw_polygon(pts, [Color(0.4, 0.8, 1.0)])
			draw_polyline(pts, Color(0, 1, 1, 0.7), 1.0)


class _ComboDisplay extends Node2D:
	var combo: int = 0
	var multiplier: int = 1
	var _pulse: float = 0.0

	func _process(delta: float) -> void:
		if combo > 0:
			_pulse += delta * 4.0
			queue_redraw()

	func _draw() -> void:
		if combo <= 0:
			return
		var arc_color := Color(1.0, 0.3, 0.0) if multiplier >= 5 else \
						 Color(1.0, 0.7, 0.0) if multiplier >= 3 else \
						 Color(0.3, 0.8, 1.0)
		var arc_frac := minf(float(combo) / 20.0, 1.0)
		var r := 28.0 + sin(_pulse) * 3.0
		draw_arc(Vector2(30, 12), r, -PI / 2.0, -PI / 2.0 + TAU * arc_frac, 32, arc_color, 3.0)
		draw_arc(Vector2(30, 12), r + 4, -PI / 2.0, -PI / 2.0 + TAU * arc_frac, 32, Color(arc_color.r, arc_color.g, arc_color.b, 0.3), 5.0)


func _ready() -> void:
	layer = 10

	# Top HUD bar background
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0.07, 0.85)
	bar.size = Vector2(GameData.GAME_WIDTH, 60)
	add_child(bar)

	# Neon bottom border
	var border := ColorRect.new()
	border.color = Color(0, 1, 0.8, 0.3)
	border.size = Vector2(GameData.GAME_WIDTH, 1)
	border.position = Vector2(0, 59)
	add_child(border)

	# Lives display: ship icons positioned at top-left
	_lives_display = _LivesDisplay.new()
	_lives_display.position = Vector2(28, 30)
	add_child(_lives_display)

	_lives_label = _make_label(20, 15, "HP  |||", Color(1, 0.27, 0.4), 22)
	_lives_label.visible = false

	_gas_label   = _make_label(220, 15, "GAS  3", Color(1, 0.53, 0), 22)
	_score_label = _make_label(400, 15, "SCR  000000", Color(1, 0.87, 0), 22)

	_mission_label = _make_label(0, 15, "", Color(0.67, 0.73, 0.8), 18)
	_mission_label.size = Vector2(GameData.GAME_WIDTH, 40)
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_timer_label = _make_label(0, 70, "", Color(1, 0.27, 0.27), 38)
	_timer_label.size = Vector2(GameData.GAME_WIDTH, 60)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_shield_label = _make_label(630, 15, "", Color(0.3, 0.8, 1.0), 22)

	_combo_label = _make_label(0, 140, "", Color(1.0, 0.87, 0.0), 42)
	_combo_label.size = Vector2(GameData.GAME_WIDTH, 60)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.visible = false

	# Combo arc display, positioned to align with the combo label area
	_combo_display = _ComboDisplay.new()
	_combo_display.position = Vector2(20, 148)
	add_child(_combo_display)


func _make_label(x: float, y: float, text: String, color: Color, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(x, y)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl


func update_lives(lives: int) -> void:
	_lives_display.lives = lives
	_lives_display.queue_redraw()


func update_gas(count: int) -> void:
	_gas_label.text = "GAS  " + str(count)


func update_score(score: int) -> void:
	_score_label.text = "POANG  %06d" % score
	# Pop animation
	var tween := create_tween()
	tween.tween_property(_score_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(_score_label, "scale", Vector2(1.0, 1.0), 0.12)


func update_mission(text: String) -> void:
	_mission_label.text = text


func update_timer(seconds: int) -> void:
	if seconds > 0:
		_timer_label.text = "T-%03d" % seconds
		_timer_label.add_theme_color_override("font_color",
			Color(1, 0, 0) if seconds <= 10 else Color(1, 0.27, 0.27))
	else:
		_timer_label.text = ""


func update_combo(combo: int, multiplier: int) -> void:
	if combo <= 1 or multiplier <= 1:
		_combo_label.visible = false
		_combo_display.combo = 0
		_combo_display.queue_redraw()
		return
	_combo_label.text = "x" + str(multiplier) + "  COMBO " + str(combo) + "!"
	_combo_label.visible = true
	_combo_display.combo = combo
	_combo_display.multiplier = multiplier
	_combo_display.queue_redraw()


func update_shield(active: bool) -> void:
	if _shield_label:
		_shield_label.text = "SLD  ON" if active else ""


func show_damage_flash() -> void:
	var vignette := ColorRect.new()
	vignette.color = Color(0.9, 0.1, 0.0, 0.45)
	vignette.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	vignette.z_index = 25
	add_child(vignette)
	var tween := create_tween()
	tween.tween_property(vignette, "modulate:a", 0.0, 0.4)
	tween.tween_callback(vignette.queue_free)


func show_frozen() -> void:
	if _frozen_overlay and is_instance_valid(_frozen_overlay):
		return
	_frozen_overlay = ColorRect.new()
	_frozen_overlay.color = Color(0, 0.27, 1.0, 0.18)
	_frozen_overlay.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	_frozen_overlay.position = Vector2.ZERO
	add_child(_frozen_overlay)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(_frozen_overlay):
			_frozen_overlay.queue_free()
	)
