# Stjärnkrigaren v2 — Feature Plan

## Architecture Overview (v1 patterns to follow)

- All visuals: `_draw()` with polygons, circles, polylines — no sprites/textures
- Collision: manual distance checks in `Game._process()` (not Godot physics)
- Inner classes: self-contained helper nodes (`_ExplosionBurst`, `_StarLayer`, `_UpgradeCard`)
- Signals: typed GDScript signals for inter-component communication
- Audio: synthesized PCM via `AudioStreamWAV` in `AudioSystem.gd`
- Enemies: extend `BaseEnemy` (Area2D), override `_draw_shape()`, `_get_radius()`, `_process()`
- Spawner: wave queue with dictionary configs, factory match in `_do_spawn()`
- Save: flat JSON via `SaveSystem`, `FileAccess`-based

---

## Feature 1: Pause Menu (S)

### What & Why
No pause exists. Players cannot pause mid-level, adjust settings, or quit to menu. Every game needs pause.

### Implementation

**New file: `scenes/PauseMenu.gd`**
- Extends `CanvasLayer`, `z_index = 100`
- Semi-transparent overlay + "PAUS" title + Resume / Quit-to-menu buttons
- Signals: `resume_pressed`, `quit_pressed`
- `process_mode = PROCESS_MODE_WHEN_PAUSED`

**Modify: `scenes/Game.gd`**
- `_unhandled_input(event)`: if `ui_cancel` pressed → `_toggle_pause()`
- `_toggle_pause()`: toggles `get_tree().paused`, shows/hides `_pause_menu`

**New/Modified files:** `scenes/PauseMenu.gd` (new), `scenes/Game.gd`

---

## Feature 2: Shield Mechanic (M)

### What & Why
The "shield" powerup (`EnemySpawner.gd:118`) drops and is collected (`Game.gd:301`) but only triggers `_flash_screen()` — no actual protection. `shield_level` upgrade in `SaveSystem` is also unused.

### Implementation

**Modify: `entities/Player.gd`**
- Add `_shield_active: bool`, `_shield_timer: float`, `_shield_pulse: float`
- `activate_shield()`: sets `_shield_active = true`, `_shield_timer = 8.0`
- In `_draw()`: pulsing double-arc when active:
  ```gdscript
  var r := 32.0 + sin(_shield_pulse) * 3.0
  var a := 0.4 + sin(_shield_pulse * 2.0) * 0.15
  draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.3, 0.8, 1.0, a), 2.5)
  draw_arc(Vector2.ZERO, r + 3.0, 0, TAU, 32, Color(0.3, 0.8, 1.0, a * 0.3), 1.0)
  ```
- In `take_damage()`: if active, absorb hit (scale with `shield_level`), play shield-hit sound
- Signal: `shield_changed(active: bool)`

**Modify: `scenes/Game.gd:301`**
- Change `"shield"` case from `_flash_screen()` to `_player.activate_shield()`

**Modify: `scenes/HUD.gd`**
- Add shield indicator in HUD bar

**Modify: `autoloads/AudioSystem.gd`**
- `play_shield_hit()`: metallic ping 2000→1000 Hz, 0.1s
- `play_shield_activate()`: ascending shimmer

**Files:** `Player.gd`, `Game.gd`, `HUD.gd`, `AudioSystem.gd`

---

## Feature 3: Animated Thruster + Danger Indicators (S)

### What & Why
Static engine glow. Animated thruster adds game-feel. Screen-edge danger arrows warn about off-screen enemies.

### Implementation

**Modify: `entities/Player.gd`**
- Add `_thruster_phase: float`, increment in `_process()`, call `queue_redraw()`
- Replace static glow dot with animated flame polygon:
  ```gdscript
  var thrust_len := 12.0 + abs(velocity.x) * 0.03 + sin(_thruster_phase * 15.0) * 4.0
  draw_polygon([Vector2(-14, -5), Vector2(-14 - thrust_len, 0), Vector2(-14, 5)],
      [Color(1.0, 0.6, 0.1, 0.9)])
  draw_polygon([Vector2(-12, -7), Vector2(-12 - thrust_len * 1.3, 0), Vector2(-12, 7)],
      [Color(0.3, 0.5, 1.0, 0.3)])
  ```

**Modify: `scenes/Game.gd`**
- Add inner class `_DangerIndicator extends Node2D`:
  - Scans `BaseEnemy` children approaching from right edge
  - `_draw()`: pulsing red triangle arrow at screen edge, alpha driven by `sin()`
- Instantiate in `_ready()`, `z_index = 15`

**Files:** `Player.gd`, `Game.gd`

---

## Feature 4: Falcon Companion Drone (M)

### What & Why
`SaveSystem.gd:15` tracks `falcon_level` (default 1). `Hangar.gd:8` sells "Falk Lv2" for 100 coins. No companion entity exists — players buy an upgrade that does nothing.

### Implementation

**New file: `entities/Falcon.gd`**
- Extends `Node2D` (invulnerable — no collision)
- `setup(level: int)`: sets fire rate interval = `1.2 / level`
- Follows player with lerp: `position = lerp(position, _player_ref.position + Vector2(-40, -30), 4.0 * delta)`
- Auto-shoots on timer → emits `falcon_shoot(pos: Vector2)`
- `_draw()`: small triangle (half player size) + blinking wing lights
- Inner class `_FalconTrail`: fading position dots

**Modify: `scenes/Game.gd:67-79` (`_build_player`)**
- After player setup: check `upgrades.get("falcon_level", 0)`
- If >= 1: `_falcon = Falcon.new(); _falcon.setup(falcon_level); add_child(_falcon)`
- Connect `falcon_shoot` signal → `_spawn_bullet(pos, Vector2(900, 0))`

**Files:** `entities/Falcon.gd` (new), `scenes/Game.gd`

---

## Feature 5: Combo/Multiplier Score + High Score Persistence (M)

### What & Why
Score is flat +10 per kill, never saved. Combo system rewards skilled play. Persistent high scores add replay incentive.

### Implementation

**New file: `systems/ComboSystem.gd`**
- `class_name ComboSystem extends Node`
- `_combo: int`, `_combo_timer: float`, `COMBO_WINDOW := 1.5`
- `register_kill() -> int`: increments combo, resets timer, returns score × multiplier
  - 1-4 kills: ×1 | 5-9: ×2 | 10-19: ×3 | 20+: ×5
- Signals: `combo_changed(combo: int, multiplier: float)`, `combo_lost`
- Inner class `_ComboPopup extends Node2D`: floating "+50 ×3!" text fading upward

**Modify: `scenes/Game.gd:280-283`**
- Replace `_score += 10` with `_score += _combo_system.register_kill()`
- Connect `combo_changed` to HUD

**Modify: `scenes/HUD.gd`**
- Large pulsing combo counter when multiplier > 1

**Modify: `autoloads/SaveSystem.gd`**
- Add `"high_scores": {}` to `DEFAULT_STATE`
- `save_high_score(level_id: String, score: int) -> bool`
- `get_high_score(level_id: String) -> int`

**Modify: `scenes/Game.gd:321-343` (`_complete_level`)**
- Call `SaveSystem.save_high_score(_level_id, _score)`

**Modify: `scenes/MissionComplete.gd`**
- Show "NYTT REKORD!" badge if new high score

**Modify: `autoloads/AudioSystem.gd`**
- `play_combo_up()`: ascending note, pitch tracks combo level

**Files:** `systems/ComboSystem.gd` (new), `Game.gd`, `HUD.gd`, `SaveSystem.gd`, `MissionComplete.gd`, `AudioSystem.gd`

---

## Feature 6: Boss Enemies (L)

### What & Why
`GameData.gd:44,72,102,131,160` defines `"mission": {"type": "boss"}` for every world's third level. No boss entity exists — 5 levels are incomplete.

### Implementation

**New file: `entities/enemies/BossEnemy.gd`**
- Extends `BaseEnemy`
- `hp = 50`, `max_hp = 50`, stationary on right edge of screen
- `_draw_shape()`: large ~80px multi-layered polygon with rotating outer ring
- Attack phases (cycle on timer):
  - **Burst**: rapid 5× `shoot_at` signal with spread angles (reuses `RedEnemy` pattern)
  - **Sweep**: slow rotating laser line drawn in `_draw()`, damage on player overlap check
  - **Minions**: signal to spawner to drop 5-8 green enemies from boss position
- Signals: `shoot_at(pos: Vector2)`, `spawn_minions(pos: Vector2, count: int)`
- Inner class `_BossHealthBar extends Node2D`: top-screen HP bar with color shift red→orange→yellow
- Death: `_ExplosionBurst` with 30 particles + extended camera shake

**New file: `entities/enemies/MagnetBoss.gd`** (world-4)
- Extends `BossEnemy`
- Override attack: pulls player toward boss via velocity influence in `Game._process()`
- `_draw_shape()`: concentric rings with alternating colors

**Modify: `systems/EnemySpawner.gd:80-96`**
- Add `"boss"` case in `_do_spawn()` match
- Connect boss signals; emit `boss_defeated` on boss die

**Modify: `scenes/Game.gd`**
- `_start_mission_timer()`: add `elif mission.get("type") == "boss":` branch
- Spawn boss after `all_waves_done`; connect `boss_defeated` → `_complete_level()`

**Modify: `autoloads/AudioSystem.gd`**
- `play_boss_hit()`: deep impact sawtooth 100→50 Hz, 0.15s
- `play_boss_defeated()`: dramatic descending explosion sequence

**Files:** `BossEnemy.gd` (new), `MagnetBoss.gd` (new), `EnemySpawner.gd`, `Game.gd`, `AudioSystem.gd`

---

## Implementation Order

| Phase | Feature | Size | New Files | Modified Files |
|-------|---------|------|-----------|---------------|
| 1 | Pause Menu | S | `PauseMenu.gd` | `Game.gd` |
| 2 | Shield Mechanic | M | — | `Player.gd`, `Game.gd`, `HUD.gd`, `AudioSystem.gd` |
| 3 | Thruster + Danger | S | — | `Player.gd`, `Game.gd` |
| 4 | Falcon Companion | M | `Falcon.gd` | `Game.gd` |
| 5 | Combo + High Score | M | `ComboSystem.gd` | `Game.gd`, `HUD.gd`, `SaveSystem.gd`, `MissionComplete.gd`, `AudioSystem.gd` |
| 6 | Boss Enemies | L | `BossEnemy.gd`, `MagnetBoss.gd` | `EnemySpawner.gd`, `Game.gd`, `AudioSystem.gd` |

**Total: ~950-1100 lines across 5 new files and 9 modified files.**

---

## New Signals

| Signal | Source | Consumer |
|--------|--------|---------|
| `BossEnemy.shoot_at(pos)` | `BossEnemy` | `EnemySpawner` → `Game` |
| `BossEnemy.spawn_minions(pos, count)` | `BossEnemy` | `EnemySpawner` |
| `EnemySpawner.boss_defeated` | `EnemySpawner` | `Game` |
| `Falcon.falcon_shoot(pos)` | `Falcon` | `Game` |
| `Player.shield_changed(active)` | `Player` | `HUD` |
| `ComboSystem.combo_changed(combo, mult)` | `ComboSystem` | `HUD` |
| `ComboSystem.combo_lost` | `ComboSystem` | `HUD` |
| `PauseMenu.resume_pressed` | `PauseMenu` | `Game` |
| `PauseMenu.quit_pressed` | `PauseMenu` | `Game` |

---

## Key File References (v1 → v2 touch points)

- `scenes/Game.gd:293-305` — shield powerup currently does nothing → `activate_shield()`
- `scenes/Game.gd:67-79` — falcon never instantiated despite upgrade existing
- `scenes/Game.gd:354-359` — only handles timed missions, boss path missing
- `scenes/Game.gd:280-283` — flat `+10` score → replace with ComboSystem
- `entities/Player.gd:96-109` — static engine glow → animated thruster
- `entities/Player.gd:112-121` — `take_damage()` → shield intercept here
- `entities/enemies/BaseEnemy.gd:44-46` — `_draw_shape()` override pattern for BossEnemy
- `entities/enemies/RedEnemy.gd:5,40` — `shoot_at` signal pattern to reuse in BossEnemy
- `systems/EnemySpawner.gd:80-96` — `_do_spawn()` match block → add `"boss"` case
- `autoloads/SaveSystem.gd:5-18` — save schema → add `high_scores`
- `autoloads/SaveSystem.gd:15` — `falcon_level` tracked but unused → Falcon.gd uses it
- `autoloads/AudioSystem.gd:61-78` — `_make_beep()` pattern for all new sounds
- `autoloads/GameData.gd:44,72,102,131,160` — boss mission configs already defined
