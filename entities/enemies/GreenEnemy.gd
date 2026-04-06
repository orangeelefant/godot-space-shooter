class_name GreenEnemy
extends BaseEnemy


func _ready() -> void:
	hp = 1
	max_hp = 1
	speed = randf_range(180.0, 280.0)
	damage = 1
	enemy_type = "green"
	_color = Color(0.1, 0.9, 0.2)
	super._ready()


func _draw_shape() -> void:
	# Hexagon
	var r := _get_radius()
	draw_circle(Vector2.ZERO, r * 1.5, Color(_color.r, _color.g, _color.b, 0.12))  # outer glow
	draw_circle(Vector2.ZERO, r * 1.2, Color(_color.r, _color.g, _color.b, 0.2))   # inner glow
	var pts := PackedVector2Array()
	for i in 6:
		var angle := i * TAU / 6.0 - PI / 6.0
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	draw_polygon(pts, PackedColorArray([_color]))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.3, 1.0, 0.4, 0.6), 1.5)
