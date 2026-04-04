extends Node2D

var _world_id: String = "world-1"
var _level_id: String = "w1-l1"
var _level_config: Dictionary = {}

var _player: Player
var _spawner: EnemySpawner
var _hud: CanvasLayer

var _score: int = 0
var _gas_count: int = 3
var _total_enemies: int = 0
var _enemies_killed: int = 0
var _level_done: bool = false

var _shoot_cooldown: float = 0.0
const SHOOT_RATE := 0.18  # seconds between shots

# Parallax
var _stars_far: Node2D
var _stars_near: Node2D
var _far_offset: float = 0.0
var _near_offset: float = 0.0

# Mission timer
var _mission_timer_active: bool = false
var _mission_time_left: float = 0.0
var _timer_tick: float = 0.0


func _ready() -> void:
	_world_id = GameState.current_world_id
	_level_id = GameState.current_level_id
	_level_config = GameData.get_level(_world_id, _level_id)
	_load_save()
	_build_background()
	_build_player()
	_build_hud()
	_build_spawner()
	_wire_collisions()
	_start_mission_timer()


func setup(world_id: String, level_id: String) -> void:
	_world_id = world_id
	_level_id = level_id


func _load_save() -> void:
	var state := SaveSystem.load_game()
	_gas_count = int(state.get("gas_grenades", 3))


func _build_background() -> void:
	# Far parallax layer
	_stars_far = _StarLayer.new(80, 0.5, 1.5, Color(0.27, 0.53, 0.8), 0.15, 0.5)
	_stars_far.z_index = 0
	add_child(_stars_far)

	# Near parallax layer
	_stars_near = _StarLayer.new(40, 1.5, 3.0, Color(1, 1, 1), 0.5, 1.0)
	_stars_near.z_index = 1
	add_child(_stars_near)


func _build_player() -> void:
	var state := SaveSystem.load_game()
	var ship := GameData.get_ship(state.get("ship_id", "ruben"))
	var upgrades: Dictionary = state.get("upgrades", {})

	_player = Player.new()
	_player.setup(ship, upgrades)
	_player.position = Vector2(200, GameData.GAME_HEIGHT / 2.0)
	_player.z_index = 10
	_player.lives_changed.connect(_on_lives_changed)
	_player.damaged.connect(_on_player_damaged)
	_player.died.connect(_on_player_died)
	add_child(_player)


func _build_hud() -> void:
	var hud_scene := load("res://scenes/HUD.tscn")
	_hud = hud_scene.instantiate()
	add_child(_hud)
	_update_hud_initial()


func _update_hud_initial() -> void:
	var hud := _hud as Node
	hud.call("update_lives", _player.lives)
	hud.call("update_gas", _gas_count)
	hud.call("update_score", 0)
	var mission_name: String = _level_config.get("name", "")
	hud.call("update_mission", mission_name.to_upper())


func _build_spawner() -> void:
	_spawner = EnemySpawner.new()
	add_child(_spawner)

	var waves: Array = _level_config.get("waves", [])
	_total_enemies = 0
	for w in waves:
		_total_enemies += int(w.get("count", 0))

	_spawner.enemy_killed.connect(_on_enemy_killed)
	_spawner.all_waves_done.connect(_on_all_waves_launched)
	_spawner.setup(waves)


func _wire_collisions() -> void:
	# We use Area2D overlap check manually via groups or direct area_entered signals
	# Player vs enemies + enemy bullets: checked via area_entered on player's area or overlap query
	# We'll use a periodic overlap check approach for simplicity
	pass


func _process(delta: float) -> void:
	# Parallax
	_far_offset += 0.15 * delta * 60.0
	_near_offset += 0.5 * delta * 60.0
	if _stars_far.has_method("scroll_to"):
		_stars_far.call("scroll_to", _far_offset)
		_stars_near.call("scroll_to", _near_offset)

	# Shooting
	_shoot_cooldown -= delta
	if _player.is_shoot_pressed() and _shoot_cooldown <= 0.0:
		_fire_bullet()
		_shoot_cooldown = SHOOT_RATE

	# Gas grenade
	if _player.is_gas_pressed() and _gas_count > 0:
		_use_gas()

	# Collision checks (manual overlap)
	_check_bullet_enemy_overlap()
	_check_player_enemy_overlap()
	_check_player_enemy_bullets()
	_check_player_powerups()

	# Mission timer
	if _mission_timer_active:
		_mission_time_left -= delta
		_timer_tick += delta
		if _timer_tick >= 1.0:
			_timer_tick -= 1.0
			var secs := maxi(0, int(_mission_time_left))
			_hud.call("update_timer", secs)
			if secs <= 0:
				_mission_timer_active = false
				_hud.call("update_timer", 0)
				if not _level_done:
					_force_level_complete()


func _fire_bullet() -> void:
	AudioSystem.play_shoot()
	var muzzle := _player.get_muzzle_pos()
	var state := SaveSystem.load_game()
	var upgrades: Dictionary = state.get("upgrades", {})
	var cannon: String = upgrades.get("cannon_level", "enkel")

	match cannon:
		"enkel":
			_spawn_bullet(muzzle, Vector2(900, 0))
		"dubbel":
			_spawn_bullet(muzzle + Vector2(0, -10), Vector2(900, 0))
			_spawn_bullet(muzzle + Vector2(0,  10), Vector2(900, 0))
		"spread":
			_spawn_bullet(muzzle, Vector2(900, 0))
			_spawn_bullet(muzzle, Vector2(860, -80))
			_spawn_bullet(muzzle, Vector2(860,  80))
		"laser":
			var b := _spawn_bullet(muzzle, Vector2(1400, 0))
			b.damage = 3
		_:
			_spawn_bullet(muzzle, Vector2(900, 0))


func _spawn_bullet(pos: Vector2, vel: Vector2) -> Bullet:
	var bullet := Bullet.new()
	bullet.fire(pos, vel)
	bullet.z_index = 5
	add_child(bullet)
	return bullet


func _use_gas() -> void:
	_gas_count -= 1
	_hud.call("update_gas", _gas_count)
	var state := SaveSystem.load_game()
	state["gas_grenades"] = _gas_count
	SaveSystem.save_game(state)
	_spawner.kill_all()
	# Screen flash
	var flash := ColorRect.new()
	flash.color = Color(0, 0.4, 1.0, 0.35)
	flash.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	flash.z_index = 20
	add_child(flash)
	get_tree().create_timer(0.3).timeout.connect(func(): flash.queue_free())


# ── Collision checks ─────────────────────────────────────────────────────────

func _check_bullet_enemy_overlap() -> void:
	for bullet in get_children():
		if not bullet is Bullet:
			continue
		if not bullet.is_inside_tree():
			continue
		for enemy in get_children():
			if not enemy is BaseEnemy:
				continue
			if not enemy.is_inside_tree():
				continue
			if bullet.position.distance_to(enemy.position) < 22.0:
				bullet.queue_free()
				enemy.hit(bullet.damage)
				break


func _check_player_enemy_overlap() -> void:
	if _player._invincible or _player._frozen:
		return
	for enemy in get_children():
		if not enemy is BaseEnemy:
			continue
		if not enemy.is_inside_tree():
			continue
		if _player.position.distance_to(enemy.position) < 28.0:
			if enemy is FlyEnemy:
				_player.freeze()
				_hud.call("show_frozen")
			else:
				_player.take_damage(enemy.get_damage())
			enemy.hit(999)


func _check_player_enemy_bullets() -> void:
	if _player._invincible or _player._frozen:
		return
	for bullet in get_children():
		if not bullet is EnemyBullet:
			continue
		if not bullet.is_inside_tree():
			continue
		if _player.position.distance_to(bullet.position) < 22.0:
			bullet.queue_free()
			_player.take_damage(1)


func _check_player_powerups() -> void:
	for pu in get_children():
		if not pu is PowerUp:
			continue
		if not pu.is_inside_tree():
			continue
		if _player.position.distance_to(pu.position) < 32.0:
			_collect_powerup(pu as PowerUp)


# ── Event handlers ────────────────────────────────────────────────────────────

func _on_lives_changed(lives: int) -> void:
	_hud.call("update_lives", lives)


func _on_player_damaged() -> void:
	AudioSystem.play_damage()
	_camera_shake()


func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func _on_enemy_killed(_enemy: BaseEnemy) -> void:
	_score += 10
	_hud.call("update_score", _score)
	_enemies_killed += 1
	_check_level_complete()


func _on_all_waves_launched() -> void:
	# All waves spawned — completion will trigger when all kills are confirmed
	pass


func _collect_powerup(pu: PowerUp) -> void:
	match pu.power_type:
		"life":
			_player.add_life()
		"gas":
			_gas_count = mini(_gas_count + 1, GameData.MAX_GAS)
			_hud.call("update_gas", _gas_count)
		"speed":
			_flash_screen(Color(0, 0.8, 1.0, 0.25))
		"shield":
			_flash_screen(Color(0.27, 1.0, 0.53, 0.25))
	_score += 50
	_hud.call("update_score", _score)
	pu.collect()


func _check_level_complete() -> void:
	if _level_done:
		return
	if _enemies_killed >= _total_enemies:
		_complete_level()


func _force_level_complete() -> void:
	if _level_done:
		return
	_complete_level()


func _complete_level() -> void:
	_level_done = true
	AudioSystem.play_level_complete()
	_hud.call("update_mission", "UPPDRAG SLUTFÖRT!")

	SaveSystem.mark_level_complete(_level_id)
	SaveSystem.add_coins(int(_score / 10))

	var is_world_complete := GameData.is_last_level_in_world(_world_id, _level_id)
	var all_done := _are_all_worlds_done()

	get_tree().create_timer(2.0).timeout.connect(func():
		if all_done:
			get_tree().change_scene_to_file("res://scenes/Victory.tscn")
		else:
			GameState.level_result = {
				"level_id": _level_id,
				"world_id": _world_id,
				"score": _score,
				"is_world_complete": is_world_complete,
			}
			get_tree().change_scene_to_file("res://scenes/MissionComplete.tscn")
	)


func _are_all_worlds_done() -> bool:
	var all_ids := GameData.get_all_level_ids()
	for lid in all_ids:
		if not SaveSystem.is_level_complete(lid):
			return false
	return true


func _start_mission_timer() -> void:
	var mission: Dictionary = _level_config.get("mission", {})
	if mission.get("type", "") == "timed":
		_mission_timer_active = true
		_mission_time_left = float(mission.get("time_limit", 60))
		_hud.call("update_timer", int(_mission_time_left))


func _camera_shake() -> void:
	var tween := create_tween()
	var original := position
	for _i in 6:
		tween.tween_property(self, "position",
			original + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.03)
	tween.tween_property(self, "position", original, 0.03)


func _flash_screen(color: Color) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	flash.z_index = 20
	add_child(flash)
	get_tree().create_timer(0.25).timeout.connect(func(): flash.queue_free())


# ── Parallax star layer ───────────────────────────────────────────────────────

class _StarLayer extends Node2D:
	var _stars: Array[Dictionary] = []
	var _offset: float = 0.0

	func _init(count: int, min_r: float, max_r: float, color: Color, min_a: float, max_a: float) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(count) + str(min_r))
		for i in count:
			_stars.append({
				"x": rng.randf() * GameData.GAME_WIDTH,
				"y": rng.randf() * GameData.GAME_HEIGHT,
				"r": rng.randf_range(min_r, max_r),
				"a": rng.randf_range(min_a, max_a),
				"c": color,
			})

	func scroll_to(offset: float) -> void:
		_offset = offset
		queue_redraw()

	func _draw() -> void:
		for star in _stars:
			var x := fmod(star.x - _offset, GameData.GAME_WIDTH)
			if x < 0:
				x += GameData.GAME_WIDTH
			draw_circle(Vector2(x, star.y), star.r, Color(star.c.r, star.c.g, star.c.b, star.a))


