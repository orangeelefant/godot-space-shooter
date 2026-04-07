class_name MemoryWatcher
extends RefCounted

const SAMPLE_INTERVAL_S := 5.0
const MEM_LEAK_MB_MIN   := 8.0
const NODE_LEAK_PER_MIN := 100.0

signal memory_leak_detected(rate_mb_per_min: float, current_mb: float)
signal node_leak_detected(rate_per_min: float, current_count: int)

var _timer: float = 0.0
var _samples: Array[Dictionary] = []
const HISTORY := 6


func tick(delta: float, tree: SceneTree) -> void:
	_timer += delta
	if _timer < SAMPLE_INTERVAL_S:
		return
	_timer = 0.0
	var mem_mb := OS.get_static_memory_usage() / 1_000_000.0
	var nodes  := _count_nodes(tree)
	_samples.append({ "ts": Time.get_ticks_msec(), "mem_mb": mem_mb, "nodes": nodes })
	if _samples.size() > HISTORY:
		_samples.pop_front()
	if _samples.size() < 2:
		return
	var span_min := (_samples[-1].ts - _samples[0].ts) / 60_000.0
	if span_min <= 0.0:
		return
	var mem_rate  := (_samples[-1].mem_mb - _samples[0].mem_mb) / span_min
	var node_rate := float(_samples[-1].nodes - _samples[0].nodes) / span_min
	if mem_rate > MEM_LEAK_MB_MIN:
		memory_leak_detected.emit(mem_rate, mem_mb)
	if node_rate > NODE_LEAK_PER_MIN:
		node_leak_detected.emit(node_rate, nodes)


func dump() -> String:
	if _samples.is_empty():
		return "(no samples)"
	var last: Dictionary = _samples[-1]
	return "mem=%.1fMB nodes=%d" % [last.mem_mb, last.nodes]


func _count_nodes(tree: SceneTree) -> int:
	if tree == null or tree.root == null:
		return 0
	return _count_recursive(tree.root)


func _count_recursive(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_recursive(child)
	return count
