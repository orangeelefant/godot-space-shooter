class_name Falcon
extends Node2D

signal falcon_shoot(pos: Vector2)

var _level: int = 1
var _shoot_timer: float = 0.0
var _shoot_interval: float = 1.2
var _wing_phase: float = 0.0
var _trail: Array[Vector2] = []
var _player_ref: Node2D = null


func setup(level: int, player: Node2D) -> void:
	_level = level
	_player_ref = player
	_shoot_interval = 1.2 / float(level)
	z_index = 9


func _process(delta: float) -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		return

	var target := _player_ref.position + Vector2(-45, -28)
	position = position.lerp(target, 4.5 * delta)

	_trail.push_front(position)
	if _trail.size() > 8:
		_trail.pop_back()

	_wing_phase += delta * 6.0
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = _shoot_interval
		falcon_shoot.emit(position + Vector2(18, 0))

	queue_redraw()


func _draw() -> void:
	# Trail dots
	for i in _trail.size():
		var alpha := 0.35 * (1.0 - float(i) / float(_trail.size()))
		var local_pos := to_local(_trail[i])
		draw_circle(local_pos, 2.0, Color(0.27, 0.8, 1.0, alpha))

	# Body — small arrowhead pointing right
	var pts := PackedVector2Array([
		Vector2(14, 0),
		Vector2(-8, -7),
		Vector2(-4, 0),
		Vector2(-8, 7),
	])
	draw_polygon(pts, [Color(0.53, 0.8, 1.0)])
	draw_polyline(pts, Color(0, 1, 1, 0.8), 1.0)

	# Blinking wing lights
	var blink: float = absf(sin(_wing_phase))
	draw_circle(Vector2(-6, -7), 2.5, Color(0, 1, 0.53, blink))
	draw_circle(Vector2(-6, 7), 2.5, Color(0, 1, 0.53, blink))

	# Thruster glow
	var thrust_len: float = 6.0 + sin(_wing_phase * 3.0) * 2.0
	draw_polygon(
		PackedVector2Array([Vector2(-8, -3), Vector2(-8 - thrust_len, 0), Vector2(-8, 3)]),
		[Color(0.3, 0.6, 1.0, 0.7)]
	)
