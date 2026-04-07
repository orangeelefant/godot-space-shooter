extends Node2D

var _world_id: String = "world-1"
var _level_id: String = "w1-l1"
var _level_config: Dictionary = {}

var _player: Player
var _spawner: EnemySpawner
var _hud: CanvasLayer
var _pause_menu: CanvasLayer
var _falcon: Node2D
var _combo_system: Node
var _danger_ind: Node2D

var _score: int = 0
var _gas_count: int = 3
var _total_enemies: int = 0
var _enemies_killed: int = 0
var _enemies_live: int = 0   # incremented on spawn, decremented on kill or escape
var _check_complete_pending: bool = false  # set true when an enemy dies/escapes to defer the scan
var _level_done: bool = false

var _cannon_level: String = "enkel"
var _shop_open: bool = false
var _shoot_cooldown: float = 0.0
var _sweep_hit_cooldown: float = 0.0
const SHOOT_RATE := 0.18  # seconds between shots

# Parallax
var _stars_far: Node2D
var _stars_near: Node2D
var _nebula: Node2D
var _god_rays: ColorRect
var _planet: Node2D
var _asteroids: Node2D
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
	# Load save once — pass state to builders that need it to avoid redundant file reads
	var save_state := SaveSystem.load_game()
	_load_save(save_state)
	_build_background()
	_build_player(save_state)
	_build_hud()
	_build_spawner()
	_wire_collisions()
	_build_pause_menu()
	_build_falcon(save_state)
	_build_combo_system()
	_build_danger_indicator()
	_start_mission_timer()


func setup(world_id: String, level_id: String) -> void:
	_world_id = world_id
	_level_id = level_id


func _load_save(state: Dictionary) -> void:
	_gas_count = int(state.get("gas_grenades", 3))
	var upgrades: Dictionary = state.get("upgrades", {})
	_cannon_level = upgrades.get("cannon_level", "enkel")


func _build_background() -> void:
	# Nebula layer (behind everything)
	_nebula = _NebulaLayer.new()
	add_child(_nebula)

	# God rays layer (behind stars)
	_god_rays = _GodRaysLayer.new()
	add_child(_god_rays)

	# Far parallax layer
	_stars_far = _StarLayer.new(80, 0.5, 1.5, Color(0.27, 0.53, 0.8), 0.15, 0.5)
	_stars_far.z_index = 0
	add_child(_stars_far)

	# Planet layer
	_planet = _PlanetLayer.new()
	add_child(_planet)

	# Near parallax layer
	_stars_near = _StarLayer.new(40, 1.5, 3.0, Color(1, 1, 1), 0.5, 1.0)
	_stars_near.z_index = 1
	add_child(_stars_near)

	# Asteroid belt layer
	_asteroids = _AsteroidLayer.new()
	add_child(_asteroids)


func _build_player(state: Dictionary) -> void:
	var ship := GameData.get_ship(state.get("ship_id", "ruben"))
	var upgrades: Dictionary = state.get("upgrades", {})

	_player = Player.new()
	_player.setup(ship, upgrades)
	_player.position = Vector2(200, GameData.GAME_HEIGHT / 2.0)
	_player.z_index = 10
	_player.lives_changed.connect(_on_lives_changed)
	_player.damaged.connect(_on_player_damaged)
	_player.died.connect(_on_player_died)
	_player.shield_changed.connect(func(active: bool): _hud.call("update_shield", active))
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
	_spawner.boss_spawned.connect(_on_boss_spawned)
	_spawner.wave_started.connect(_on_wave_started)
	_spawner.setup(waves)


func _wire_collisions() -> void:
	pass


func _build_pause_menu() -> void:
	var scene := load("res://scenes/PauseMenu.tscn")
	_pause_menu = scene.instantiate()
	_pause_menu.visible = false
	_pause_menu.resume_pressed.connect(_toggle_pause)
	_pause_menu.quit_pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")
	)
	add_child(_pause_menu)


func _build_falcon(state: Dictionary) -> void:
	var upgrades: Dictionary = state.get("upgrades", {})
	var falcon_level: int = int(upgrades.get("falcon_level", 0))
	if falcon_level < 1:
		return
	_falcon = Falcon.new()
	(_falcon as Falcon).setup(falcon_level, _player)
	(_falcon as Falcon).falcon_shoot.connect(func(pos: Vector2): _spawn_bullet(pos, Vector2(900, 0)))
	add_child(_falcon)


func _build_combo_system() -> void:
	_combo_system = ComboSystem.new()
	(_combo_system as ComboSystem).combo_changed.connect(_on_combo_changed)
	(_combo_system as ComboSystem).combo_lost.connect(_on_combo_lost)
	add_child(_combo_system)


func _build_danger_indicator() -> void:
	_danger_ind = _DangerIndicator.new()
	_danger_ind.z_index = 15
	add_child(_danger_ind)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _level_done:
		_toggle_pause()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause_menu.visible = paused


func _process(delta: float) -> void:
	# Parallax
	_far_offset += 0.15 * delta * 60.0
	_near_offset += 0.5 * delta * 60.0
	if _stars_far.has_method("scroll_to"):
		_stars_far.call("scroll_to", _far_offset)
		_stars_near.call("scroll_to", _near_offset)
		_nebula.call("scroll_to", _far_offset)
		_planet.call("scroll_to", _far_offset)
		_asteroids.call("scroll_to", _near_offset)

	# Shooting
	_shoot_cooldown -= delta
	_sweep_hit_cooldown -= delta
	if _player.is_shoot_pressed() and _shoot_cooldown <= 0.0:
		_fire_bullet()
		_shoot_cooldown = SHOOT_RATE

	# Gas grenade
	if _player.is_gas_pressed() and _gas_count > 0:
		_use_gas()

	# Gather typed lists once — avoids repeated get_children() scans per check
	var bullets: Array = []
	var enemies: Array = []
	var enemy_bullets: Array = []
	var powerups: Array = []
	var bosses: Array = []
	for child in get_children():
		if not child.is_inside_tree():
			continue
		if child is Bullet:
			bullets.append(child)
		elif child is BaseEnemy:
			if child is BossEnemy:
				bosses.append(child)
			else:
				enemies.append(child)
		elif child is EnemyBullet:
			enemy_bullets.append(child)
		elif child is PowerUp:
			powerups.append(child)

	# Collision checks (manual overlap)
	_check_bullet_enemy_overlap(bullets, enemies)
	_check_player_enemy_overlap(enemies)
	_check_player_enemy_bullets(enemy_bullets)
	_check_player_powerups(powerups)
	_check_player_boss_sweep(bosses)

	# Magnet boss pull — reuses already-gathered bosses array, no extra get_children()
	_apply_magnet_pull(delta, bosses)

	# Handle enemies that escaped off-screen without being killed
	# Only scan when an enemy actually died/escaped — not every frame
	if _check_complete_pending and _spawner._all_launched and not _level_done:
		_check_complete_pending = false
		_check_level_complete()

	# Feed crash-context to ErrorCatcher every frame (cheap dict, no alloc)
	ErrorCatcher.update_context({
		"level": _level_id,
		"score": _score,
		"lives": _player.lives if is_instance_valid(_player) else -1,
		"enemies_live": _enemies_live,
		"enemies_killed": _enemies_killed,
		"wave": _spawner._current_wave if is_instance_valid(_spawner) else -1,
		"gas": _gas_count,
		"pos": str(_player.position) if is_instance_valid(_player) else "?",
	})

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
	_spawn_muzzle_flash(muzzle)
	match _cannon_level:
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
			_spawn_laser_beam(muzzle)
		"slash":
			var angles := [-60.0, -30.0, 0.0, 30.0, 60.0]
			for deg in angles:
				var rad := deg_to_rad(deg)
				var vel := Vector2(cos(rad), sin(rad)) * 950.0
				var b := _spawn_bullet(muzzle, vel)
				b.damage = 2
			_spawn_slash_arc(muzzle)
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
	# Update only the gas_grenades field — avoid a full load_game() round-trip during gameplay
	var state := SaveSystem.load_game()
	state["gas_grenades"] = _gas_count
	SaveSystem.save_game(state)
	_check_complete_pending = true  # enemies are about to be cleared
	_spawner.kill_all()
	# Screen flash
	var flash := ColorRect.new()
	flash.color = Color(0, 0.4, 1.0, 0.35)
	flash.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	flash.z_index = 20
	add_child(flash)
	get_tree().create_timer(0.3).timeout.connect(func(): flash.queue_free())


# ── Collision checks ─────────────────────────────────────────────────────────

func _check_bullet_enemy_overlap(bullets: Array, enemies: Array) -> void:
	for bullet in bullets:
		if not is_instance_valid(bullet) or not bullet.is_inside_tree():
			continue
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.is_inside_tree():
				continue
			if bullet.position.distance_to(enemy.position) < 22.0:
				bullet.queue_free()
				enemy.hit(bullet.damage)
				break


func _check_player_enemy_overlap(enemies: Array) -> void:
	if _player._invincible or _player._frozen:
		return
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if _player.position.distance_to(enemy.position) < 28.0:
			if enemy is FlyEnemy:
				_player.freeze()
				_hud.call("show_frozen")
			else:
				_player.take_damage(enemy.get_damage())
			enemy.hit(999)


func _check_player_enemy_bullets(enemy_bullets: Array) -> void:
	if _player._invincible or _player._frozen:
		return
	for bullet in enemy_bullets:
		if not is_instance_valid(bullet) or not bullet.is_inside_tree():
			continue
		if _player.position.distance_to(bullet.position) < 22.0:
			bullet.queue_free()
			_player.take_damage(1)


func _check_player_powerups(powerups: Array) -> void:
	for pu in powerups:
		if not is_instance_valid(pu) or not pu.is_inside_tree():
			continue
		if _player.position.distance_to(pu.position) < 32.0:
			_collect_powerup(pu as PowerUp)


func _check_player_boss_sweep(bosses: Array) -> void:
	if _player._invincible or _player._frozen:
		return
	if _sweep_hit_cooldown > 0.0:
		return
	for child in bosses:
		var boss := child as BossEnemy
		if not boss.is_sweep_active():
			continue
		var a := boss.position
		var b := boss.get_sweep_end()
		var ab := b - a
		var t := clampf(((_player.position - a).dot(ab)) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(_player.position) < 30.0:
			_player.take_damage(1)
			_hud.call("show_damage_flash")
			AudioSystem.play_damage()
			_sweep_hit_cooldown = 0.6


# ── Event handlers ────────────────────────────────────────────────────────────

func _on_lives_changed(lives: int) -> void:
	_hud.call("update_lives", lives)


func _on_player_damaged() -> void:
	AudioSystem.play_damage()
	_camera_shake()


func _on_player_died() -> void:
	GameState.last_score = _score
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func _on_enemy_killed(enemy: BaseEnemy) -> void:
	_spawn_explosion(enemy.position, 1.0)
	var points := (_combo_system as ComboSystem).register_kill()
	_score += points
	_hud.call("update_score", _score)
	_enemies_killed += 1
	_check_complete_pending = true
	_check_level_complete()


func _on_combo_changed(combo: int, multiplier: int) -> void:
	if multiplier > 1:
		_hud.call("update_combo", combo, multiplier)
		AudioSystem.play_combo_up(multiplier)
	if combo in [5, 10, 20] and is_instance_valid(_player):
		_spawn_combo_burst(_player.position, multiplier)


func _spawn_combo_burst(pos: Vector2, tier: int) -> void:
	var size := 60.0 + float(tier) * 30.0
	var burst := ColorRect.new()
	burst.size = Vector2(size * 2.0, size * 2.0)
	burst.position = pos - Vector2(size, size)
	burst.z_index = 9
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/starburst.gdshader")
	if shader:
		mat.shader = shader
		var col := Color(1.0, 0.8, 0.2) if tier < 5 else Color(0.5, 0.2, 1.0)
		mat.set_shader_parameter("flare_color", col)
		mat.set_shader_parameter("ray_count", float(tier + 4))
		mat.set_shader_parameter("lifespan", 1.0)
		burst.material = mat
	add_child(burst)
	var t := create_tween()
	t.tween_method(func(v: float): if is_instance_valid(burst) and burst.material: (burst.material as ShaderMaterial).set_shader_parameter("lifespan", v), 1.0, 0.0, 0.55)
	t.tween_callback(func(): if is_instance_valid(burst): burst.queue_free())


func _on_combo_lost() -> void:
	_hud.call("update_combo", 0, 1)


func _on_wave_started(index: int) -> void:
	if index == 0 or _shop_open or _level_done:
		return
	var mission_type: String = _level_config.get("mission", {}).get("type", "")
	if mission_type == "boss":
		return
	_shop_open = true
	get_tree().paused = true
	var overlay: CanvasLayer = load("res://scenes/ShopOverlay.gd").new()
	overlay.call("setup", _cannon_level, func(new_cannon: String): _cannon_level = new_cannon)
	overlay.connect("closed", func(): _shop_open = false)
	add_child(overlay)


func _on_all_waves_launched() -> void:
	_check_complete_pending = true


func _on_boss_spawned(boss: BossEnemy) -> void:
	var bar := BossEnemy.create_health_bar(boss)
	add_child(bar)


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
			_player.activate_shield()
	_score += 50
	_hud.call("update_score", _score)
	pu.collect()
	_spawn_starburst(pu.position)


func _check_level_complete() -> void:
	if _level_done:
		return
	var mission_type: String = _level_config.get("mission", {}).get("type", "")
	if mission_type == "boss":
		return  # Boss missions complete only via boss_defeated signal
	if not _spawner._all_launched:
		return
	for child in get_children():
		if child is BaseEnemy:
			return
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
	var is_new_record := SaveSystem.save_high_score(_level_id, _score)

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
				"is_new_record": is_new_record,
				"high_score": SaveSystem.get_high_score(_level_id),
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
	match mission.get("type", ""):
		"timed":
			_mission_timer_active = true
			_mission_time_left = float(mission.get("time_limit", 60))
			_hud.call("update_timer", int(_mission_time_left))
		"boss":
			# Boss spawns after all normal waves complete
			_spawner.all_waves_done.connect(_spawn_boss, CONNECT_ONE_SHOT)
			_spawner.boss_defeated.connect(func():
				for child in get_children():
					if child is BossEnemy:
						_spawn_explosion(child.position, 2.5)
						_camera_shake(1.5)
						break
				if not _level_done:
					_force_level_complete()
			, CONNECT_ONE_SHOT)


func _spawn_boss() -> void:
	var mission: Dictionary = _level_config.get("mission", {})
	var boss_type: String = mission.get("boss_type", "standard")
	var boss_wave := [{"type": "boss", "count": 1, "formation": "line", "delay": 0.0, "boss_type": boss_type}]
	_spawner.setup(boss_wave)
	_hud.call("update_mission", "BOSS!")
	AudioSystem.play_boss_hit()


func _apply_magnet_pull(delta: float, bosses: Array) -> void:
	# Reuses already-gathered bosses array — no extra get_children() scan
	for child in bosses:
		if not is_instance_valid(child):
			continue
		var boss := child as BossEnemy
		if boss == null or not boss.has_method("is_pulling"):
			continue
		if not boss.call("is_pulling"):
			continue
		var toward := boss.position - _player.position
		var dist := toward.length()
		if dist > 20.0:
			var strength := 90.0 * (1.0 - clampf(dist / 700.0, 0.0, 1.0))
			_player.position += toward.normalized() * strength * delta
			_player.position.x = clampf(_player.position.x, 30.0, GameData.GAME_WIDTH - 30.0)
			_player.position.y = clampf(_player.position.y, 70.0, GameData.GAME_HEIGHT - 30.0)


func _camera_shake(intensity: float = 1.0) -> void:
	var tween := create_tween()
	var original := position
	for _i in int(4 + intensity * 4):
		tween.tween_property(self, "position",
			original + Vector2(randf_range(-8, 8), randf_range(-6, 6)) * intensity, 0.03)
	tween.tween_property(self, "position", original, 0.03)


func _flash_screen(color: Color) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
	flash.z_index = 20
	add_child(flash)
	get_tree().create_timer(0.25).timeout.connect(func(): flash.queue_free())


func _spawn_muzzle_flash(pos: Vector2) -> void:
	var flash := _MuzzleFlash.new()
	flash.position = pos
	flash.z_index = 6
	add_child(flash)


func _spawn_explosion(pos: Vector2, size: float) -> void:
	var ex := _Explosion.new(size)
	ex.position = pos
	ex.z_index = 8
	add_child(ex)


func _spawn_laser_beam(start: Vector2) -> void:
	var beam := ColorRect.new()
	beam.size = Vector2(GameData.GAME_WIDTH - start.x, 6)
	beam.position = start + Vector2(0, -3)
	beam.z_index = 6
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/energy_beam.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("color", Color(0.0, 1.0, 0.9, 1.0))
		mat.set_shader_parameter("outline_color", Color(0.3, 0.8, 1.0, 0.6))
		mat.set_shader_parameter("speed", 3.0)
		mat.set_shader_parameter("thickness", 0.015)
		mat.set_shader_parameter("beams", 1)
		beam.material = mat
	add_child(beam)
	# Auto-remove after brief flash
	get_tree().create_timer(0.09).timeout.connect(func(): if is_instance_valid(beam): beam.queue_free())


func _spawn_slash_arc(pos: Vector2) -> void:
	var arc := ColorRect.new()
	arc.size = Vector2(180, 180)
	arc.position = pos + Vector2(-20, -90)
	arc.z_index = 7
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/slash_arc.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("slash_color", Color(0.8, 0.3, 1.0, 1.0))
		mat.set_shader_parameter("progress", 1.0)
		arc.material = mat
	add_child(arc)
	# Animate fade-out
	var t := create_tween()
	t.tween_method(func(v: float): if is_instance_valid(arc) and arc.material: (arc.material as ShaderMaterial).set_shader_parameter("progress", v), 1.0, 0.0, 0.25)
	t.tween_callback(func(): if is_instance_valid(arc): arc.queue_free())


func _spawn_starburst(pos: Vector2) -> void:
	var burst := ColorRect.new()
	burst.size = Vector2(80, 80)
	burst.position = pos - Vector2(40, 40)
	burst.z_index = 9
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/starburst.gdshader")
	if shader:
		mat.shader = shader
		mat.set_shader_parameter("lifespan", 1.0)
		burst.material = mat
	add_child(burst)
	get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(burst): burst.queue_free())


# ── Muzzle flash ─────────────────────────────────────────────────────────────

class _MuzzleFlash extends Node2D:
	var _elapsed: float = 0.0
	const DURATION := 0.08

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()
		if _elapsed >= DURATION:
			queue_free()

	func _draw() -> void:
		var t := 1.0 - (_elapsed / DURATION)
		draw_circle(Vector2.ZERO, 10.0 * t, Color(1.0, 0.9, 0.4, t * 0.8))
		draw_circle(Vector2.ZERO, 5.0 * t, Color(1.0, 1.0, 1.0, t))
		# Three spike lines
		for i in 3:
			var a := float(i) / 3.0 * TAU
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 14.0 * t, Color(1.0, 0.8, 0.2, t * 0.6), 1.5)


# ── Danger indicator ─────────────────────────────────────────────────────────

class _DangerIndicator extends Node2D:
	var _pulse: float = 0.0
	var _cached_parent: Node = null

	func _ready() -> void:
		_cached_parent = get_parent()

	func _process(delta: float) -> void:
		_pulse += delta * 4.0
		queue_redraw()

	func _draw() -> void:
		if not _cached_parent or not is_instance_valid(_cached_parent):
			return
		var alpha := 0.5 + sin(_pulse) * 0.35
		for child in _cached_parent.get_children():
			if not child is BaseEnemy:
				continue
			if not child.is_inside_tree():
				continue
			var ex: float = child.position.x
			var ey: float = child.position.y
			if ex > GameData.GAME_WIDTH - 80.0:
				# Enemy off right edge — draw arrow on right
				var ax := float(GameData.GAME_WIDTH) - 18.0
				var ay := clampf(ey, 40.0, GameData.GAME_HEIGHT - 40.0)
				draw_colored_polygon(
					PackedVector2Array([
						Vector2(ax + 14, ay),
						Vector2(ax - 2, ay - 10),
						Vector2(ax - 2, ay + 10),
					]),
					Color(1.0, 0.2, 0.2, alpha)
				)


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


# ── Nebula layer ──────────────────────────────────────────────────────────────

class _NebulaLayer extends Node2D:
	var _offset: float = 0.0
	var _blobs: Array[Dictionary] = []

	func _ready() -> void:
		z_index = -1
		for i in 8:
			_blobs.append({
				"x": randf_range(0, GameData.GAME_WIDTH),
				"y": randf_range(0, GameData.GAME_HEIGHT),
				"r": randf_range(120.0, 280.0),
				"color": [
					Color(0.2, 0.05, 0.4, 0.07),
					Color(0.0, 0.1, 0.35, 0.06),
					Color(0.3, 0.0, 0.2, 0.05),
				][randi() % 3],
			})
		queue_redraw()

	func scroll_to(offset: float) -> void:
		_offset = offset
		queue_redraw()

	func _draw() -> void:
		for b in _blobs:
			var radius: float = float(b["r"])
			var color: Color = b["color"]
			var x: float = fmod(float(b["x"]) - _offset * 0.03, GameData.GAME_WIDTH + radius * 2.0) - radius
			draw_circle(Vector2(x, float(b["y"])), radius, color)
			draw_circle(Vector2(x, float(b["y"])), radius * 0.6, Color(color.r, color.g, color.b, color.a * 1.5))


# ── God rays layer ────────────────────────────────────────────────────────────

class _GodRaysLayer extends ColorRect:
	func _ready() -> void:
		z_index = -1
		size = Vector2(GameData.GAME_WIDTH, GameData.GAME_HEIGHT)
		color = Color(0, 0, 0, 0)  # transparent fallback so no white flash if shader missing
		mouse_filter = Control.MOUSE_FILTER_IGNORE  # never block input
		var mat := ShaderMaterial.new()
		var shader := load("res://shaders/god_rays.gdshader")
		if shader:
			mat.shader = shader
			mat.set_shader_parameter("color", Color(0.08, 0.2, 0.6, 0.12))
			mat.set_shader_parameter("angle", -0.25)
			mat.set_shader_parameter("spread", 0.4)
			mat.set_shader_parameter("speed", 0.6)
			mat.set_shader_parameter("ray1_density", 6.0)
			mat.set_shader_parameter("ray2_density", 25.0)
			material = mat


# ── Planet layer ──────────────────────────────────────────────────────────────

class _PlanetLayer extends Node2D:
	var _offset: float = 0.0
	const PLANET_X := GameData.GAME_WIDTH * 0.78
	const PLANET_Y := GameData.GAME_HEIGHT * 0.35
	const PLANET_R := 320.0

	func _ready() -> void:
		z_index = 1
		queue_redraw()

	func scroll_to(offset: float) -> void:
		_offset = offset
		queue_redraw()

	func _draw() -> void:
		var px := PLANET_X - _offset * 0.01
		# Planet body
		draw_circle(Vector2(px, PLANET_Y), PLANET_R, Color(0.08, 0.12, 0.22))
		# Atmosphere rim
		draw_arc(Vector2(px, PLANET_Y), PLANET_R, 0, TAU, 64, Color(0.15, 0.3, 0.6, 0.4), 8.0)
		draw_arc(Vector2(px, PLANET_Y), PLANET_R + 6, 0, TAU, 64, Color(0.1, 0.2, 0.5, 0.15), 4.0)
		# Surface bands (horizontal stripes via arcs)
		draw_arc(Vector2(px, PLANET_Y), PLANET_R * 0.75, 0.1, PI - 0.1, 32, Color(0.1, 0.15, 0.28, 0.6), 3.0)
		draw_arc(Vector2(px, PLANET_Y), PLANET_R * 0.45, 0.2, PI - 0.2, 24, Color(0.12, 0.18, 0.3, 0.5), 2.0)
		# Ring system
		draw_arc(Vector2(px, PLANET_Y), PLANET_R * 1.5, -0.3, PI + 0.3, 48, Color(0.3, 0.4, 0.6, 0.18), 3.0)
		draw_arc(Vector2(px, PLANET_Y), PLANET_R * 1.65, -0.25, PI + 0.25, 48, Color(0.25, 0.35, 0.55, 0.1), 2.0)


# ── Explosion effect ──────────────────────────────────────────────────────────

class _Explosion extends Node2D:
	var _elapsed: float = 0.0
	var _particles: Array[Dictionary] = []
	const DURATION := 0.55

	func _init(size: float) -> void:
		var count := int(8 + size * 4)
		for i in count:
			var angle := randf() * TAU
			var speed := randf_range(40.0, 120.0) * size
			_particles.append({
				"pos": Vector2.ZERO,
				"vel": Vector2(cos(angle), sin(angle)) * speed,
				"r":   randf_range(2.0, 5.0) * size,
				"col": [Color(1.0, 0.6, 0.1), Color(1.0, 0.2, 0.0), Color(1.0, 0.9, 0.3)][randi() % 3],
			})

	func _process(delta: float) -> void:
		_elapsed += delta
		for p in _particles:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.88
		queue_redraw()
		if _elapsed >= DURATION:
			queue_free()

	func _draw() -> void:
		var t := _elapsed / DURATION
		var alpha := 1.0 - t
		for p in _particles:
			var r := p["r"] * (1.0 - t * 0.5)
			var col: Color = p["col"]
			draw_circle(p["pos"], r, Color(col.r, col.g, col.b, alpha))
		# Central flash (fades fast)
		if t < 0.25:
			var flash_a := (1.0 - t / 0.25) * 0.7
			draw_circle(Vector2.ZERO, 18.0 * (1.0 - t / 0.25), Color(1.0, 1.0, 0.8, flash_a))


# ── Asteroid layer ────────────────────────────────────────────────────────────

class _AsteroidLayer extends Node2D:
	var _offset: float = 0.0
	var _rocks: Array[Dictionary] = []

	func _ready() -> void:
		z_index = 2
		for i in 12:
			var pts := PackedVector2Array()
			var sides := randi_range(5, 8)
			var base_r := randf_range(8.0, 22.0)
			for j in sides:
				var a := float(j) / float(sides) * TAU
				var r := base_r * randf_range(0.7, 1.3)
				pts.append(Vector2(cos(a), sin(a)) * r)
			_rocks.append({
				"x": randf_range(0, GameData.GAME_WIDTH),
				"y": randf_range(30, GameData.GAME_HEIGHT - 30),
				"pts": pts,
				"speed": randf_range(0.04, 0.12),
				"rot": randf() * TAU,
				"rot_speed": randf_range(-0.3, 0.3),
			})
		queue_redraw()

	func scroll_to(offset: float) -> void:
		_offset = offset
		queue_redraw()

	func _draw() -> void:
		for r in _rocks:
			var x := fmod(r["x"] - _offset * r["speed"], GameData.GAME_WIDTH + 50.0) - 25.0
			var rot_pts := PackedVector2Array()
			var cos_r := cos(r["rot"] + _offset * r["rot_speed"] * 0.01)
			var sin_r := sin(r["rot"] + _offset * r["rot_speed"] * 0.01)
			for p in r["pts"]:
				rot_pts.append(Vector2(p.x * cos_r - p.y * sin_r, p.x * sin_r + p.y * cos_r))
			draw_colored_polygon(rot_pts, Color(0.18, 0.16, 0.14, 0.7))
			draw_polyline(rot_pts, Color(0.3, 0.27, 0.24, 0.5), 1.0)
			draw_line(rot_pts[rot_pts.size()-1], rot_pts[0], Color(0.3, 0.27, 0.24, 0.5), 1.0)
