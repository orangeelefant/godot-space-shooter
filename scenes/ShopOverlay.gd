extends CanvasLayer

signal closed

const CANNON_ORDER := ["enkel", "dubbel", "spread", "laser"]
const UPGRADE_COST := 15

var _current_cannon: String = "enkel"
var _on_purchase: Callable


func setup(current_cannon: String, on_purchase: Callable) -> void:
	_current_cannon = current_cannon
	_on_purchase = on_purchase


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Dim background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.1, 0.75)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Panel
	var panel := Node2D.new()
	panel.position = Vector2(GameData.GAME_WIDTH / 2.0, GameData.GAME_HEIGHT / 2.0)
	add_child(panel)

	var _draw_panel := func():
		panel.draw_rect(Rect2(-200, -110, 400, 220), Color(0.05, 0.05, 0.15))
		panel.draw_rect(Rect2(-200, -110, 400, 220), Color(0.2, 0.6, 1.0, 0.6), false, 2.0)
	panel.connect("draw", _draw_panel)
	panel.queue_redraw()

	# Title
	var title := Label.new()
	title.text = "VAPENBUTIK"
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	title.position = Vector2(GameData.GAME_WIDTH / 2.0 - 80, GameData.GAME_HEIGHT / 2.0 - 95)
	add_child(title)

	# Current cannon label
	var current_idx := CANNON_ORDER.find(_current_cannon)
	var current_lbl := Label.new()
	current_lbl.text = "Nuvarande: %s" % _current_cannon.to_upper()
	current_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	current_lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 140, GameData.GAME_HEIGHT / 2.0 - 50)
	add_child(current_lbl)

	# Upgrade button (if not at max)
	if current_idx < CANNON_ORDER.size() - 1:
		var next_cannon := CANNON_ORDER[current_idx + 1]
		var coins := SaveSystem.get_coins()
		var can_afford := coins >= UPGRADE_COST

		var upgrade_btn := Button.new()
		upgrade_btn.text = "Uppgradera → %s  (%d mynt)" % [next_cannon.to_upper(), UPGRADE_COST]
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
		add_child(upgrade_btn)
	else:
		var max_lbl := Label.new()
		max_lbl.text = "MAX NIVÅ UPPNÅDD"
		max_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		max_lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 100, GameData.GAME_HEIGHT / 2.0 + 20)
		add_child(max_lbl)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "FORTSÄTT"
	close_btn.position = Vector2(GameData.GAME_WIDTH / 2.0 - 80, GameData.GAME_HEIGHT / 2.0 + 65)
	close_btn.size = Vector2(160, 40)
	close_btn.pressed.connect(_close)
	add_child(close_btn)


func _close() -> void:
	closed.emit()
	get_tree().paused = false
	queue_free()
