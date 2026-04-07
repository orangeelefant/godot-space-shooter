class_name StructuredLog
extends RefCounted

const PATH := "user://error_log.json"

var _file: FileAccess = null
var _mutex: Mutex = Mutex.new()


func open() -> void:
	_file = FileAccess.open(PATH, FileAccess.WRITE_READ)
	if _file:
		_file.seek_end(0)


func write(level: String, scene: String, msg: String, extra: Dictionary = {}) -> void:
	if _file == null:
		return
	var entry := {
		"ts":    Time.get_datetime_string_from_system(),
		"level": level,
		"scene": scene,
		"msg":   msg,
	}
	entry.merge(extra)
	_mutex.lock()
	_file.store_line(JSON.stringify(entry))
	_file.flush()
	_mutex.unlock()


func close() -> void:
	_mutex.lock()
	if _file:
		_file.flush()
		_file = null
	_mutex.unlock()
