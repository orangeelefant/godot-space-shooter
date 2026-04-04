class_name RedEnemy
extends BaseEnemy

signal shoot_at(pos: Vector2)

var _shoot_timer: float = 0.0
var _shoot_interval: float = 1.8
var _wave_offset: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	hp = 3
	max_hp = 3
	speed = randf_range(200.0, 320.0)
	damage = 2
	enemy_type = "red"
	_color = Color(1.0, 0.15, 0.15)
	super._ready()
	_shoot_timer = randf_range(0.5, _shoot_interval)
	_wave_offset = randf() * TAU
	_base_y = position.y


func _process(delta: float) -> void:
	_wave_offset += delta * 3.0
	position.y = _base_y + sin(_wave_offset) * 40.0
	position.x -= speed * delta

	if _tint_timer > 0.0:
		_tint_timer -= delta
		modulate = Color.WHITE if _tint_timer <= 0.0 else Color(2.0, 2.0, 2.0)

	if position.x < -80.0:
		queue_free()

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = _shoot_interval
		shoot_at.emit(position)


func _get_radius() -> float:
	return 22.0


func _draw_shape() -> void:
	var r := _get_radius()
	# Spiky shape — star-like
	var pts := PackedVector2Array()
	for i in 8:
		var angle := i * TAU / 8.0
		var radius := r if i % 2 == 0 else r * 0.5
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_polygon(pts, PackedColorArray([_color]))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.5, 0.5, 0.8), 1.5)
