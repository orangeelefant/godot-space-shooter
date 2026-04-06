class_name ShieldEnemy
extends BaseEnemy

var _shield_hp: int = 2
const SHIELD_MAX := 2


func _ready() -> void:
	hp = 1
	max_hp = 1
	speed = 160.0
	damage = 1
	enemy_type = "shield"
	_color = Color(0.2, 0.5, 1.0)
	super._ready()


func hit(damage_amount: int = 1) -> void:
	if _shield_hp > 0:
		_shield_hp -= damage_amount
		_tint_timer = 0.08
		modulate = Color(2.0, 2.0, 2.0)
		queue_redraw()
	else:
		super.hit(damage_amount)


func _draw_shape() -> void:
	var r := _get_radius()
	draw_circle(Vector2.ZERO, r * 0.55, Color(0.1, 0.3, 0.8))
	if _shield_hp <= 0:
		return
	# Shield polygon — fewer sides as shield degrades (2→8, 1→6, 0→gone)
	var sides := 4 + _shield_hp * 2  # 2→8, 1→6
	var shield_pts := PackedVector2Array()
	for i in sides:
		var a := float(i) / float(sides) * TAU
		shield_pts.append(Vector2(cos(a), sin(a)) * r)
	var frac := float(_shield_hp) / float(SHIELD_MAX)
	draw_polyline(shield_pts, Color(0.3, 0.6, 1.0, 0.4 + frac * 0.5), 2.5)
	draw_line(shield_pts[sides - 1], shield_pts[0], Color(0.3, 0.6, 1.0, 0.4 + frac * 0.5), 2.5)


func _get_radius() -> float:
	return 20.0
