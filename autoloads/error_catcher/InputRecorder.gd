class_name InputRecorder
extends RefCounted

const CAPACITY := 30
const ACTIONS  := ["shoot", "gas", "ui_left", "ui_right", "ui_up", "ui_down", "ui_cancel"]

var _buf: Array[Dictionary] = []
var _mutex: Mutex = Mutex.new()


func tick() -> void:
	_mutex.lock()
	for action in ACTIONS:
		if Input.is_action_just_pressed(action):
			_buf.append({ "ts": Time.get_ticks_msec(), "action": action })
			if _buf.size() > CAPACITY:
				_buf.pop_front()
	_mutex.unlock()


func dump() -> String:
	_mutex.lock()
	var snapshot := _buf.duplicate()
	_mutex.unlock()

	if snapshot.is_empty():
		return "(no inputs)"
	var base := snapshot[0].ts
	var lines: PackedStringArray = []
	for e in snapshot:
		lines.append("  +%5dms %s" % [e.ts - base, e.action])
	return "\n".join(lines)


func clear() -> void:
	_mutex.lock()
	_buf.clear()
	_mutex.unlock()
