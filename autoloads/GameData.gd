extends Node

const GAME_WIDTH := 1920
const GAME_HEIGHT := 1080
const STARTING_LIVES := 3
const MAX_LIVES := 9
const MAX_GAS := 3
const FREEZE_DURATION := 2.0  # seconds

const SHIPS: Array[Dictionary] = [
	{"id": "ruben",      "name": "Ruben",      "color": Color(0.0, 0.8, 1.0),  "speed": 3, "shield": 3, "firepower": 3},
	{"id": "charles",    "name": "Charles",    "color": Color(1.0, 0.4, 0.0),  "speed": 5, "shield": 1, "firepower": 4},
	{"id": "johanna",    "name": "Johanna",    "color": Color(0.6, 0.0, 1.0),  "speed": 2, "shield": 5, "firepower": 2},
	{"id": "christoffer","name": "Christoffer","color": Color(1.0, 0.85, 0.0), "speed": 4, "shield": 2, "firepower": 5},
	{"id": "bernard",    "name": "Bernard",    "color": Color(0.0, 1.0, 0.4),  "speed": 1, "shield": 4, "firepower": 5},
]

const WORLDS: Array[Dictionary] = [
	{
		"id": "world-1", "name": "Rymdens Utkanter",
		"levels": [
			{
				"id": "w1-l1", "name": "Första Kontakten",
				"waves": [
					{"type": "green",  "count": 40, "formation": "swarm", "delay": 0.12},
					{"type": "green",  "count": 60, "formation": "swarm", "delay": 0.08},
				],
				"mission": {"type": "timed", "time_limit": 60}
			},
			{
				"id": "w1-l2", "name": "Svärmen Anländer",
				"waves": [
					{"type": "green",  "count": 80, "formation": "swarm",  "delay": 0.1},
					{"type": "yellow", "count": 10, "formation": "line",   "delay": 0.5},
				],
				"mission": {"type": "timed", "time_limit": 90}
			},
			{
				"id": "w1-l3", "name": "Chefen",
				"waves": [
					{"type": "green",  "count": 50, "formation": "swarm", "delay": 0.1},
					{"type": "yellow", "count": 20, "formation": "v",     "delay": 0.3},
				],
				"mission": {"type": "boss", "boss_type": "standard"}
			},
		]
	},
	{
		"id": "world-2", "name": "Asteroidbältet",
		"levels": [
			{
				"id": "w2-l1", "name": "Stenhavet",
				"waves": [
					{"type": "green",  "count": 80, "formation": "random", "delay": 0.1},
					{"type": "yellow", "count": 20, "formation": "v",      "delay": 0.3},
				],
				"mission": {"type": "timed", "time_limit": 75}
			},
			{
				"id": "w2-l2", "name": "Gula Hotet",
				"waves": [
					{"type": "yellow", "count": 40, "formation": "swarm", "delay": 0.2},
					{"type": "green",  "count": 60, "formation": "swarm", "delay": 0.08},
				],
				"mission": {"type": "timed", "time_limit": 90}
			},
			{
				"id": "w2-l3", "name": "Asteroidchefen",
				"waves": [
					{"type": "yellow", "count": 30, "formation": "v",     "delay": 0.2},
					{"type": "red",    "count": 10, "formation": "line",  "delay": 0.5},
				],
				"mission": {"type": "boss", "boss_type": "standard"}
			},
		]
	},
	{
		"id": "world-3", "name": "Nebulosans Hjärta",
		"levels": [
			{
				"id": "w3-l1", "name": "Gasmoln",
				"waves": [
					{"type": "yellow",    "count": 50, "formation": "swarm",  "delay": 0.15},
					{"type": "invisible", "count": 15, "formation": "random", "delay": 0.4},
				],
				"mission": {"type": "timed", "time_limit": 60}
			},
			{
				"id": "w3-l2", "name": "De Osynliga",
				"waves": [
					{"type": "invisible", "count": 30, "formation": "random", "delay": 0.3},
					{"type": "green",     "count": 60, "formation": "swarm",  "delay": 0.08},
				],
				"mission": {"type": "timed", "time_limit": 90}
			},
			{
				"id": "w3-l3", "name": "Nebulans Väktare",
				"waves": [
					{"type": "invisible", "count": 20, "formation": "random", "delay": 0.3},
					{"type": "red",       "count": 15, "formation": "line",   "delay": 0.4},
				],
				"mission": {"type": "boss", "boss_type": "standard"}
			},
		]
	},
	{
		"id": "world-4", "name": "Isplaneten",
		"levels": [
			{
				"id": "w4-l1", "name": "Frusen Rymd",
				"waves": [
					{"type": "fly",   "count": 60, "formation": "swarm", "delay": 0.1},
					{"type": "green", "count": 40, "formation": "swarm", "delay": 0.1},
				],
				"mission": {"type": "timed", "time_limit": 55}
			},
			{
				"id": "w4-l2", "name": "Flugpesten",
				"waves": [
					{"type": "fly",    "count": 80, "formation": "swarm", "delay": 0.08},
					{"type": "yellow", "count": 20, "formation": "v",     "delay": 0.3},
				],
				"mission": {"type": "timed", "time_limit": 70}
			},
			{
				"id": "w4-l3", "name": "Ischefens Gård",
				"waves": [
					{"type": "fly",  "count": 40, "formation": "swarm", "delay": 0.1},
					{"type": "red",  "count": 20, "formation": "line",  "delay": 0.4},
				],
				"mission": {"type": "boss", "boss_type": "magnet"}
			},
		]
	},
	{
		"id": "world-5", "name": "Korallrevet",
		"levels": [
			{
				"id": "w5-l1", "name": "Djuphavet",
				"waves": [
					{"type": "red",   "count": 30, "formation": "line",  "delay": 0.4},
					{"type": "green", "count": 60, "formation": "swarm", "delay": 0.08},
				],
				"mission": {"type": "timed", "time_limit": 60}
			},
			{
				"id": "w5-l2", "name": "Röda Tidvattnet",
				"waves": [
					{"type": "red",    "count": 50, "formation": "swarm", "delay": 0.2},
					{"type": "yellow", "count": 30, "formation": "v",     "delay": 0.3},
				],
				"mission": {"type": "timed", "time_limit": 80}
			},
			{
				"id": "w5-l3", "name": "Revlords Monark",
				"waves": [
					{"type": "red",  "count": 40, "formation": "line",  "delay": 0.3},
					{"type": "fly",  "count": 30, "formation": "swarm", "delay": 0.1},
				],
				"mission": {"type": "boss", "boss_type": "standard"}
			},
		]
	},
]


func get_ship(ship_id: String) -> Dictionary:
	for ship in SHIPS:
		if ship.id == ship_id:
			return ship
	return SHIPS[0]


func get_level(world_id: String, level_id: String) -> Dictionary:
	for world in WORLDS:
		if world.id == world_id:
			for level in world.levels:
				if level.id == level_id:
					return level
	return WORLDS[0].levels[0]


func is_last_level_in_world(world_id: String, level_id: String) -> bool:
	for world in WORLDS:
		if world.id == world_id:
			var last: Dictionary = world.levels[world.levels.size() - 1]
			return last.id == level_id
	return false


func get_all_level_ids() -> Array[String]:
	var ids: Array[String] = []
	for world in WORLDS:
		for level in world.levels:
			ids.append(level.id)
	return ids
