class_name EnemySpawner
extends Node

signal enemy_killed(enemy: BaseEnemy)
signal wave_started(index: int)
signal all_waves_done
signal boss_defeated
signal boss_spawned(boss: BossEnemy)

var _waves: Array = []
var _current_wave: int = 0
var _spawn_timer: float = 0.0
var _spawn_queue: Array[Dictionary] = []  # {type, pos}
var _wave_timer: float = 0.0
var _waiting_for_next_wave: bool = false
var _all_launched: bool = false

const SPAWN_X := 1970.0
const GAP_BETWEEN_WAVES := 3.0  # seconds after last spawn of a wave


func setup(waves: Array) -> void:
	_waves = waves
	_current_wave = 0
	_all_launched = false
	_launch_wave(0)


func _process(delta: float) -> void:
	# Drain spawn queue
	if not _spawn_queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var entry: Dictionary = _spawn_queue.pop_front()
			_do_spawn(entry.type, entry.pos, str(entry.get("boss_type", "standard")))
			_spawn_timer = entry.get("delay", 0.1)

	# Launch next wave after gap
	if _waiting_for_next_wave:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_waiting_for_next_wave = false
			_current_wave += 1
			if _current_wave < _waves.size():
				_launch_wave(_current_wave)
			else:
				_all_launched = true
				all_waves_done.emit()


func _launch_wave(index: int) -> void:
	var wave: Dictionary = _waves[index]
	wave_started.emit(index)
	var count: int = int(wave.get("count", 10))
	var delay: float = float(wave.get("delay", 0.15))
	var formation: String = wave.get("formation", "swarm")
	var etype: String = wave.get("type", "green")

	for i in count:
		var entry := {
			"type": etype,
			"pos": Vector2(SPAWN_X + i * 10.0, _formation_y(i, count, formation)),
			"delay": delay,
		}
		if etype == "boss":
			entry["boss_type"] = wave.get("boss_type", "standard")
		_spawn_queue.append(entry)

	# Schedule next wave after all spawns + gap
	var total_time := count * delay + GAP_BETWEEN_WAVES
	_wave_timer = total_time
	_waiting_for_next_wave = true


func _formation_y(index: int, total: int, formation: String) -> float:
	match formation:
		"line":
			return 120.0 + (float(index) / float(total)) * (GameData.GAME_HEIGHT - 240.0)
		"v":
			return GameData.GAME_HEIGHT / 2.0 + abs(index - total / 2) * 40.0
		_:  # swarm / random
			return randf_range(80.0, GameData.GAME_HEIGHT - 80.0)


func _do_spawn(etype: String, pos: Vector2, boss_type: String = "standard") -> void:
	var enemy: BaseEnemy
	match etype:
		"green":
			enemy = GreenEnemy.new()
		"yellow":
			enemy = YellowEnemy.new()
			(enemy as YellowEnemy).shoot_at.connect(_on_enemy_shoot)
		"red":
			enemy = RedEnemy.new()
			(enemy as RedEnemy).shoot_at.connect(_on_enemy_shoot)
		"invisible":
			enemy = InvisibleEnemy.new()
		"fly":
			enemy = FlyEnemy.new()
		"shield":
			enemy = ShieldEnemy.new()
		"zigzag":
			enemy = ZigZagEnemy.new()
		"boss":
			var boss: BossEnemy = MagnetBoss.new() if boss_type == "magnet" else BossEnemy.new()
			boss.shoot_at.connect(_on_enemy_shoot)
			boss.shoot_directed.connect(_on_enemy_shoot_directed)
			boss.spawn_minions.connect(_on_boss_spawn_minions)
			boss.health_changed.connect(_on_boss_health_changed)
			boss.position = pos
			boss.died.connect(_on_boss_died)
			get_parent().add_child(boss)
			boss_spawned.emit(boss)
			return
		_:
			enemy = GreenEnemy.new()

	enemy.position = pos
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)


func _on_enemy_died(enemy: BaseEnemy) -> void:
	enemy_killed.emit(enemy)
	AudioSystem.play_explosion()
	_maybe_drop_powerup(enemy.position)


func _on_enemy_shoot(pos: Vector2) -> void:
	var bullet := EnemyBullet.new()
	bullet.position = pos
	get_parent().add_child(bullet)


func _on_enemy_shoot_directed(pos: Vector2, vel: Vector2) -> void:
	var bullet := EnemyBullet.new()
	bullet.position = pos
	bullet.fire(vel)
	get_parent().add_child(bullet)


func _maybe_drop_powerup(pos: Vector2) -> void:
	if randf() > 0.15:
		return
	var types := ["life", "gas", "speed", "shield"]
	var pu := PowerUp.new()
	pu.power_type = types[randi() % types.size()]
	pu.position = pos
	get_parent().add_child(pu)


func _on_boss_died(_enemy: BaseEnemy) -> void:
	AudioSystem.play_boss_defeated()
	boss_defeated.emit()


func _on_boss_spawn_minions(pos: Vector2, count: int) -> void:
	for i in count:
		var entry := {
			"type": "green",
			"pos": pos + Vector2(randf_range(-80, 80), randf_range(-120, 120)),
			"delay": 0.12,
		}
		_spawn_queue.append(entry)


func _on_boss_health_changed(_current: int, _maximum: int) -> void:
	pass  # Game.gd connects directly to boss for HUD updates


func kill_all() -> void:
	for child in get_parent().get_children():
		if child is BossEnemy:
			child.hit(child.hp)  # trigger proper death chain so boss_defeated fires
		elif child is BaseEnemy:
			child.queue_free()
		elif child is EnemyBullet:
			child.queue_free()
