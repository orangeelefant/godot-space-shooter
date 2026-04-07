class_name BossEnemy
extends BaseEnemy

signal shoot_at(pos: Vector2)
signal shoot_directed(pos: Vector2, vel: Vector2)
signal spawn_minions(pos: Vector2, count: int)
signal health_changed(current_hp: int, max_hp_val: int)

const TARGET_X := 1500.0
const PHASE_DURATION := 3.5

var _phase: int = 0       # 0 = burst, 1 = minions, 2 = sweep
var _phase_timer: float = PHASE_DURATION
var _rotation_angle: float = 0.0
var _sweep_angle: float = 0.0
var _sweep_active: bool = false
var _pulse: float = 0.0
var _arrived: bool = false


func _ready() -> void:
	hp = 50
	max_hp = 50
	speed = 120.0
	damage = 2
	enemy_type = "boss"
	_color = Color(1.0, 0.2, 0.3)
	super._ready()
	z_index = 8


func _process(delta: float) -> void:
	_rotation_angle += delta * 1.2
	_pulse += delta * 3.0
	queue_redraw()

	# Move to target X then stop
	if not _arrived:
		position.x -= speed * delta
		if position.x <= TARGET_X:
			position.x = TARGET_X
			speed = 0.0
			_arrived = true
	else:
		# Gentle vertical drift
		position.y += sin(_rotation_angle * 0.7) * 0.6
		if _sweep_active:
			_sweep_angle -= delta * 1.5

	if _tint_timer > 0.0:
		_tint_timer -= delta
		modulate = Color.WHITE if _tint_timer <= 0.0 else Color(2.0, 2.0, 2.0)

	if not _arrived:
		return

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase_timer = PHASE_DURATION
		_phase = (_phase + 1) % 3
		_execute_phase()


func _execute_phase() -> void:
	match _phase:
		0:  # Burst fire — 5-shot fan spread
			for i in 5:
				var angle := deg_to_rad(-40.0 + i * 20.0)
				var vel := Vector2(cos(angle + PI), sin(angle + PI)) * 420.0
				shoot_directed.emit(position, vel)
			AudioSystem.play_boss_hit()
		1:  # Spawn minions
			spawn_minions.emit(position + Vector2(-50, 0), 4)
		2:  # Sweep beam — flag active for a short window
			_sweep_active = true
			_sweep_angle = PI * 0.0
			get_tree().create_timer(2.0).timeout.connect(func(): _sweep_active = false)


func _draw_shape() -> void:
	var r := _get_radius()

	# Outer rotating ring segments
	for i in 8:
		var a := _rotation_angle + i * (TAU / 8.0)
		var a2 := a + TAU / 16.0
		var p1 := Vector2(cos(a), sin(a)) * (r + 12.0)
		var p2 := Vector2(cos(a2), sin(a2)) * (r + 18.0)
		var p3 := Vector2(cos(a + TAU / 8.0), sin(a + TAU / 8.0)) * (r + 12.0)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]),
			Color(1.0, 0.5, 0.1, 0.7))

	# Body — octagon
	var pts := PackedVector2Array()
	for i in 8:
		var a := float(i) / 8.0 * TAU - PI / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.35, 0.0, 0.1))
	draw_polyline(pts, Color(1.0, 0.2, 0.3), 2.0)
	# close the polyline
	draw_line(pts[7], pts[0], Color(1.0, 0.2, 0.3), 2.0)

	# Inner core — pulsing
	var core_r := 22.0 + sin(_pulse) * 4.0
	# Additional outer glow pulse
	var outer_glow_r := core_r * 2.0 + sin(_pulse * 0.7) * 6.0
	draw_circle(Vector2.ZERO, outer_glow_r, Color(1.0, 0.1, 0.2, 0.06))
	draw_circle(Vector2.ZERO, core_r * 1.4, Color(1.0, 0.2, 0.0, 0.15))
	draw_circle(Vector2.ZERO, core_r, Color(1.0, 0.1, 0.2, 0.9))
	draw_circle(Vector2.ZERO, core_r * 0.6, Color(1.0, 0.6, 0.0, 0.8))

	# HP fill ring
	var hp_frac := float(hp) / float(max_hp)
	if hp_frac > 0.0:
		draw_arc(Vector2.ZERO, r + 6.0, -PI / 2.0, -PI / 2.0 + TAU * hp_frac, 48,
			Color(1.0, 0.2 + hp_frac * 0.6, 0.0, 0.9), 4.0)

	# Sweep beam visual
	if _sweep_active:
		var beam_end := Vector2(cos(_sweep_angle), sin(_sweep_angle)) * 600.0
		draw_line(Vector2.ZERO, beam_end, Color(1.0, 0.3, 0.0, 0.6), 6.0)
		draw_line(Vector2.ZERO, beam_end, Color(1.0, 0.8, 0.0, 0.3), 12.0)


func _get_radius() -> float:
	return 55.0


func _die() -> void:
	# Large explosion burst
	for i in 3:
		var burst := _ExplosionBurst.new()
		burst.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		burst.color = Color(1.0, 0.4, 0.1)
		get_parent().add_child(burst)
	died.emit(self)
	queue_free()


func hit(damage_amount: int = 1) -> void:
	super.hit(damage_amount)
	health_changed.emit(hp, max_hp)


func is_sweep_active() -> bool:
	return _sweep_active


func get_sweep_end() -> Vector2:
	return position + Vector2(cos(_sweep_angle), sin(_sweep_angle)) * 600.0


# ── Boss health bar (top of screen) ─────────────────────────────────────────

class _BossHealthBar extends Node2D:
	var boss_ref: BossEnemy = null
	const BAR_W := 600.0
	const BAR_H := 14.0

	func _ready() -> void:
		z_index = 20
		position = Vector2(GameData.GAME_WIDTH / 2.0 - BAR_W / 2.0, 8)

	func _process(_delta: float) -> void:
		if not boss_ref or not is_instance_valid(boss_ref):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if not boss_ref or not is_instance_valid(boss_ref):
			return
		var frac := float(boss_ref.hp) / float(boss_ref.max_hp)
		draw_rect(Rect2(0, 0, BAR_W, BAR_H), Color(0.1, 0.0, 0.05))
		var bar_color := Color(1.0, 0.2 + frac * 0.6, 0.0)
		draw_rect(Rect2(0, 0, BAR_W * frac, BAR_H), bar_color)
		draw_rect(Rect2(0, 0, BAR_W, BAR_H), Color(1.0, 0.2, 0.3, 0.7), false, 1.5)


static func create_health_bar(boss: BossEnemy) -> _BossHealthBar:
	var bar := _BossHealthBar.new()
	bar.boss_ref = boss
	return bar
