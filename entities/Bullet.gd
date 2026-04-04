class_name Bullet
extends Area2D

var speed: float = 900.0
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0
const MAX_LIFETIME := 2.0


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
	position += velocity * delta
	_lifetime += delta
	if _lifetime > MAX_LIFETIME or position.x > GameData.GAME_WIDTH + 50.0:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-10, -2.5, 20, 5), Color(0.0, 1.0, 1.0))
	draw_rect(Rect2(-8, -1.5, 16, 3), Color(0.7, 1.0, 1.0, 0.8))
