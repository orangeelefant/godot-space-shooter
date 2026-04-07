class_name InvisibleEnemy
extends BaseEnemy

var _player_pos: Vector2 = Vector2(200, 540)
var _cached_player: Player = null
var _visible_timer: float = 0.0
var _is_visible: bool = false
const VISIBLE_INTERVAL := 3.0
const VISIBLE_DURATION := 0.5

var _shimmer: _ShimmerNode
var _glitch_overlay: ColorRect


func _ready() -> void:
	hp = 2
	max_hp = 2
	speed = randf_range(150.0, 220.0)
	damage = 1
	enemy_type = "invisible"
	_color = Color(0.4, 0.6, 1.0, 0.15)
	super._ready()
	self_modulate.a = 0.1
	_visible_timer = randf_range(1.0, VISIBLE_INTERVAL)
	_shimmer = _ShimmerNode.new()
	_shimmer.owner_enemy = self
	add_child(_shimmer)
	_build_glitch_overlay()
	# Cache player reference once — avoids O(n) get_children() scan every frame
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is Player:
				_player_pos = (child as Player).position
				_cached_player = child as Player
				break


func _process(delta: float) -> void:
	# Update cached player position — O(1) field read instead of O(n) scan
	if _cached_player and is_instance_valid(_cached_player):
		_player_pos = _cached_player.position

	# Homing
	var dir := (_player_pos - position).normalized()
	position += dir * speed * delta

	_visible_timer -= delta
	if not _is_visible and _visible_timer <= 0.0:
		_is_visible = true
		_visible_timer = VISIBLE_DURATION
		self_modulate.a = 0.7
		queue_redraw()
		_trigger_glitch()
	elif _is_visible and _visible_timer <= 0.0:
		_is_visible = false
		_visible_timer = VISIBLE_INTERVAL
		self_modulate.a = 0.1
		queue_redraw()
		_trigger_glitch()

	if _tint_timer > 0.0:
		_tint_timer -= delta
		if _tint_timer <= 0.0:
			self_modulate = Color(1, 1, 1, 0.1 if not _is_visible else 0.7)
		else:
			self_modulate = Color(2.0, 2.0, 2.0, 1.0)

	if position.x < -80.0 or position.x > GameData.GAME_WIDTH + 80.0:
		queue_free()

	_shimmer.queue_redraw()


func _build_glitch_overlay() -> void:
	_glitch_overlay = ColorRect.new()
	_glitch_overlay.size = Vector2(40, 40)
	_glitch_overlay.position = Vector2(-20, -20)
	_glitch_overlay.visible = false
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/glitch.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("shake_power", 0.06)
		mat.set_shader_parameter("shake_rate", 0.6)
		mat.set_shader_parameter("shake_speed", 12.0)
		_glitch_overlay.material = mat
	add_child(_glitch_overlay)


func _trigger_glitch() -> void:
	if _glitch_overlay and is_instance_valid(_glitch_overlay):
		_glitch_overlay.visible = true
		get_tree().create_timer(0.18).timeout.connect(
			func(): if is_instance_valid(_glitch_overlay): _glitch_overlay.visible = false,
			CONNECT_ONE_SHOT
		)


func set_player_position(pos: Vector2) -> void:
	_player_pos = pos


func _get_radius() -> float:
	return 18.0


func _draw_shape() -> void:
	draw_circle(Vector2.ZERO, _get_radius(), Color(0.4, 0.6, 1.0, 0.8))
	draw_arc(Vector2.ZERO, _get_radius() + 4, 0, TAU, 32, Color(0.6, 0.8, 1.0, 0.5), 1.5)


# Drawn on a child node so it's unaffected by parent self_modulate
class _ShimmerNode extends Node2D:
	var owner_enemy: InvisibleEnemy = null

	func _draw() -> void:
		if not owner_enemy or not is_instance_valid(owner_enemy):
			return
		var dist := owner_enemy.position.distance_to(owner_enemy._player_pos)
		var alpha := 0.08 if dist >= 120.0 else 0.35 * (1.0 - dist / 120.0)
		var r := owner_enemy._get_radius()
		draw_arc(Vector2.ZERO, r + 8, 0, TAU, 24, Color(0.0, 0.9, 1.0, alpha), 2.0)
		draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 12, Color(0.0, 0.7, 1.0, alpha * 0.5), 1.0)
