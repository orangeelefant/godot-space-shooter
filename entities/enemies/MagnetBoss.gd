class_name MagnetBoss
extends BossEnemy

var _pull_active: bool = false
var _pull_timer: float = 0.0
var _inner_rot: float = 0.0


func _ready() -> void:
	super._ready()
	_color = Color(0.6, 0.0, 1.0)
	hp = 50
	max_hp = 50


func _process(delta: float) -> void:
	_inner_rot += delta * 2.5
	if _pull_active:
		_pull_timer -= delta
		if _pull_timer <= 0.0:
			_pull_active = false
	super._process(delta)


func _execute_phase() -> void:
	match _phase:
		0:  # Magnetic pull — attract player toward boss
			_pull_active = true
			_pull_timer = 2.5
			AudioSystem.play_boss_hit()
		1:  # Spawn minions
			spawn_minions.emit(position + Vector2(-50, 0), 5)
		2:  # Burst fire — 3-shot spread
			for i in 3:
				var angle := deg_to_rad(-25.0 + i * 25.0)
				var vel := Vector2(cos(angle + PI), sin(angle + PI)) * 400.0
				shoot_directed.emit(position, vel)
			AudioSystem.play_boss_hit()


func _draw_shape() -> void:
	var r := _get_radius()

	# Outer rotating triangle segments
	for i in 6:
		var a := _rotation_angle + i * (TAU / 6.0)
		var a2 := a + TAU / 12.0
		var p1 := Vector2(cos(a), sin(a)) * (r + 14.0)
		var p2 := Vector2(cos(a2), sin(a2)) * (r + 20.0)
		var p3 := Vector2(cos(a + TAU / 6.0), sin(a + TAU / 6.0)) * (r + 14.0)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]),
			Color(0.7, 0.0, 1.0, 0.6))

	# Concentric spinning rings
	for i in 3:
		var ring_r := float(i + 1) * r / 3.5
		var arc_start := _inner_rot + float(i) * 0.8
		draw_arc(Vector2.ZERO, ring_r, arc_start, arc_start + TAU * 0.7, 32,
			Color(0.6, 0.0, 1.0, 0.3 + float(i) * 0.1), 2.5)

	# Hexagon body
	var pts := PackedVector2Array()
	for i in 6:
		var a := float(i) / 6.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.18, 0.0, 0.28))
	draw_polyline(pts, Color(0.8, 0.1, 1.0), 2.0)
	draw_line(pts[5], pts[0], Color(0.8, 0.1, 1.0), 2.0)

	# Core
	var core_r := 20.0 + sin(_pulse) * 4.0
	draw_circle(Vector2.ZERO, core_r, Color(0.65, 0.0, 1.0, 0.9))
	draw_circle(Vector2.ZERO, core_r * 0.55, Color(1.0, 0.6, 1.0, 0.85))

	# HP ring
	var hp_frac := float(hp) / float(max_hp)
	if hp_frac > 0.0:
		draw_arc(Vector2.ZERO, r + 6.0, -PI / 2.0, -PI / 2.0 + TAU * hp_frac, 48,
			Color(0.7 + hp_frac * 0.1, 0.0, 1.0, 0.9), 4.0)

	# Magnetic field lines when pull is active
	if _pull_active:
		var field_alpha := 0.18 + sin(_pulse * 2.5) * 0.1
		for i in 8:
			var a := float(i) / 8.0 * TAU + _rotation_angle * 1.5
			draw_line(
				Vector2(cos(a), sin(a)) * r,
				Vector2(cos(a), sin(a)) * (r + 38.0),
				Color(0.8, 0.2, 1.0, field_alpha * 2.2), 2.0
			)


func _get_radius() -> float:
	return 50.0


func is_pulling() -> bool:
	return _pull_active
