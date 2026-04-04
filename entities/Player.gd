class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal damaged
signal died

var ship_data: Dictionary = {}
var upgrades: Dictionary = {}
var lives: int = GameData.STARTING_LIVES

var _speed: float = 300.0
var _frozen: bool = false
var _invincible: bool = false
var _invincible_timer: float = 0.0
var _freeze_timer: float = 0.0
var _blink_timer: float = 0.0
var _color: Color = Color.CYAN
var _shoot_pressed: bool = false
var _gas_pressed: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2  # collide with enemies

	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 14.0
	cap.height = 28.0
	shape.shape = cap
	shape.rotation_degrees = 90
	add_child(shape)

	if not ship_data.is_empty():
		_apply_ship_data()

	queue_redraw()


func setup(ship: Dictionary, upgrade_state: Dictionary) -> void:
	ship_data = ship
	upgrades = upgrade_state
	_apply_ship_data()
	queue_redraw()


func _apply_ship_data() -> void:
	var base_speed := float(ship_data.get("speed", 3)) * 60.0
	var motor_bonus := float(upgrades.get("motor_level", 1) - 1) * 20.0
	_speed = base_speed + motor_bonus
	_color = ship_data.get("color", Color.CYAN)


func _physics_process(delta: float) -> void:
	if _frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  dir.x -= 1.0
	if Input.is_action_pressed("ui_right"): dir.x += 1.0
	if Input.is_action_pressed("ui_up"):    dir.y -= 1.0
	if Input.is_action_pressed("ui_down"):  dir.y += 1.0

	velocity = dir.normalized() * _speed
	move_and_slide()

	# Clamp to screen
	position.x = clampf(position.x, 30.0, GameData.GAME_WIDTH - 30.0)
	position.y = clampf(position.y, 70.0, GameData.GAME_HEIGHT - 30.0)


func _process(delta: float) -> void:
	_shoot_pressed = Input.is_action_just_pressed("shoot")
	_gas_pressed = Input.is_action_just_pressed("gas")

	if _invincible:
		_invincible_timer -= delta
		_blink_timer += delta
		modulate.a = 0.3 if fmod(_blink_timer, 0.15) < 0.075 else 1.0
		if _invincible_timer <= 0.0:
			_invincible = false
			modulate.a = 1.0
			queue_redraw()

	if _frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			_frozen = false
			modulate = Color.WHITE
			queue_redraw()


func _draw() -> void:
	# Ship silhouette — arrow pointing right
	var c := _color
	var pts := PackedVector2Array([
		Vector2(34, 0),
		Vector2(-20, -18),
		Vector2(-10, 0),
		Vector2(-20, 18),
	])
	draw_polygon(pts, PackedColorArray([c]))
	# Engine glow
	draw_circle(Vector2(-16, 0), 7.0, c.lightened(0.4))
	# Cockpit
	draw_circle(Vector2(12, 0), 6.0, Color(0.7, 0.9, 1.0, 0.8))


func take_damage(amount: int = 1) -> void:
	if _invincible or _frozen:
		return
	lives -= amount
	lives_changed.emit(lives)
	damaged.emit()
	if lives <= 0:
		died.emit()
	else:
		_start_invincibility()


func add_life() -> void:
	if lives < GameData.MAX_LIVES:
		lives += 1
		lives_changed.emit(lives)


func freeze() -> void:
	_frozen = true
	_freeze_timer = GameData.FREEZE_DURATION
	modulate = Color(0.6, 0.8, 1.0)


func is_shoot_pressed() -> bool:
	return _shoot_pressed


func is_gas_pressed() -> bool:
	return _gas_pressed


func get_muzzle_pos() -> Vector2:
	return position + Vector2(40.0, 0.0)


func _start_invincibility() -> void:
	_invincible = true
	_invincible_timer = 1.8
	_blink_timer = 0.0
