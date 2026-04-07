class_name ZigZagEnemy
extends BaseEnemy

var _time: float = 0.0
var _base_y: float = 0.0
var _base_y_set: bool = false
var _amplitude: float = 80.0
var _frequency: float = 2.5
var _arc_overlay: ColorRect


func _ready() -> void:
	hp = 1
	max_hp = 1
	speed = 280.0
	damage = 1
	enemy_type = "zigzag"
	_color = Color(1.0, 0.7, 0.0)
	super._ready()
	_build_arc_overlay()


func _build_arc_overlay() -> void:
	_arc_overlay = ColorRect.new()
	_arc_overlay.size = Vector2(44, 44)
	_arc_overlay.position = Vector2(-22, -22)
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/electric_arc.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("arc_color", Color(0.4, 0.7, 1.0, 0.9))
		mat.set_shader_parameter("speed", 5.0)
		mat.set_shader_parameter("intensity", 2.5)
		_arc_overlay.material = mat
	add_child(_arc_overlay)


func _process(delta: float) -> void:
	if not _base_y_set:
		_base_y = position.y
		_base_y_set = true
	_time += delta
	position.x -= speed * delta
	position.y = _base_y + sin(_time * _frequency) * _amplitude

	if _tint_timer > 0.0:
		_tint_timer -= delta
		modulate = Color.WHITE if _tint_timer <= 0.0 else Color(2.0, 2.0, 2.0)

	if position.x < -80.0:
		queue_free()
		return

	queue_redraw()


func _draw_shape() -> void:
	var r := _get_radius()
	# Arrow/chevron shape pointing left (direction of movement)
	var pts := PackedVector2Array([
		Vector2(-r, 0),
		Vector2(0, -r * 0.7),
		Vector2(r * 0.3, 0),
		Vector2(0, r * 0.7),
	])
	draw_polygon(pts, [Color(1.0, 0.7, 0.0)])
	draw_polyline(pts, Color(1.0, 1.0, 0.5, 0.8), 1.5)
	draw_line(pts[3], pts[0], Color(1.0, 1.0, 0.5, 0.8), 1.5)


func _get_radius() -> float:
	return 16.0
