extends Node

var pool: Array = [
	{"id": "health_1", "name": "Repair Kit", "cost": 5, "description": "Heal 25 HP", "effect_type": "Health", "effect_value": 25.0},
	{"id": "health_2", "name": "Med Pack", "cost": 10, "description": "Heal 50 HP", "effect_type": "Health", "effect_value": 50.0},
	{"id": "health_3", "name": "Field Surgery", "cost": 20, "description": "Heal 100 HP", "effect_type": "Health", "effect_value": 100.0},
	{"id": "damage_1", "name": "Sharpened Edge", "cost": 8, "description": "+5 Dash Damage", "effect_type": "Damage", "effect_value": 5.0},
	{"id": "damage_2", "name": "Reinforced Core", "cost": 15, "description": "+10 Dash Damage", "effect_type": "Damage", "effect_value": 10.0},
	{"id": "damage_3", "name": "Overcharged", "cost": 25, "description": "+15 Dash Damage", "effect_type": "Damage", "effect_value": 15.0},
	{"id": "speed_1", "name": "Lightweight Frame", "cost": 8, "description": "+50 Move Speed", "effect_type": "Speed", "effect_value": 50.0},
	{"id": "speed_2", "name": "Boost Modules", "cost": 15, "description": "+100 Move Speed", "effect_type": "Speed", "effect_value": 100.0},
	{"id": "speed_3", "name": "Afterburners", "cost": 25, "description": "+150 Move Speed", "effect_type": "Speed", "effect_value": 150.0},
	{"id": "stamina_1", "name": "Stamina Cell", "cost": 8, "description": "+25 Max Stamina", "effect_type": "Stamina", "effect_value": 25.0},
	{"id": "stamina_2", "name": "Power Core", "cost": 15, "description": "+50 Max Stamina", "effect_type": "Stamina", "effect_value": 50.0},
	{"id": "stamina_3", "name": "Infinite Reactor", "cost": 25, "description": "+100 Max Stamina", "effect_type": "Stamina", "effect_value": 100.0},
]

func get_random_upgrades(count: int) -> Array:
	var available := pool.duplicate()
	var result: Array = []
	for i in min(count, available.size()):
		var idx := randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)
	return result
