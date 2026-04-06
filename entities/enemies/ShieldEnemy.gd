class_name ShieldEnemy
extends BaseEnemy


func _ready() -> void:
	hp = 3
	max_hp = 3
	speed = 160.0
	damage = 1
	enemy_type = "shield"
	_color = Color(0.2, 0.5, 1.0)
	super._ready()


func _draw_shape() -> void:
	var r := _get_radius()
	# Inner body
	draw_circle(Vector2.ZERO, r * 0.55, Color(0.1, 0.3, 0.8))
	# Shield polygon — fewer sides as hp drops (6→4→2 sides)
	var sides := 2 + hp * 2  # hp=3→8, hp=2→6, hp=1→4
	sides = clampi(sides, 3, 8)
	var shield_pts := PackedVector2Array()
	for i in sides:
		var a := float(i) / float(sides) * TAU
		shield_pts.append(Vector2(cos(a), sin(a)) * r)
	var hp_frac := float(hp) / float(max_hp)
	draw_polyline(shield_pts, Color(0.3, 0.6, 1.0, 0.4 + hp_frac * 0.5), 2.5)
	draw_line(shield_pts[sides - 1], shield_pts[0], Color(0.3, 0.6, 1.0, 0.4 + hp_frac * 0.5), 2.5)


func _get_radius() -> float:
	return 20.0
