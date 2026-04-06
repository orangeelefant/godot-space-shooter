extends Node

signal combo_changed(combo: int, multiplier: int)
signal combo_lost

const COMBO_WINDOW := 1.5

var _combo: int = 0
var _timer: float = 0.0
var _active: bool = false


func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		if _combo > 0:
			_combo = 0
			_active = false
			combo_lost.emit()


func register_kill() -> int:
	_combo += 1
	_timer = COMBO_WINDOW
	_active = true
	var mult := _get_multiplier()
	combo_changed.emit(_combo, mult)
	return 10 * mult


func reset() -> void:
	_combo = 0
	_active = false
	_timer = 0.0


func get_combo() -> int:
	return _combo


func _get_multiplier() -> int:
	if _combo >= 20:
		return 5
	elif _combo >= 10:
		return 3
	elif _combo >= 5:
		return 2
	return 1
