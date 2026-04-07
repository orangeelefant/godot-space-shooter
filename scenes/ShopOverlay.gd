extends CanvasLayer

signal closed

const CANNON_ORDER := ["enkel", "dubbel", "spread", "laser", "slash"]
const UPGRADE_COST := 150

var _current_cannon: String = "enkel"
var _on_purchase: Callable


func setup(current_cannon: String, on_purchase: Callable) -> void:
	_current_cannon = current_cannon
	_on_purchase = on_purchase


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Dim background — dark navy, more opaque
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.18, 0.92)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Panel
	var panel := Node2D.new()
	panel.position = Vector2(GameData.GAME_WIDTH / 2.0, GameData.GAME_HEIGHT / 2.0)
	add_child(panel)

	var _draw_panel := func():
		panel.draw_rect(Rect2(-200, -120, 400, 250), Color(0.05, 0.05, 0.15))
		# Outer bright cyan border
		panel.draw_rect(Rect2(-200, -120, 400, 250), Color(0.0, 0.9, 1.0, 0.9), false, 3.0)
		# Inner glow border
		panel.draw_rect(Rect2(-196, -116, 392, 242), Color(0.0, 0.6, 0.8, 0.4), false, 8.0)
	panel.connect("draw", _draw_panel)
	panel.queue_redraw()

	# Title
	var title := Label.new()
	title.text = "\u26a1 VAPENUPPGRADERING \u26a1"
	var title_settings := LabelSettings.new()
	title_settings.font_size = 24
	title_settings.font_color = Color(0.0, 1.0, 0.9)
	title.label_settings = title_settings
	title.position = Vector2(GameData.GAME_WIDTH / 2.0 - 190, GameData.GAME_HEIGHT / 2.0 - 110)
	title.size = Vector2(380, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Välj uppgradering innan nästa våg!"
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.position = Vector2(GameData.GAME_WIDTH / 2.0 - 190, GameData.GAME_HEIGHT / 2.0 - 78)
	subtitle.size = Vector2(380, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	# Current cannon label
	var current_idx := CANNON_ORDER.find(_current_cannon)
	var current_lbl := Label.new()
	current_lbl.text = "Nuvarande: %s" % _current_cannon.to_upper()
	current_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	current_lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 140, GameData.GAME_HEIGHT / 2.0 - 40)
	add_child(current_lbl)

	# Upgrade button (if not at max)
	if current_idx < CANNON_ORDER.size() - 1:
		var next_cannon: String = CANNON_ORDER[current_idx + 1]
		var coins := SaveSystem.get_coins()
		var can_afford := coins >= UPGRADE_COST

		var upgrade_btn := Button.new()
		upgrade_btn.text = "Uppgradera \u2192 %s  (%d mynt)" % [next_cannon.to_upper(), UPGRADE_COST]
		upgrade_btn.disabled = not can_afford
		upgrade_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 10)
		upgrade_btn.size = Vector2(320, 44)
		upgrade_btn.pressed.connect(func():
			SaveSystem.spend_coins(UPGRADE_COST)
			var state := SaveSystem.load_game()
			if not state.has("upgrades"):
				state["upgrades"] = {}
			state["upgrades"]["cannon_level"] = next_cannon
			SaveSystem.save_game(state)
			_on_purchase.call(next_cannon)
			_close()
		)
		_style_button(upgrade_btn)
		var upg_style_normal := StyleBoxFlat.new()
		upg_style_normal.bg_color = Color(0.1, 0.3, 0.8)
		upg_style_normal.border_width_left = 2
		upg_style_normal.border_width_right = 2
		upg_style_normal.border_width_top = 2
		upg_style_normal.border_width_bottom = 2
		upg_style_normal.border_color = Color(0.2, 0.6, 1.0, 0.8)
		upg_style_normal.corner_radius_top_left = 4
		upg_style_normal.corner_radius_top_right = 4
		upg_style_normal.corner_radius_bottom_left = 4
		upg_style_normal.corner_radius_bottom_right = 4
		var upg_style_hover := StyleBoxFlat.new()
		upg_style_hover.bg_color = Color(0.2, 0.5, 1.0)
		upg_style_hover.border_width_left = 2
		upg_style_hover.border_width_right = 2
		upg_style_hover.border_width_top = 2
		upg_style_hover.border_width_bottom = 2
		upg_style_hover.border_color = Color(0.3, 0.8, 1.0)
		upg_style_hover.corner_radius_top_left = 4
		upg_style_hover.corner_radius_top_right = 4
		upg_style_hover.corner_radius_bottom_left = 4
		upg_style_hover.corner_radius_bottom_right = 4
		upgrade_btn.add_theme_stylebox_override("normal", upg_style_normal)
		upgrade_btn.add_theme_stylebox_override("hover", upg_style_hover)
		add_child(upgrade_btn)
	else:
		var max_lbl := Label.new()
		max_lbl.text = "MAX NIVÅ UPPNÅDD"
		max_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		max_lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 100, GameData.GAME_HEIGHT / 2.0 + 20)
		add_child(max_lbl)

	# Close button — green, visible
	var close_btn := Button.new()
	close_btn.text = "\u25b6  FORTSÄTT (HOPPA ÖVER)"
	close_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 160, GameData.GAME_HEIGHT / 2.0 + 65)
	close_btn.size = Vector2(320, 44)
	close_btn.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))
	var close_normal := StyleBoxFlat.new()
	close_normal.bg_color = Color(0.0, 0.8, 0.3)
	close_normal.border_width_left = 2
	close_normal.border_width_right = 2
	close_normal.border_width_top = 2
	close_normal.border_width_bottom = 2
	close_normal.border_color = Color(0.0, 1.0, 0.5)
	close_normal.corner_radius_top_left = 4
	close_normal.corner_radius_top_right = 4
	close_normal.corner_radius_bottom_left = 4
	close_normal.corner_radius_bottom_right = 4
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.0, 1.0, 0.4)
	close_hover.border_width_left = 2
	close_hover.border_width_right = 2
	close_hover.border_width_top = 2
	close_hover.border_width_bottom = 2
	close_hover.border_color = Color(0.0, 1.0, 0.6)
	close_hover.corner_radius_top_left = 4
	close_hover.corner_radius_top_right = 4
	close_hover.corner_radius_bottom_left = 4
	close_hover.corner_radius_bottom_right = 4
	var close_pressed := StyleBoxFlat.new()
	close_pressed.bg_color = Color(0.0, 0.5, 0.2)
	close_pressed.border_width_left = 2
	close_pressed.border_width_right = 2
	close_pressed.border_width_top = 2
	close_pressed.border_width_bottom = 2
	close_pressed.border_color = Color(0.0, 1.0, 0.8)
	close_pressed.corner_radius_top_left = 4
	close_pressed.corner_radius_top_right = 4
	close_pressed.corner_radius_bottom_left = 4
	close_pressed.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", close_normal)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_pressed)
	close_btn.pressed.connect(_close)
	add_child(close_btn)


func _close() -> void:
	closed.emit()
	get_tree().paused = false
	queue_free()


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
