class_name EventBuffer
extends RefCounted

const CAPACITY := 64

var _buf: Array[Dictionary] = []
var _head: int = 0
var _full: bool = false


func record(tag: String, detail: String = "") -> void:
    var entry := { "ts": Time.get_ticks_msec(), "tag": tag, "detail": detail }
    if _full:
        _buf[_head] = entry
    else:
        _buf.append(entry)
    _head = (_head + 1) % CAPACITY
    if _head == 0:
        _full = true


func dump() -> String:
    if _buf.is_empty():
        return "(no events)"
    var ordered: Array[Dictionary] = []
    if _full:
        for i in CAPACITY:
            ordered.append(_buf[(_head + i) % CAPACITY])
    else:
        ordered = _buf.duplicate()
    var base_ts: int = ordered[0].ts
    var lines: PackedStringArray = []
    for e in ordered:
        var detail := (" — " + e.detail) if e.detail != "" else ""
        lines.append("  +%5dms [%s]%s" % [e.ts - base_ts, e.tag, detail])
    return "\n".join(lines)


func clear() -> void:
    _buf.clear()
    _head = 0
    _full = false
