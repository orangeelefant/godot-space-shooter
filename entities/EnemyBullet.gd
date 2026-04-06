class_name EnemyBullet
extends Area2D

var _lifetime: float = 0.0
var _velocity: Vector2 = Vector2(-380.0, 0.0)
const MAX_LIFETIME := 3.5


func fire(vel: Vector2) -> void:
	_velocity = vel


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 4)
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func _process(delta: float) -> void:
	position += _velocity * delta
	_lifetime += delta
	if _lifetime > MAX_LIFETIME or position.x < -50.0:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-10, -4, 20, 8), Color(1.0, 0.3, 0.0, 0.2))  # glow
	draw_rect(Rect2(-9, -3, 18, 6), Color(1.0, 0.4, 0.0, 0.3))   # inner glow
	draw_rect(Rect2(-8, -2, 16, 4), Color(1.0, 0.4, 0.0))
	draw_rect(Rect2(-6, -1, 12, 2), Color(1.0, 0.8, 0.3, 0.8))
