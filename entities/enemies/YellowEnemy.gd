class_name YellowEnemy
extends BaseEnemy

signal shoot_at(pos: Vector2)

var _shoot_timer: float = 0.0
var _shoot_interval: float = 2.5


func _ready() -> void:
	hp = 2
	max_hp = 2
	speed = randf_range(100.0, 160.0)
	damage = 1
	enemy_type = "yellow"
	_color = Color(1.0, 0.85, 0.0)
	super._ready()
	_shoot_timer = randf_range(1.0, _shoot_interval)


func _process(delta: float) -> void:
	super._process(delta)
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = _shoot_interval
		shoot_at.emit(position)


func _get_radius() -> float:
	return 20.0


func _draw_shape() -> void:
	# Diamond
	var r := _get_radius()
	var pts := PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.7, 0),
		Vector2(0, r),  Vector2(-r * 0.7, 0),
	])
	draw_polygon(pts, PackedColorArray([_color]))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 1.0, 0.4, 0.7), 2.0)
	# Eye
	draw_circle(Vector2(-4, 0), 4.0, Color(0.1, 0.1, 0.1))
