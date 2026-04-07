extends Node2D

const UPGRADES := [
	{"id": "motor_2",   "name": "Motor Lv2",   "desc": "Snabbare rörelse",      "cost": 500,  "stat": "motor_level",   "target": 2},
	{"id": "cannon_2",  "name": "Dubbel Kanon", "desc": "Två kulor på en gång",  "cost": 800,  "stat": "cannon_level",  "target": "dubbel"},
	{"id": "shield_2",  "name": "Sköld Lv2",   "desc": "+1 träff att ta",        "cost": 600,  "stat": "shield_level",  "target": 2},
	{"id": "cannon_3",  "name": "Sprid-Kanon",  "desc": "Tre kulor i en spread",  "cost": 1200, "stat": "cannon_level",  "target": "spread"},
	{"id": "falcon_2",  "name": "Falk Lv2",     "desc": "Falken skjuter snabbare","cost": 1000, "stat": "falcon_level",  "target": 2},
	{"id": "motor_3",   "name": "Motor Lv3",   "desc": "Topphastighet",           "cost": 1200, "stat": "motor_level",   "target": 3},
	{"id": "gas_1",     "name": "Gas Granat",   "desc": "Köp en granat (max 3)",  "cost": 300,  "stat": "gas_grenades",  "target": 0},
]


func _ready() -> void:
	_draw_background()
	_draw_title()
	_draw_upgrades()
	_draw_back()


func _draw_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0.04)
	bg.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	add_child(bg)


func _draw_title() -> void:
	var state := SaveSystem.load_game()
	var coins: int = int(state.get("coins", 0))

	var title := Label.new()
	title.text = "HANGAREN"
	title.position = Vector2(0, 50)
	title.size = Vector2(GameData.GAME_WIDTH, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	add_child(title)

	var coins_lbl := Label.new()
	coins_lbl.text = "MYNT: " + str(coins)
	coins_lbl.position = Vector2(GameData.GAME_WIDTH / 2.0 - 200, 140)
	coins_lbl.size = Vector2(400, 48)
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_lbl.add_theme_font_size_override("font_size", 36)
	coins_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
	add_child(coins_lbl)


func _draw_upgrades() -> void:
	var cols := 3
	var card_w := 400.0
	var card_h := 200.0
	var gap := 60.0
	var total_w := cols * card_w + (cols - 1) * gap
	var start_x := (GameData.GAME_WIDTH - total_w) / 2.0
	var start_y := 200.0

	for i in UPGRADES.size():
		var upg: Dictionary = UPGRADES[i]
		var col := i % cols
		var row := i / cols
		var pos := Vector2(start_x + col * (card_w + gap), start_y + row * (card_h + gap))
		_add_upgrade_card(upg, pos, card_w, card_h)


func _add_upgrade_card(upg: Dictionary, pos: Vector2, w: float, h: float) -> void:
	var state := SaveSystem.load_game()
	var coins: int = int(state.get("coins", 0))
	var upgrades: Dictionary = state.get("upgrades", {})

	# Check if already purchased
	var current_val = upgrades.get(upg.stat, 1)
	var owned := false
	if upg.target is int:
		owned = int(current_val) >= int(upg.target)
	elif upg.stat == "cannon_level":
		const CANNON_ORDER := ["enkel", "dubbel", "spread", "laser", "slash"]
		owned = CANNON_ORDER.find(str(current_val)) >= CANNON_ORDER.find(str(upg.target))
	elif upg.stat == "gas_grenades":
		var gas: int = int(state.get("gas_grenades", GameData.MAX_GAS))
		owned = gas >= GameData.MAX_GAS
	else:
		owned = str(current_val) == str(upg.target)

	var can_buy := not owned and coins >= int(upg.cost)

	var card := _UpgradeCard.new()
	card.upg = upg
	card.is_owned = owned
	card.can_buy = can_buy
	card.card_size = Vector2(w, h)
	card.position = pos
	card.buy_pressed.connect(func(): _purchase(upg))
	add_child(card)


func _purchase(upg: Dictionary) -> void:
	var state := SaveSystem.load_game()
	var coins: int = int(state.get("coins", 0))
	if coins < int(upg.cost):
		return
	state["coins"] = coins - int(upg.cost)
	if upg.stat == "gas_grenades":
		var gas: int = int(state.get("gas_grenades", GameData.MAX_GAS))
		state["gas_grenades"] = mini(gas + 1, GameData.MAX_GAS)
	else:
		var upgrades: Dictionary = state.get("upgrades", {})
		upgrades[upg.stat] = upg.target
		state["upgrades"] = upgrades
	SaveSystem.save_game(state)
	get_tree().reload_current_scene()


func _draw_back() -> void:
	var btn := Button.new()
	btn.text = "< TILLBAKA"
	btn.size = Vector2(200, 50)
	btn.position = Vector2(40, 40)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/WorldMap.tscn"))
	_style_button(btn)
	add_child(btn)


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


class _UpgradeCard extends Node2D:
	signal buy_pressed

	var upg: Dictionary = {}
	var is_owned: bool = false
	var can_buy: bool = false
	var card_size: Vector2 = Vector2(400, 200)

	func _ready() -> void:
		queue_redraw()

		# Upgrade name
		var name_lbl := Label.new()
		name_lbl.text = upg.get("name", "").to_upper()
		name_lbl.position = Vector2(16, 18)
		name_lbl.size = Vector2(card_size.x - 32, 36)
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color",
			Color(0, 1, 0.53) if is_owned else Color(0.8, 0.9, 1.0))
		add_child(name_lbl)

		# Description
		var desc_lbl := Label.new()
		desc_lbl.text = upg.get("desc", "")
		desc_lbl.position = Vector2(16, 62)
		desc_lbl.size = Vector2(card_size.x - 32, 60)
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(desc_lbl)

		if is_owned:
			var owned_lbl := Label.new()
			owned_lbl.text = "ÄGAD"
			owned_lbl.position = Vector2(0, card_size.y - 52)
			owned_lbl.size = Vector2(card_size.x, 36)
			owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			owned_lbl.add_theme_font_size_override("font_size", 18)
			owned_lbl.add_theme_color_override("font_color", Color(0, 1, 0.53))
			add_child(owned_lbl)
		else:
			var btn := Button.new()
			btn.text = "KÖPA " + str(upg.get("cost", 0)) + " ¤"
			btn.size = Vector2(160, 40)
			btn.position = Vector2(card_size.x / 2.0 - 80, card_size.y - 55)
			btn.add_theme_font_size_override("font_size", 18)
			btn.disabled = not can_buy
			btn.pressed.connect(func(): buy_pressed.emit())
			_apply_style(btn)
			add_child(btn)

	func _apply_style(btn: Button) -> void:
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

	func _draw() -> void:
		var w := card_size.x
		var h := card_size.y
		var bg := Color(0, 0.12, 0.2) if is_owned else Color(0.02, 0.02, 0.06)
		var border := Color(0, 0.8, 1.0, 0.8) if is_owned else (Color(0, 0.6, 0.3) if can_buy else Color(0.15, 0.2, 0.3))
		draw_rect(Rect2(0, 0, w, h), bg)
		draw_rect(Rect2(0, 0, w, h), border, false, 2.0)
		if is_owned:
			draw_rect(Rect2(0, 0, w, 3), Color(0, 1, 0.53))
