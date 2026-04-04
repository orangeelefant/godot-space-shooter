extends Node

const SAVE_PATH := "user://save.json"

const DEFAULT_STATE := {
	"ship_id": "ruben",
	"lives": 3,
	"coins": 0,
	"gas_grenades": 3,
	"upgrades": {
		"cannon_level": "enkel",
		"motor_level": 1,
		"shield_level": 1,
		"scanner_level": 0,
		"falcon_level": 1,
	},
	"completed_levels": [],
}


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return DEFAULT_STATE.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_STATE.duplicate(true)
	var text := file.get_as_text()
	file.close()
	var result := JSON.parse_string(text)
	if result == null or not result is Dictionary:
		return DEFAULT_STATE.duplicate(true)
	# Merge with defaults to handle missing keys
	var state: Dictionary = DEFAULT_STATE.duplicate(true)
	state.merge(result, true)
	return state


func save_game(state: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing")
		return
	file.store_string(JSON.stringify(state, "\t"))
	file.close()


func mark_level_complete(level_id: String) -> void:
	var state := load_game()
	var completed: Array = state.get("completed_levels", [])
	if not level_id in completed:
		completed.append(level_id)
		state["completed_levels"] = completed
		save_game(state)


func is_level_complete(level_id: String) -> bool:
	var state := load_game()
	var completed: Array = state.get("completed_levels", [])
	return level_id in completed


func is_world_unlocked(world_id: String) -> bool:
	if world_id == "world-1":
		return true
	for world in GameData.WORLDS:
		if world.id == world_id:
			var unlock_after: String = world.get("unlock_after", "")
			if unlock_after == "":
				return true
			# World unlocked when all levels of preceding world complete
			for prev_world in GameData.WORLDS:
				if prev_world.id == unlock_after:
					for level in prev_world.levels:
						if not is_level_complete(level.id):
							return false
					return true
	return false


func add_coins(amount: int) -> void:
	var state := load_game()
	state["coins"] = int(state.get("coins", 0)) + amount
	save_game(state)


func reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
