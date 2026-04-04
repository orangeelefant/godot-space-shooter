class_name BaseEnemy
extends Area2D

signal died(enemy: BaseEnemy)

var hp: int = 1
var max_hp: int = 1
var speed: float = 200.0
var damage: int = 1
var enemy_type: String = "green"
var _color: Color = Color.GREEN

var _shape: CollisionShape2D
var _tint_timer: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true

	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _get_radius()
	_shape.shape = circle
	add_child(_shape)

	queue_redraw()


func _process(delta: float) -> void:
	position.x -= speed * delta

	if _tint_timer > 0.0:
		_tint_timer -= delta
		modulate = Color.WHITE if _tint_timer <= 0.0 else Color(2.0, 2.0, 2.0)

	# Despawn when off-screen left
	if position.x < -80.0:
		queue_free()


func _draw() -> void:
	_draw_shape()


func hit(damage_amount: int = 1) -> void:
	hp -= damage_amount
	_tint_timer = 0.08
	modulate = Color(2.0, 2.0, 2.0)
	if hp <= 0:
		_die()


func get_damage() -> int:
	return damage


func _die() -> void:
	_spawn_explosion()
	died.emit(self)
	queue_free()


func _spawn_explosion() -> void:
	# Visual burst — spawn a few fading circles via a short-lived node
	var burst := _ExplosionBurst.new()
	burst.position = position
	burst.color = _color
	get_parent().add_child(burst)


func _get_radius() -> float:
	return 18.0


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, _get_radius(), _color)


# ── Inner helper node ────────────────────────────────────────────────────────

class _ExplosionBurst extends Node2D:
	var color: Color = Color.ORANGE
	var _particles: Array[Dictionary] = []
	var _elapsed: float = 0.0
	const DURATION := 0.4

	func _ready() -> void:
		z_index = 10
		for i in 10:
			_particles.append({
				"vel": Vector2.from_angle(randf() * TAU) * randf_range(40.0, 180.0),
				"pos": Vector2.ZERO,
				"size": randf_range(3.0, 8.0),
			})
		queue_redraw()

	func _process(delta: float) -> void:
		_elapsed += delta
		for p in _particles:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.92
		queue_redraw()
		if _elapsed >= DURATION:
			queue_free()

	func _draw() -> void:
		var alpha := 1.0 - (_elapsed / DURATION)
		for p in _particles:
			var c := Color(color.r, color.g, color.b, alpha)
			draw_circle(p["pos"], p["size"] * alpha, c)
