class_name InvisibleEnemy
extends BaseEnemy

var _player_pos: Vector2 = Vector2(200, 540)
var _visible_timer: float = 0.0
var _is_visible: bool = false
const VISIBLE_INTERVAL := 3.0
const VISIBLE_DURATION := 0.5


func _ready() -> void:
	hp = 2
	max_hp = 2
	speed = randf_range(150.0, 220.0)
	damage = 1
	enemy_type = "invisible"
	_color = Color(0.4, 0.6, 1.0, 0.15)
	super._ready()
	modulate.a = 0.1
	_visible_timer = randf_range(1.0, VISIBLE_INTERVAL)


func _process(delta: float) -> void:
	# Homing
	var dir := (_player_pos - position).normalized()
	position += dir * speed * delta

	_visible_timer -= delta
	if not _is_visible and _visible_timer <= 0.0:
		_is_visible = true
		_visible_timer = VISIBLE_DURATION
		modulate.a = 0.7
		queue_redraw()
	elif _is_visible and _visible_timer <= 0.0:
		_is_visible = false
		_visible_timer = VISIBLE_INTERVAL
		modulate.a = 0.1
		queue_redraw()

	if _tint_timer > 0.0:
		_tint_timer -= delta
		if _tint_timer <= 0.0:
			modulate = Color(1, 1, 1, 0.1 if not _is_visible else 0.7)
		else:
			modulate = Color(2.0, 2.0, 2.0, 1.0)

	if position.x < -80.0 or position.x > GameData.GAME_WIDTH + 80.0:
		queue_free()


func set_player_position(pos: Vector2) -> void:
	_player_pos = pos


func _get_radius() -> float:
	return 18.0


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, _get_radius(), Color(0.4, 0.6, 1.0, 0.8))
	draw_arc(Vector2.ZERO, _get_radius() + 4, 0, TAU, 32, Color(0.6, 0.8, 1.0, 0.5), 1.5)
	# Proximity shimmer — always drawn, reveals enemy when player is close
	var dist := position.distance_to(_player_pos)
	var shimmer_alpha := 0.08 if dist >= 120.0 else 0.35 * (1.0 - dist / 120.0)
	draw_arc(Vector2.ZERO, _get_radius() + 8, 0, TAU, 24, Color(0.0, 0.9, 1.0, shimmer_alpha), 2.0)
	draw_arc(Vector2.ZERO, _get_radius() * 0.55, 0, TAU, 12, Color(0.0, 0.7, 1.0, shimmer_alpha * 0.5), 1.0)
