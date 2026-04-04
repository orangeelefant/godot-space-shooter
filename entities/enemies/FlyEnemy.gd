class_name FlyEnemy
extends BaseEnemy

signal freeze_player

var _wave_offset: float = 0.0
var _base_y: float = 0.0
var _has_frozen: bool = false


func _ready() -> void:
	hp = 1
	max_hp = 1
	speed = randf_range(300.0, 450.0)
	damage = 0
	enemy_type = "fly"
	_color = Color(0.3, 0.8, 1.0)
	super._ready()
	_wave_offset = randf() * TAU
	_base_y = position.y


func _process(delta: float) -> void:
	_wave_offset += delta * 5.0
	position.y = _base_y + sin(_wave_offset) * 30.0
	position.x -= speed * delta

	if _tint_timer > 0.0:
		_tint_timer -= delta
		modulate = Color.WHITE if _tint_timer <= 0.0 else Color(2.0, 2.0, 2.0)

	if position.x < -80.0:
		queue_free()


func _get_radius() -> float:
	return 14.0


func _draw_shape() -> void:
	var r := _get_radius()
	# Wing shape — two ovals + body
	draw_ellipse_approx(Vector2(-2, -r * 0.6), Vector2(r * 0.8, r * 0.5), _color.lightened(0.2))
	draw_ellipse_approx(Vector2(-2,  r * 0.6), Vector2(r * 0.8, r * 0.5), _color.lightened(0.2))
	draw_circle(Vector2.ZERO, r * 0.5, _color)


func draw_ellipse_approx(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polygon(pts, PackedColorArray([color]))
