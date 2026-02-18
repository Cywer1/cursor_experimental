extends Node

var pool: Array = [
	# --- MICRO ITEMS (Cost 1-4) ---
	{"id": "micro_weld", "name": "Spot Weld", "cost": 1, "description": "Heal 5 HP", "effect_type": "Health", "effect_value": 5.0},
	{"id": "micro_patch", "name": "Patch", "cost": 2, "description": "Heal 10 HP", "effect_type": "Health", "effect_value": 10.0},
	{"id": "micro_grease", "name": "Grease", "cost": 2, "description": "+10 Move Speed", "effect_type": "Speed", "effect_value": 10.0},
	{"id": "micro_spike", "name": "Spike Tip", "cost": 3, "description": "+2 Dash Damage", "effect_type": "Damage", "effect_value": 2.0},
	{"id": "micro_weight", "name": "Lead Weight", "cost": 3, "description": "+25 Knockback Force", "effect_type": "Knockback", "effect_value": 25.0},
	{"id": "micro_vent", "name": "Air Vent", "cost": 4, "description": "+2 Stamina Regen", "effect_type": "Regen", "effect_value": 2.0},

	# --- ECONOMY / LOW TIER (Cost 5-12) ---
	{"id": "health_1", "name": "Repair Kit", "cost": 5, "description": "Heal 25 HP", "effect_type": "Health", "effect_value": 25.0},
	{"id": "damage_1", "name": "Sharpened Edge", "cost": 6, "description": "+5 Dash Damage", "effect_type": "Damage", "effect_value": 5.0},
	{"id": "speed_1", "name": "Lightweight Frame", "cost": 6, "description": "+40 Move Speed", "effect_type": "Speed", "effect_value": 40.0},
	{"id": "knock_1", "name": "Iron Bumper", "cost": 7, "description": "+60 Knockback Force", "effect_type": "Knockback", "effect_value": 60.0},
	{"id": "stamina_1", "name": "Stamina Cell", "cost": 8, "description": "+20 Max Stamina", "effect_type": "Stamina", "effect_value": 20.0},
	{"id": "regen_1", "name": "Cooling Fan", "cost": 9, "description": "+5 Stamina Regen", "effect_type": "Regen", "effect_value": 5.0},
	{"id": "damage_1b", "name": "Serrated Blade", "cost": 10, "description": "+8 Dash Damage", "effect_type": "Damage", "effect_value": 8.0},
	{"id": "health_2", "name": "Med Pack", "cost": 10, "description": "Heal 50 HP", "effect_type": "Health", "effect_value": 50.0},

	# --- MID TIER (Cost 13-24) ---
	{"id": "knock_2", "name": "Hydraulic Ram", "cost": 14, "description": "+120 Knockback Force", "effect_type": "Knockback", "effect_value": 120.0},
	{"id": "damage_2", "name": "Reinforced Core", "cost": 15, "description": "+12 Dash Damage", "effect_type": "Damage", "effect_value": 12.0},
	{"id": "speed_2", "name": "Turbo Modules", "cost": 15, "description": "+80 Move Speed", "effect_type": "Speed", "effect_value": 80.0},
	{"id": "stamina_2", "name": "Power Core", "cost": 16, "description": "+40 Max Stamina", "effect_type": "Stamina", "effect_value": 40.0},
	{"id": "regen_2", "name": "Liquid Cooling", "cost": 18, "description": "+10 Stamina Regen", "effect_type": "Regen", "effect_value": 10.0},
	{"id": "health_3", "name": "Field Surgery", "cost": 20, "description": "Heal 100 HP", "effect_type": "Health", "effect_value": 100.0},

	# --- HIGH TIER (Cost 25+) ---
	{"id": "damage_3", "name": "Overcharged", "cost": 25, "description": "+20 Dash Damage", "effect_type": "Damage", "effect_value": 20.0},
	{"id": "knock_3", "name": "Graviton Ram", "cost": 28, "description": "+250 Knockback Force", "effect_type": "Knockback", "effect_value": 250.0},
	{"id": "speed_3", "name": "Afterburners", "cost": 30, "description": "+150 Move Speed", "effect_type": "Speed", "effect_value": 150.0},
	{"id": "stamina_3", "name": "Infinite Reactor", "cost": 35, "description": "+100 Max Stamina", "effect_type": "Stamina", "effect_value": 100.0},
	{"id": "regen_3", "name": "Cryo-System", "cost": 40, "description": "+20 Stamina Regen", "effect_type": "Regen", "effect_value": 20.0},

	# --- SPECIAL EFFECTS ---
	{"id": "effect_explode_1", "name": "Volatile Core", "cost": 2, "description": "20% Chance for enemies to explode on death (50 Dmg)", "effect_type": "Explosive", "effect_value": 0.2},
	{"id": "effect_explode_2", "name": "Unstable Isotope", "cost": 2, "description": "+20% Explosion Chance", "effect_type": "Explosive", "effect_value": 0.2},
	{"id": "effect_vamp_1", "name": "Leech System", "cost": 2, "description": "5% Chance to heal 2 HP on kill", "effect_type": "Vampire", "effect_value": 0.05},
	{"id": "effect_thorns_1", "name": "Reactive Armor", "cost": 2, "description": "Deal 10 DPS to touching enemies", "effect_type": "Thorns", "effect_value": 10.0},
	{"id": "effect_thorns_2", "name": "Spiked Plating", "cost": 2, "description": "+15 Thorns DPS", "effect_type": "Thorns", "effect_value": 15.0},
]

# Level 2s: only include if player has the corresponding stat > 0
var prerequisites: Dictionary = {
	"effect_thorns_2": "thorns_damage",
	"effect_explode_2": "explosive_chance",
}
# Level 1s: exclude if player already has that stat > 0 (prevent buying twice)
var level1_exclude_if: Dictionary = {
	"effect_explode_1": "explosive_chance",
	"effect_thorns_1": "thorns_damage",
	"effect_vamp_1": "vampire_chance",
}

func _pick_one_from(available: Array) -> Dictionary:
	var idx := randi() % available.size()
	return available[idx]

func _index_of_item_in(arr: Array, item: Dictionary) -> int:
	for i in arr.size():
		if arr[i].id == item.id:
			return i
	return -1

func _meets_prerequisite(item_id: StringName, player: Node) -> bool:
	if not prerequisites.has(item_id):
		return true
	var prop: StringName = prerequisites[item_id]
	var val = player.get(prop)
	if val == null:
		return false
	if val is float:
		return (val as float) > 0.0
	if val is int:
		return (val as int) > 0
	return false

func _should_exclude_level1(item_id: StringName, player: Node) -> bool:
	if not level1_exclude_if.has(item_id):
		return false
	var prop: StringName = level1_exclude_if[item_id]
	var val = player.get(prop)
	if val == null:
		return false
	if val is float:
		return (val as float) > 0.0
	if val is int:
		return (val as int) > 0
	return false

func _build_valid_pool(player: Node) -> Array:
	var valid: Array = []
	for item in pool:
		if _should_exclude_level1(item.id, player):
			continue
		if not _meets_prerequisite(item.id, player):
			continue
		valid.append(item.duplicate())
	return valid

func get_random_upgrades(count: int, player: Node) -> Array:
	var result: Array = []
	var valid_pool := _build_valid_pool(player)
	var remaining: Array = []
	for item in valid_pool:
		remaining.append(item.duplicate())
	var currency: int = player.get("currency") if player.get("currency") != null else 0

	# Slot 1: Guaranteed affordable (cost <= currency), or cheapest if none
	var affordable: Array = []
	for item in remaining:
		if item.cost <= currency:
			affordable.append(item)
	var chosen: Dictionary
	if affordable.size() > 0:
		chosen = _pick_one_from(affordable)
	else:
		remaining.sort_custom(func(a, b): return a.cost < b.cost)
		chosen = remaining[0]
	result.append(chosen)
	var idx := _index_of_item_in(remaining, chosen)
	if idx >= 0:
		remaining.remove_at(idx)

	if count <= 1:
		return result

	# Slot 2: 50% Affordable, 50% Reach Goal (currency to currency + 15)
	if remaining.size() > 0:
		var affordable_s2: Array = []
		var reach_goal: Array = []
		for item in remaining:
			if item.cost <= currency:
				affordable_s2.append(item)
			elif item.cost <= currency + 15:
				reach_goal.append(item)
		if randf() < 0.5 and affordable_s2.size() > 0:
			chosen = _pick_one_from(affordable_s2)
		elif reach_goal.size() > 0:
			chosen = _pick_one_from(reach_goal)
		else:
			chosen = _pick_one_from(remaining)
		result.append(chosen)
		idx = _index_of_item_in(remaining, chosen)
		if idx >= 0:
			remaining.remove_at(idx)

	if count <= 2:
		return result

	# Slot 3: Wildcard — any item from remaining valid pool
	if remaining.size() > 0:
		chosen = _pick_one_from(remaining)
		result.append(chosen)

	return result
