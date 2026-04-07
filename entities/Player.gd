class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal damaged
signal died
signal shield_changed(active: bool)

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

var _shield_active: bool = false
var _shield_timer: float = 0.0
var _shield_pulse: float = 0.0
const SHIELD_DURATION := 8.0
const SHIELD_HITS := 3
var _shield_hits_left: int = 0
var _thruster_phase: float = 0.0


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

	if _shield_active:
		_shield_timer -= delta
		_shield_pulse += delta * 4.0
		if _shield_timer <= 0.0:
			_shield_active = false
			shield_changed.emit(false)
		queue_redraw()

	_thruster_phase += delta
	queue_redraw()


func _draw() -> void:
	var c := _color

	# Animated thruster flame
	var thrust_len: float = 12.0 + absf(velocity.x) * 0.025 + sin(_thruster_phase * 14.0) * 4.0
	draw_polygon(
		PackedVector2Array([Vector2(-18, -4), Vector2(-18 - thrust_len, 0), Vector2(-18, 4)]),
		PackedColorArray([Color(1.0, 0.55, 0.1, 0.85)])
	)
	draw_polygon(
		PackedVector2Array([Vector2(-16, -6), Vector2(-16 - thrust_len * 1.25, 0), Vector2(-16, 6)]),
		PackedColorArray([Color(0.3, 0.5, 1.0, 0.28)])
	)

	# Ship silhouette — arrow pointing right
	var body_pts := PackedVector2Array([
		Vector2(34, 0),
		Vector2(-20, -18),
		Vector2(-10, 0),
		Vector2(-20, 18),
	])
	# Ship glow
	var glow_pts := PackedVector2Array()
	for p in body_pts:
		glow_pts.append(p * 1.35)
	draw_polygon(glow_pts, [Color(0.3, 0.7, 1.0, 0.12)])
	var pts := body_pts
	draw_polygon(pts, PackedColorArray([c]))
	# Cockpit
	draw_circle(Vector2(12, 0), 6.0, Color(0.7, 0.9, 1.0, 0.8))

	# Shield arc
	if _shield_active:
		var r := 32.0 + sin(_shield_pulse) * 3.0
		var a := 0.4 + sin(_shield_pulse * 2.0) * 0.15
		var shield_color := Color(0.3, 0.8, 1.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(shield_color.r, shield_color.g, shield_color.b, a), 2.5)
		draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 40, Color(shield_color.r, shield_color.g, shield_color.b, a * 0.3), 1.0)


func activate_shield() -> void:
	_shield_active = true
	_shield_timer = SHIELD_DURATION
	_shield_hits_left = SHIELD_HITS
	_shield_pulse = 0.0
	shield_changed.emit(true)
	AudioSystem.play_shield_activate()


func take_damage(amount: int = 1) -> void:
	if _invincible or _frozen:
		return
	if _shield_active:
		_shield_hits_left -= amount
		AudioSystem.play_shield_hit()
		_shield_pulse = 0.0  # reset pulse for visual pop
		if _shield_hits_left <= 0:
			_shield_active = false
			shield_changed.emit(false)
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
