class_name PowerUp
extends Area2D

signal collected(type: String)

var power_type: String = "life"
var _bob_timer: float = 0.0
var _lifetime: float = 0.0
const MAX_LIFETIME := 8.0
const BOB_SPEED := 2.5
const BOB_AMOUNT := 8.0
const MOVE_SPEED := -70.0

const COLORS := {
	"life":   Color(1.0, 0.27, 0.4),
	"gas":    Color(1.0, 0.53, 0.0),
	"speed":  Color(0.0, 0.8,  1.0),
	"shield": Color(0.27, 1.0, 0.53),
}

const LABELS := {
	"life": "+", "gas": "G", "speed": ">", "shield": "S",
}

var _base_y: float = 0.0
var _color: Color = Color.WHITE


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0

	_color = COLORS.get(power_type, Color.WHITE)
	_base_y = position.y

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func _process(delta: float) -> void:
	_bob_timer += delta * BOB_SPEED
	_lifetime += delta
	position.x += MOVE_SPEED * delta
	position.y = _base_y + sin(_bob_timer) * BOB_AMOUNT

	var fade := 1.0
	if _lifetime > MAX_LIFETIME - 1.5:
		fade = (MAX_LIFETIME - _lifetime) / 1.5
	modulate.a = clampf(fade, 0.0, 1.0)

	if _lifetime >= MAX_LIFETIME or position.x < -40.0:
		queue_free()


func _draw() -> void:
	# Ring
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 32, _color.darkened(0.3), 3.0)
	# Fill circle
	draw_circle(Vector2.ZERO, 10.0, _color)
	# Inner glow
	draw_circle(Vector2.ZERO, 6.0, _color.lightened(0.5))


func collect() -> void:
	AudioSystem.play_powerup()
	collected.emit(power_type)
	queue_free()
