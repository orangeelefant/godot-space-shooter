## ErrorCatcher — autoload for rapid bug iteration
## Catches crashes, logs context, writes to file, and shows a dev overlay.
## Add to project.godot: ErrorCatcher="*res://autoloads/ErrorCatcher.gd"
extends Node

# ── Config ────────────────────────────────────────────────────────────────────
const LOG_PATH       := "user://error_log.txt"
const MAX_OVERLAY    := 8     # lines shown on screen at once
const MAX_LOG_LINES  := 2000  # rotate log after this many lines
const OVERLAY_TTL    := 12.0  # seconds each entry stays visible

# Show overlay only in debug builds; set false to silence in release too
var overlay_enabled: bool = OS.is_debug_build()

# ── State ─────────────────────────────────────────────────────────────────────
var _log_file: FileAccess = null
var _line_count: int = 0
var _entries: Array[Dictionary] = []   # { msg, ttl, level }
var _overlay: CanvasLayer = null
var _label: Label = null
var _last_context: Dictionary = {}     # snapshot written on crash


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


# ── Public API ────────────────────────────────────────────────────────────────

## General info — green overlay, always logged
func log_info(msg: String) -> void:
	_record("INFO", msg, Color(0.6, 1.0, 0.6))


## Warning — yellow overlay, logged
func log_warn(msg: String) -> void:
	_record("WARN", msg, Color(1.0, 0.9, 0.3))
	push_warning("[ErrorCatcher] " + msg)


## Error — red overlay, logged, includes current game context
func log_error(msg: String) -> void:
	_record("ERROR", msg, Color(1.0, 0.35, 0.35))
	push_error("[ErrorCatcher] " + msg)


## Safe node access — returns null and logs instead of crashing
func safe_get(node: Node, child_path: NodePath, context: String = "") -> Node:
	if not is_instance_valid(node):
		log_error("safe_get: parent node is invalid | context=%s" % context)
		return null
	var child := node.get_node_or_null(child_path)
	if child == null:
		log_warn("safe_get: '%s' not found | context=%s" % [child_path, context])
	return child


## Validate a node and log if dead/null — returns true if usable
func is_valid(node: Object, context: String = "") -> bool:
	if node == null or not is_instance_valid(node):
		log_error("is_valid: null/freed instance | context=%s" % context)
		return false
	return true


## Store game context for crash reports (call from Game._process)
func update_context(ctx: Dictionary) -> void:
	_last_context = ctx.duplicate()


## Dump a manual snapshot of the current game state to the log
func snapshot(label: String = "manual") -> void:
	var scene_name := _current_scene_name()
	log_info("[SNAPSHOT:%s] scene=%s fps=%.0f mem=%dMB | ctx=%s" % [
		label,
		scene_name,
		Engine.get_frames_per_second(),
		OS.get_static_memory_usage() / 1_000_000,
		str(_last_context)
	])


# ── Godot notifications ───────────────────────────────────────────────────────

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CRASH:
			_write_crash_report()
		NOTIFICATION_WM_CLOSE_REQUEST:
			snapshot("shutdown")
			_flush_log()


func _process(delta: float) -> void:
	if not overlay_enabled:
		return
	# Age entries
	for i in range(_entries.size() - 1, -1, -1):
		_entries[i].ttl -= delta
		if _entries[i].ttl <= 0.0:
			_entries.remove_at(i)
	_refresh_label()


# ── Internal ──────────────────────────────────────────────────────────────────

func _record(level: String, msg: String, color: Color) -> void:
	var ts := Time.get_time_string_from_system()
	var scene := _current_scene_name()
	var line := "[%s][%s][%s] %s" % [ts, level, scene, msg]

	_write_line(line)

	if overlay_enabled:
		_entries.append({ "text": "[%s] %s" % [level, msg], "ttl": OVERLAY_TTL, "color": color })
		if _entries.size() > MAX_OVERLAY:
			_entries.pop_front()
		_refresh_label()


func _write_line(line: String) -> void:
	if _log_file == null:
		return
	_log_file.store_line(line)
	_line_count += 1
	if _line_count >= MAX_LOG_LINES:
		_rotate_log()


func _open_log() -> void:
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if _log_file == null:
		push_error("ErrorCatcher: cannot open log at " + LOG_PATH)
		return
	# Seek to end to append
	_log_file.seek_end(0)
	# Estimate current line count to know when to rotate
	var size := _log_file.get_length()
	_line_count = size / 60  # rough average


func _rotate_log() -> void:
	_flush_log()
	var backup := LOG_PATH.replace(".txt", "_prev.txt")
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(LOG_PATH),
		ProjectSettings.globalize_path(backup)
	)
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	_line_count = 0
	_write_line("[%s][INFO][system] Log rotated — previous saved to %s" % [
		Time.get_time_string_from_system(), backup
	])


func _flush_log() -> void:
	if _log_file:
		_log_file.flush()


func _write_crash_report() -> void:
	var ts  := Time.get_datetime_string_from_system()
	var scene := _current_scene_name()
	_write_line("=" .repeat(60))
	_write_line("[%s][CRASH] scene=%s" % [ts, scene])
	_write_line("  last_context : %s" % str(_last_context))
	_write_line("  fps          : %.0f" % Engine.get_frames_per_second())
	_write_line("  mem          : %dMB" % (OS.get_static_memory_usage() / 1_000_000))
	_write_line("  video_adapter: %s" % RenderingServer.get_video_adapter_name())
	_write_line("=" .repeat(60))
	_flush_log()


func _current_scene_name() -> String:
	if get_tree() == null:
		return "no_tree"
	var s := get_tree().current_scene
	return s.name if s else "none"


## Auto-watch enemy and bullet nodes for freed-while-active patterns
func _on_node_added(node: Node) -> void:
	if node is BaseEnemy:
		if not node.is_connected("died", _on_enemy_died_watch):
			node.died.connect(_on_enemy_died_watch.bind(node))
	# Uncomment to trace every spawn in the log (noisy):
	# if node is BaseEnemy or node.get_script() != null:
	#     log_info("SPAWN: %s @ %s" % [node.name, str(node.get_position() if node.has_method("get_position") else "?")])


func _on_enemy_died_watch(enemy: BaseEnemy, _src: BaseEnemy) -> void:
	# Fires if an enemy's died signal arrives but the node is already freed
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
	# Colour by worst level present
	var worst := Color(0.6, 1.0, 0.6)
	for e in _entries:
		if e.text.begins_with("[ERROR"):
			worst = Color(1.0, 0.35, 0.35)
			break
		elif e.text.begins_with("[WARN"):
			worst = Color(1.0, 0.9, 0.3)
	_label.add_theme_color_override("font_color", worst)
