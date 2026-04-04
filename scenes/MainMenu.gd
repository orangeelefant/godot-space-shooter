extends Node2D

var _selected_index: int = 0
const CARD_W := 240.0
const CARD_H := 310.0
const CARD_GAP := 265.0
const CARDS_START_X := 960.0 - 520.0

var _card_nodes: Array[Node2D] = []


func _ready() -> void:
	_draw_background()
	_build_ship_cards()
	_build_start_button()
	_build_title()


func _draw_background() -> void:
	# Black rect
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)

	# Scanlines (every 4px)
	for y in range(0, GameData.GAME_HEIGHT, 4):
		var line := ColorRect.new()
		line.color = Color(0, 0, 0, 0.15)
		line.size = Vector2(GameData.GAME_WIDTH, 1)
		line.position = Vector2(0, y)
		add_child(line)

	# Stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 120:
		var dot := ColorRect.new()
		var r := rng.randf_range(0.5, 2.5)
		dot.color = Color(0.27, 0.53, 0.8, rng.randf_range(0.2, 0.7))
		dot.size = Vector2(r * 2, r * 2)
		dot.position = Vector2(rng.randf() * GameData.GAME_WIDTH, rng.randf() * GameData.GAME_HEIGHT)
		add_child(dot)

	# Horizon line
	var horizon := ColorRect.new()
	horizon.color = Color(0, 1, 1, 0.3)
	horizon.size = Vector2(GameData.GAME_WIDTH, 1)
	horizon.position = Vector2(0, 960)
	add_child(horizon)


func _build_title() -> void:
	var title := Label.new()
	title.text = "STJÄRNKRIGAREN"
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	title.position = Vector2(0, 80)
	title.size = Vector2(GameData.GAME_WIDTH, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "VÄLJ DITT SKEPP"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.53, 0.53, 0.6))
	subtitle.position = Vector2(0, 195)
	subtitle.size = Vector2(GameData.GAME_WIDTH, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)


func _build_ship_cards() -> void:
	for i in GameData.SHIPS.size():
		var ship: Dictionary = GameData.SHIPS[i]
		var card := _create_card(i, ship)
		add_child(card)
		_card_nodes.append(card)


func _create_card(index: int, ship: Dictionary) -> Node2D:
	var card := _ShipCard.new()
	card.ship = ship
	card.is_selected = index == _selected_index
	card.position = Vector2(CARDS_START_X + index * CARD_GAP, 560)
	card.card_pressed.connect(func(): _select_ship(index))
	return card


func _select_ship(index: int) -> void:
	_selected_index = index
	for i in _card_nodes.size():
		var card := _card_nodes[i] as _ShipCard
		card.set_selected(i == _selected_index)


func _build_start_button() -> void:
	var btn := Button.new()
	btn.text = "STARTA SPELET"
	btn.add_theme_font_size_override("font_size", 38)
	btn.add_theme_color_override("font_color", Color(0, 1, 0.53))
	btn.size = Vector2(480, 70)
	btn.position = Vector2(720, 865)
	btn.flat = true
	btn.pressed.connect(_on_start)
	add_child(btn)

	var hint := Label.new()
	hint.text = "PILAR = RÖRELSE   |   MELLANSLAG = SKJUT   |   G = GASGRANAT"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.2, 0.2, 0.35))
	hint.position = Vector2(0, 985)
	hint.size = Vector2(GameData.GAME_WIDTH, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _on_start() -> void:
	var ship: Dictionary = GameData.SHIPS[_selected_index]
	var state := SaveSystem.load_game()
	state["ship_id"] = ship.id
	SaveSystem.save_game(state)
	get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")


# ── Inner card node ──────────────────────────────────────────────────────────

class _ShipCard extends Node2D:
	signal card_pressed

	var ship: Dictionary = {}
	var is_selected: bool = false
	var _hover: bool = false

	func _ready() -> void:
		queue_redraw()

	func set_selected(val: bool) -> void:
		is_selected = val
		queue_redraw()

	func _draw() -> void:
		var w := 240.0
		var h := 310.0
		var half_w := w / 2.0
		var half_h := h / 2.0

		var bg_col := Color(0, 0.1, 0.2) if is_selected else Color(0.02, 0.02, 0.06)
		var border_col := Color(0, 0.8, 1.0) if is_selected else Color(0.13, 0.2, 0.27)
		var border_w := 2.5 if is_selected else 1.0

		# Card background
		draw_rect(Rect2(-half_w, -half_h, w, h), bg_col)
		draw_rect(Rect2(-half_w, -half_h, w, h), border_col, false, border_w)

		# Accent bar top
		var ship_color: Color = ship.get("color", Color.CYAN)
		draw_rect(Rect2(-half_w, -half_h, w, 3), ship_color)

		# Ship indicator
		var alpha := 1.0 if is_selected else 0.6
		draw_circle(Vector2(0, -85), 22.0, Color(ship_color.r, ship_color.g, ship_color.b, alpha))
		draw_arc(Vector2(0, -85), 28.0, 0, TAU, 32, border_col, 1.5)

		# Stats
		var stats := [
			["SPD", int(ship.get("speed", 3)), 5],
			["SLD", int(ship.get("shield", 3)), 5],
			["FIR", int(ship.get("firepower", 3)), 5],
		]
		for si in stats.size():
			var sy := 10.0 + si * 30.0
			# Filled bar
			var bar_fill := float(stats[si][1]) / float(stats[si][2]) * 120.0
			draw_rect(Rect2(-60, sy - 4, 120, 8), Color(0.07, 0.13, 0.2))
			draw_rect(Rect2(-60, sy - 4, bar_fill, 8), Color(ship_color.r, ship_color.g, ship_color.b, 0.9 if is_selected else 0.4))

		# Selected indicator
		if is_selected:
			draw_rect(Rect2(-60, 105, 120, 22), Color(0, 0.5, 0.33, 0.3))

	func _gui_input(event: InputEvent) -> void:
		pass

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var local := to_local(event.global_position)
			if abs(local.x) < 120 and abs(local.y) < 155:
				card_pressed.emit()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAW:
			pass
