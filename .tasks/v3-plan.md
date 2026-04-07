# Stjärnkrigaren v3 — Critic Findings Mitigation Plan

## Finding 1: Sweep beam hit feedback (no visual/audio when beam damages player)

**Problem:** Player takes damage from sweep beam silently. Nothing on screen indicates why HP dropped.

**Fix:**
- `scenes/Game.gd` — in `_check_player_boss_sweep()`, on hit: call `_flash_screen(Color(1,0.3,0,0.3))` and `AudioSystem.play_shield_hit()` (repurpose as generic damage flash sound)
- `entities/enemies/BossEnemy.gd` — draw the beam brighter (alpha 0.9) and wider (10px) when player is close to it (pass distance via a setter or check in `_draw_shape`)
- `scenes/HUD.gd` — `show_damage_flash()`: brief red vignette overlay (ColorRect at screen edge, fades in 0.1s/out 0.3s)

**Files:** `scenes/Game.gd`, `scenes/HUD.gd`, `entities/enemies/BossEnemy.gd`
**Effort:** Small

---

## Finding 2: Invisible enemy needs a tell; thin mid-game variety

### 2a — InvisibleEnemy tell
**Problem:** InvisibleEnemy is frustrating with zero warning. Annoyance ≠ challenge.

**Fix:**
- `entities/enemies/InvisibleEnemy.gd` — draw a faint shimmer/distortion ring (draw_arc with alpha ~0.12) so the enemy is barely visible but findable on close inspection
- On proximity to player (<120px): increase shimmer alpha to 0.35 briefly

**Files:** `entities/enemies/InvisibleEnemy.gd`
**Effort:** Tiny

### 2b — Two new mid-game enemy types (worlds 2–4)
**Problem:** Only green/yellow/red/invisible before world 5. Worlds 2-4 feel samey.

**New enemies:**
1. **ShieldEnemy** (`entities/enemies/ShieldEnemy.gd`) — takes 3 hits to kill, draws a hex shield that cracks with each hit. Introduced in world 2.
2. **ZigZagEnemy** (`entities/enemies/ZigZagEnemy.gd`) — moves in a sine wave path. Introduced in world 3.

**Changes:**
- Create `entities/enemies/ShieldEnemy.gd` and `entities/enemies/ZigZagEnemy.gd`
- `autoloads/GameData.gd` — add `"shield"` and `"zigzag"` wave entries to worlds 2–4
- `systems/EnemySpawner.gd` — add match cases for `"shield"` and `"zigzag"`

**Files:** 2 new entity files, `autoloads/GameData.gd`, `systems/EnemySpawner.gd`
**Effort:** Medium

---

## Finding 3: No in-run access to upgrades / cannon change

**Problem:** Wrong cannon before boss = stuck with it. No way to fix mistakes mid-run.

**Fix — Mid-Wave Shop overlay:**
- `scenes/ShopOverlay.gd` (new) — CanvasLayer that appears between waves (after `wave_started` fires for the 2nd+ wave). Shows current cannon level + cost to upgrade. Pauses spawning for 5 seconds or until dismissed.
- `scenes/Game.gd` — connect `_spawner.wave_started` to `_show_shop_if_applicable()`: show overlay on wave 2+ only (not wave 1 or boss wave). On purchase: update `_cannon_level` and call `SaveSystem.save_game()`.
- `scenes/HUD.gd` — show "WAVE 2 INCOMING — SHOP OPEN" banner during shop window

**Files:** New `scenes/ShopOverlay.gd`, `scenes/Game.gd`, `scenes/HUD.gd`
**Effort:** Medium

---

## Finding 4: Flat audio — everything at same volume

**Problem:** Combo pop == boss explosion. After 20 min the audio becomes noise.

**Fix — Volume tiers in AudioSystem:**
- `autoloads/AudioSystem.gd` — add volume constants:
  ```gdscript
  const VOL_BG     := -18.0  # background/ambience
  const VOL_UI     := -8.0   # combo, pickup, score
  const VOL_WEAPON := -4.0   # shoot, enemy bullet
  const VOL_IMPACT := 0.0    # explosion, damage, boss
  ```
- Apply to each `play_*()` method via `stream.volume_db = VOL_*`
- Add a low drone ambient loop (synthesized PCM, plays under gameplay at VOL_BG)

**Files:** `autoloads/AudioSystem.gd`
**Effort:** Small

---

## Implementation Order

| Priority | Finding | Effort | Files touched |
|----------|---------|--------|---------------|
| 1 | Audio mixing (F4) | Small | AudioSystem.gd |
| 2 | Sweep beam feedback (F1) | Small | Game.gd, HUD.gd, BossEnemy.gd |
| 3 | InvisibleEnemy shimmer (F2a) | Tiny | InvisibleEnemy.gd |
| 4 | New enemies: Shield + ZigZag (F2b) | Medium | 2 new files + GameData + Spawner |
| 5 | Mid-wave shop (F3) | Medium | 1 new file + Game.gd + HUD.gd |

Total: ~5 sessions of focused work.
