extends Node

signal level_up_choices_ready(choices: Array[UpgradeChoice])

var player_level: int = 1
var experience: float = 0.0
var experience_to_next: float = 100.0
var active_upgrades: Array[UpgradeChoice] = []
var all_upgrades: Array[UpgradeChoice] = []

func _ready() -> void:
	create_all_upgrades()

func add_experience(amount: float) -> void:
	experience += amount
	if experience >= experience_to_next:
		level_up()

func level_up() -> void:
	player_level += 1
	experience -= experience_to_next
	experience_to_next *= 1.2
	
	var choices: Array[UpgradeChoice] = generate_upgrade_choices()
	level_up_choices_ready.emit(choices)

func generate_upgrade_choices() -> Array[UpgradeChoice]:
	var available: Array[UpgradeChoice] = all_upgrades.filter(can_take_upgrade)
	available.shuffle()
	
	var choices: Array[UpgradeChoice] = []
	var categories_used: Array[String] = []
	
	for upgrade: UpgradeChoice in available:
		if choices.size() >= 3:
			break
		if upgrade.category not in categories_used or categories_used.size() >= 3:
			choices.append(upgrade)
			categories_used.append(upgrade.category)
	
	return choices

func can_take_upgrade(upgrade: UpgradeChoice) -> bool:
	return upgrade.rarity != "legendary" or not active_upgrades.has(upgrade)

func apply_upgrade(upgrade: UpgradeChoice) -> void:
	active_upgrades.append(upgrade)
	
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	for effect: UpgradeEffect in upgrade.effects:
		apply_effect_to_player(player, effect)

func apply_effect_to_player(player: CharacterBody2D, effect: UpgradeEffect) -> void:
	match effect.stat_name:
		"max_health":
			if effect.is_multiplicative:
				player.max_health *= (1.0 + effect.value)
			else:
				player.max_health += effect.value
			player.current_health = minf(player.current_health + effect.value, player.max_health)
		"health_regen_rate":
			if effect.is_multiplicative:
				player.health_regen_rate *= (1.0 + effect.value)
			else:
				player.health_regen_rate += effect.value
		"movement_speed":
			if player.has_method("modify_movement_speed"):
				player.modify_movement_speed(effect.value, effect.is_multiplicative)
		"damage_multiplier":
			if player.has_method("modify_damage"):
				player.modify_damage(effect.value, effect.is_multiplicative)
		"max_food":
			if effect.is_multiplicative:
				player.max_food *= (1.0 + effect.value)
			else:
				player.max_food += effect.value

func create_all_upgrades() -> void:
	var upgrades_data: Array[Dictionary] = [
		{"name": "Berserker's Rage", "desc": "+50% damage, -10 max health", "cat": "combat", "rare": "uncommon", "effects": [["damage_multiplier", 0.5, true], ["max_health", -10]]},
		{"name": "Glass Cannon", "desc": "+100% damage, -25% max health", "cat": "combat", "rare": "rare", "effects": [["damage_multiplier", 1.0, true], ["max_health", -0.25, true]]},
		{"name": "Blood Pact", "desc": "+25% damage per missing 10% health", "cat": "combat", "rare": "rare", "effects": [["blood_pact", 1.0]]},
		{"name": "Sharpened Blade", "desc": "+20% damage, +15% swing speed", "cat": "combat", "rare": "common", "effects": [["damage_multiplier", 0.2, true], ["swing_speed", 0.15, true]]},
		{"name": "Vampiric Strike", "desc": "Heal 15% of damage dealt, -20% max health", "cat": "combat", "rare": "uncommon", "effects": [["lifesteal", 0.15], ["max_health", -0.2, true]]},
		{"name": "Iron Will", "desc": "+30 max health, -10% movement speed", "cat": "defense", "rare": "common", "effects": [["max_health", 30], ["movement_speed", -0.1, true]]},
		{"name": "Thorny Skin", "desc": "Reflect 50% melee damage, -15 max health", "cat": "defense", "rare": "uncommon", "effects": [["damage_reflection", 0.5], ["max_health", -15]]},
		{"name": "Stone Skin", "desc": "Take 25% less damage, -20% movement speed", "cat": "defense", "rare": "uncommon", "effects": [["damage_reduction", 0.25], ["movement_speed", -0.2, true]]},
		{"name": "Regeneration", "desc": "+100% health regen, +50% food consumption", "cat": "defense", "rare": "common", "effects": [["health_regen_rate", 1.0, true], ["food_consumption_rate", 0.5, true]]},
		{"name": "Swift Feet", "desc": "+30% movement speed, +25% food consumption while moving", "cat": "utility", "rare": "common", "effects": [["movement_speed", 0.3, true], ["movement_food_decay_rate", 0.25, true]]},
		{"name": "Hunter's Instinct", "desc": "See enemies through walls, +20% damage at low health", "cat": "utility", "rare": "uncommon", "effects": [["enemy_vision", 1.0], ["low_health_damage", 0.2, true]]},
		{"name": "Pack Rat", "desc": "+3 inventory slots, -15% movement speed", "cat": "utility", "rare": "common", "effects": [["max_inventory_size", 3], ["movement_speed", -0.15, true]]},
		{"name": "Cursed Strength", "desc": "+150% damage, health constantly drains", "cat": "curse", "rare": "legendary", "effects": [["damage_multiplier", 1.5, true], ["health_drain", 2.0]]},
		{"name": "Glass Heart", "desc": "Die in 1 hit, +200% damage, +100% movement speed", "cat": "curse", "rare": "legendary", "effects": [["max_health", 1], ["damage_multiplier", 2.0, true], ["movement_speed", 1.0, true]]},
		{"name": "Chaos Magic", "desc": "Random stat changes every 30 seconds", "cat": "curse", "rare": "legendary", "effects": [["chaos_timer", 30.0]]},
		{"name": "Glutton", "desc": "+50 max food, food items give 50% more, +20% food decay", "cat": "utility", "rare": "uncommon", "effects": [["max_food", 50], ["food_efficiency", 0.5, true], ["food_consumption_rate", 0.2, true]]},
		{"name": "Survivor", "desc": "Can survive at 0 food for 60 seconds, -25% max health", "cat": "utility", "rare": "rare", "effects": [["starvation_immunity", 60.0], ["max_health", -0.25, true]]},
	]
	
	for data: Dictionary in upgrades_data:
		var upgrade: UpgradeChoice = UpgradeChoice.new()
		upgrade.name = data.name
		upgrade.description = data.desc
		upgrade.category = data.cat
		upgrade.rarity = data.rare
		
		for effect_data: Array in data.effects:
			var is_mult: bool = effect_data.size() > 2 and effect_data[2]
			upgrade.add_effect(effect_data[0], effect_data[1], is_mult)
		
		all_upgrades.append(upgrade)
