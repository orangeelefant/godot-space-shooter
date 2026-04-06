class_name Bullet
extends Area2D

var speed: float = 900.0
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0
const MAX_LIFETIME := 2.0

var _trail: Array[Vector2] = []


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2  # hits enemies

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 5)
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func fire(from: Vector2, vel: Vector2) -> void:
	position = from
	velocity = vel
	_lifetime = 0.0


func _process(delta: float) -> void:
	_trail.push_front(position)
	if _trail.size() > 6:
		_trail.pop_back()
	position += velocity * delta
	_lifetime += delta
	if _lifetime > MAX_LIFETIME or position.x > GameData.GAME_WIDTH + 50.0:
		queue_free()


func _draw() -> void:
	for i in _trail.size():
		if i == 0:
			continue
		var alpha := 0.5 * (1.0 - float(i) / float(_trail.size()))
		var local_pos := to_local(_trail[i])
		draw_rect(Rect2(local_pos.x - 4, local_pos.y - 1.5, 8, 3), Color(0.3, 0.8, 1.0, alpha))
	# Outer glow
	draw_rect(Rect2(-12, -5, 24, 10), Color(0.2, 0.8, 1.0, 0.15))
	draw_rect(Rect2(-10, -4, 20, 8), Color(0.4, 0.9, 1.0, 0.25))
	# Original body + bright core
	draw_rect(Rect2(-10, -2.5, 20, 5), Color(0.0, 1.0, 1.0))
	draw_rect(Rect2(-8, -2, 16, 4), Color(0.5, 1.0, 1.0))   # bright cyan tip
	draw_rect(Rect2(-6, -1.5, 12, 3), Color(1.0, 1.0, 1.0, 0.9))  # white core
