## ErrorCatcher — autoload for rapid bug iteration
## Catches crashes, errors, silent freezes, and FPS drops.
## Registered in project.godot: ErrorCatcher="*res://autoloads/ErrorCatcher.gd"
extends Node

# ── Config ────────────────────────────────────────────────────────────────────
const LOG_PATH            := "user://error_log.txt"
const MAX_OVERLAY         := 8       # lines shown on screen at once
const MAX_LOG_LINES       := 2000    # rotate log after this many lines
const OVERLAY_TTL         := 12.0   # seconds each entry stays visible
const FREEZE_THRESHOLD_MS := 3000   # ms of main-loop silence = freeze
const STUTTER_THRESHOLD_S := 0.5    # single frame longer than this = stutter
const LOW_FPS_THRESHOLD   := 15     # fps below this triggers a warning
const LOW_FPS_FRAMES      := 60     # consecutive low-fps frames before logging

# Show overlay only in debug builds; set false to silence in release too
var overlay_enabled: bool = OS.is_debug_build()

# ── State ─────────────────────────────────────────────────────────────────────
const DEDUP_WINDOW_S := 5.0
const DEDUP_MAX_BURST := 3
var _dedup: Dictionary = {}

var _log_file: FileAccess = null
var _mutex: Mutex = Mutex.new()        # guards all _log_file writes
var _line_count: int = 0

var _entries: Array[Dictionary] = []   # { msg, ttl, color }
var _overlay: CanvasLayer = null
var _label: Label = null
var _last_context: Dictionary = {}

# Watchdog
var _heartbeat_ms: int = 0            # written by main thread, read by watchdog
var _watchdog_thread: Thread = null
var _watchdog_running: bool = false

# FPS / stutter tracking
var _low_fps_streak: int = 0
var _last_frame_ms: int = 0


func _ready() -> void:
	name = "ErrorCatcher"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_open_log()
	_build_overlay()
	log_info("=== Session start | Godot %s | %s ===" % [
		Engine.get_version_info().string,
		Time.get_datetime_string_from_system()
	])
	get_tree().node_added.connect(_on_node_added)
	_start_watchdog()


# ── Public API ────────────────────────────────────────────────────────────────

func log_info(msg: String) -> void:
	_record("INFO", msg, Color(0.6, 1.0, 0.6))


func log_warn(msg: String) -> void:
	if not _should_log(msg):
		return
	var full_msg := msg + _get_callstack()
	_record("WARN", full_msg, Color(1.0, 0.9, 0.3))
	push_warning("[ErrorCatcher] " + msg)


func log_error(msg: String) -> void:
	if not _should_log(msg):
		return
	var full_msg := msg + _get_callstack()
	_record("ERROR", full_msg, Color(1.0, 0.35, 0.35))
	push_error("[ErrorCatcher] " + msg)


## Null-safe node access — logs instead of crashing
func safe_get(node: Node, child_path: NodePath, context: String = "") -> Node:
	if not is_instance_valid(node):
		log_error("safe_get: parent invalid | ctx=%s" % context)
		return null
	var child := node.get_node_or_null(child_path)
	if child == null:
		log_warn("safe_get: '%s' not found | ctx=%s" % [child_path, context])
	return child


## Returns true if node is alive and usable
func is_valid(node: Object, context: String = "") -> bool:
	if node == null or not is_instance_valid(node):
		log_error("is_valid: null/freed | ctx=%s" % context)
		return false
	return true


## Called from Game._process every frame — feeds crash + freeze context
func update_context(ctx: Dictionary) -> void:
	_last_context = ctx.duplicate()
	_heartbeat_ms = Time.get_ticks_msec()   # main thread is alive


## Dump a manual state snapshot to log
func snapshot(label: String = "manual") -> void:
	log_info("[SNAPSHOT:%s] scene=%s fps=%.0f mem=%dMB ctx=%s" % [
		label,
		_current_scene_name(),
		Engine.get_frames_per_second(),
		OS.get_static_memory_usage() / 1_000_000,
		str(_last_context)
	])


# ── Godot notifications ───────────────────────────────────────────────────────

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CRASH:
			_write_crash_report("CRASH")
		NOTIFICATION_WM_CLOSE_REQUEST:
			snapshot("shutdown")
			_stop_watchdog()
			_flush_log()
		NOTIFICATION_PREDELETE:
			_stop_watchdog()


func _process(delta: float) -> void:
	# ── Heartbeat (also updated by update_context, but this covers non-Game scenes)
	_heartbeat_ms = Time.get_ticks_msec()

	# ── Stutter detection: single very long frame
	var now_ms := Time.get_ticks_msec()
	if _last_frame_ms > 0:
		var frame_ms := now_ms - _last_frame_ms
		if frame_ms > int(STUTTER_THRESHOLD_S * 1000):
			log_warn("STUTTER: frame took %dms (%.1fs) | ctx=%s" % [
				frame_ms, frame_ms / 1000.0, str(_last_context)
			])
	_last_frame_ms = now_ms

	# ── Low-FPS streak detection
	var fps := Engine.get_frames_per_second()
	if fps > 0 and fps < LOW_FPS_THRESHOLD:
		_low_fps_streak += 1
		if _low_fps_streak == LOW_FPS_FRAMES:
			log_warn("LOW FPS: %d fps for %d frames | ctx=%s" % [
				int(fps), LOW_FPS_FRAMES, str(_last_context)
			])
	else:
		_low_fps_streak = 0

	# ── Overlay aging
	if overlay_enabled:
		for i in range(_entries.size() - 1, -1, -1):
			_entries[i].ttl -= delta
			if _entries[i].ttl <= 0.0:
				_entries.remove_at(i)
		_refresh_label()


# ── Watchdog thread ───────────────────────────────────────────────────────────

func _start_watchdog() -> void:
	_heartbeat_ms = Time.get_ticks_msec()
	_watchdog_running = true
	_watchdog_thread = Thread.new()
	_watchdog_thread.start(_watchdog_loop)


func _stop_watchdog() -> void:
	_watchdog_running = false
	if _watchdog_thread and _watchdog_thread.is_started():
		_watchdog_thread.wait_to_finish()
	_watchdog_thread = null


func _watchdog_loop() -> void:
	# Runs on a separate OS thread — keeps ticking even when main loop freezes
	var last_reported_ms: int = 0
	while _watchdog_running:
		OS.delay_msec(500)   # check twice per second
		if not _watchdog_running:
			break
		var now := Time.get_ticks_msec()
		var gap  := now - _heartbeat_ms
		if gap >= FREEZE_THRESHOLD_MS and now != last_reported_ms:
			last_reported_ms = now
			_write_freeze_report(gap)


func _write_freeze_report(gap_ms: int) -> void:
	# Called from watchdog thread — must use mutex
	var ts    := Time.get_datetime_string_from_system()
	var lines := [
		"=" .repeat(60),
		"[%s][FREEZE] main loop silent for %dms (%.1fs)" % [ts, gap_ms, gap_ms / 1000.0],
		"  last_context : %s" % str(_last_context),
		"  mem          : %dMB" % (OS.get_static_memory_usage() / 1_000_000),
		"=" .repeat(60),
	]
	_mutex.lock()
	for line in lines:
		if _log_file:
			_log_file.store_line(line)
			_line_count += 1
	if _log_file:
		_log_file.flush()
	_mutex.unlock()


# ── Internal ──────────────────────────────────────────────────────────────────

func _record(level: String, msg: String, color: Color) -> void:
	var ts    := Time.get_time_string_from_system()
	var scene := _current_scene_name()
	var line  := "[%s][%s][%s] %s" % [ts, level, scene, msg]
	_mutex.lock()
	_write_line_unsafe(line)
	_mutex.unlock()

	if overlay_enabled:
		_entries.append({ "text": "[%s] %s" % [level, msg], "ttl": OVERLAY_TTL, "color": color })
		if _entries.size() > MAX_OVERLAY:
			_entries.pop_front()
		_refresh_label()


func _write_line_direct(line: String) -> void:
	_mutex.lock()
	_write_line_unsafe(line)
	if _log_file:
		_log_file.flush()
	_mutex.unlock()


func _get_callstack() -> String:
	if not OS.is_debug_build():
		return ""
	var frames := get_stack()
	var result: PackedStringArray = []
	for i in range(2, min(8, frames.size())):
		var f := frames[i]
		result.append("    at %s:%d in %s()" % [f.get("source", "?"), f.get("line", 0), f.get("function", "?")])
	return "\n".join(result)


func _should_log(msg: String) -> bool:
	var h := hash(msg)
	var now := Time.get_ticks_msec() / 1000.0
	if _dedup.has(h):
		var entry: Dictionary = _dedup[h]
		if now - entry.get("time", 0.0) < DEDUP_WINDOW_S:
			entry["count"] = entry.get("count", 0) + 1
			if entry["count"] > DEDUP_MAX_BURST:
				if entry["count"] == DEDUP_MAX_BURST + 1:
					_write_line_direct("[%s][DEDUP] suppressing repeated: %s" % [
						Time.get_time_string_from_system(), msg
					])
				return false
		else:
			entry["time"] = now
			entry["count"] = 1
	else:
		_dedup[h] = {"time": now, "count": 1}
	return true


# Must be called with _mutex held
func _write_line_unsafe(line: String) -> void:
	if _log_file == null:
		return
	_log_file.store_line(line)
	_line_count += 1
	if _line_count >= MAX_LOG_LINES:
		_rotate_log_unsafe()


func _open_log() -> void:
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if _log_file == null:
		push_error("ErrorCatcher: cannot open log at " + LOG_PATH)
		return
	_log_file.seek_end(0)
	_line_count = _log_file.get_length() / 60


func _rotate_log_unsafe() -> void:
	if _log_file:
		_log_file.flush()
	var backup := LOG_PATH.replace(".txt", "_prev.txt")
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(LOG_PATH),
		ProjectSettings.globalize_path(backup)
	)
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	_line_count = 0
	if _log_file:
		_log_file.store_line("[%s][INFO][system] Log rotated" % Time.get_time_string_from_system())


func _flush_log() -> void:
	_mutex.lock()
	if _log_file:
		_log_file.flush()
	_mutex.unlock()


func _write_crash_report(kind: String) -> void:
	var ts    := Time.get_datetime_string_from_system()
	var scene := _current_scene_name()
	_mutex.lock()
	_write_line_unsafe("=" .repeat(60))
	_write_line_unsafe("[%s][%s] scene=%s" % [ts, kind, scene])
	_write_line_unsafe("  last_context : %s" % str(_last_context))
	_write_line_unsafe("  fps          : %.0f" % Engine.get_frames_per_second())
	_write_line_unsafe("  mem          : %dMB" % (OS.get_static_memory_usage() / 1_000_000))
	_write_line_unsafe("  video_adapter: %s" % RenderingServer.get_video_adapter_name())
	_write_line_unsafe("=" .repeat(60))
	if _log_file:
		_log_file.flush()
	_mutex.unlock()


func _current_scene_name() -> String:
	if get_tree() == null:
		return "no_tree"
	var s := get_tree().current_scene
	return s.name if s else "none"


func _on_node_added(node: Node) -> void:
	if node is BaseEnemy:
		if not node.is_connected("died", _on_enemy_died_watch):
			node.died.connect(_on_enemy_died_watch.bind(node))


func _on_enemy_died_watch(enemy: BaseEnemy, _src: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		log_warn("Enemy 'died' fired but instance already freed — possible double-free")


# ── Overlay ───────────────────────────────────────────────────────────────────

func _build_overlay() -> void:
	if not overlay_enabled:
		return
	_overlay = CanvasLayer.new()
	_overlay.layer = 128
	_overlay.name = "ErrorOverlay"
	add_child(_overlay)

	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.add_theme_constant_override("shadow_outline_size", 2)
	_overlay.add_child(_label)


func _refresh_label() -> void:
	if _label == null:
		return
	if _entries.is_empty():
		_label.text = ""
		return
	var lines: PackedStringArray = []
	for e in _entries:
		lines.append(e.text)
	_label.text = "\n".join(lines)
	var worst := Color(0.6, 1.0, 0.6)
	for e in _entries:
		if e.text.begins_with("[ERROR"):
			worst = Color(1.0, 0.35, 0.35)
			break
		elif e.text.begins_with("[WARN"):
			worst = Color(1.0, 0.9, 0.3)
	_label.add_theme_color_override("font_color", worst)
