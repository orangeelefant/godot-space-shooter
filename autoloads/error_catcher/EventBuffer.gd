class_name EventBuffer
extends RefCounted

const CAPACITY := 64

var _buf: Array[Dictionary] = []
var _head: int = 0
var _full: bool = false
var _mutex: Mutex = Mutex.new()


func record(tag: String, detail: String = "") -> void:
	_mutex.lock()
	var entry := { "ts": Time.get_ticks_msec(), "tag": tag, "detail": detail }
	if _full:
		_buf[_head] = entry
	else:
		_buf.append(entry)
	_head = (_head + 1) % CAPACITY
	if _head == 0:
		_full = true
	_mutex.unlock()


func dump() -> String:
	_mutex.lock()
	var snapshot_buf := _buf.duplicate()
	var snapshot_head := _head
	var snapshot_full := _full
	_mutex.unlock()
	if snapshot_buf.is_empty():
		return "(no events)"
	var ordered: Array[Dictionary] = []
	if snapshot_full:
		for i in CAPACITY:
			ordered.append(snapshot_buf[(snapshot_head + i) % CAPACITY])
	else:
		ordered = snapshot_buf
	var base_ts: int = ordered[0].ts
	var lines: PackedStringArray = []
	for e in ordered:
		var detail := (" — " + e.detail) if e.detail != "" else ""
		lines.append("  +%5dms [%s]%s" % [e.ts - base_ts, e.tag, detail])
	return "\n".join(lines)


func clear() -> void:
	_mutex.lock()
	_buf.clear()
	_head = 0
	_full = false
	_mutex.unlock()
