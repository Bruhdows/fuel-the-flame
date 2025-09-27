extends Node

signal level_up_choices_ready(choices: Array[UpgradeChoice])

var player_level: int = 1
var experience: float = 0.0
var experience_to_next: float = 100.0
var active_upgrades: Array[UpgradeChoice] = []

var all_upgrades: Array[UpgradeChoice] = []

func _ready():
	create_all_upgrades()

func add_experience(amount: float):
	experience += amount
	if experience >= experience_to_next:
		level_up()

func level_up():
	player_level += 1
	experience -= experience_to_next
	experience_to_next *= 1.2  # Scaling XP requirement
	
	var choices = generate_upgrade_choices()
	level_up_choices_ready.emit(choices)

func generate_upgrade_choices() -> Array[UpgradeChoice]:
	var available = all_upgrades.filter(func(upgrade): return can_take_upgrade(upgrade))
	available.shuffle()
	
	var choices: Array[UpgradeChoice] = []
	
	# Ensure variety in choices
	var categories_used = []
	for upgrade in available:
		if choices.size() >= 3:
			break
		if upgrade.category not in categories_used or categories_used.size() >= 3:
			choices.append(upgrade)
			categories_used.append(upgrade.category)
	
	return choices

func can_take_upgrade(upgrade: UpgradeChoice) -> bool:
	# Check if upgrade is already taken (for unique upgrades)
	if upgrade.rarity == "legendary":
		return not active_upgrades.has(upgrade)
	return true

func apply_upgrade(upgrade: UpgradeChoice):
	active_upgrades.append(upgrade)
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	for effect in upgrade.effects:
		apply_effect_to_player(player, effect)

func apply_effect_to_player(player: CharacterBody2D, effect: UpgradeEffect):
	match effect.stat_name:
		"max_health":
			if effect.is_multiplicative:
				player.max_health *= (1.0 + effect.value)
			else:
				player.max_health += effect.value
			player.current_health = min(player.current_health + effect.value, player.max_health)
		"health_regen_rate":
			if effect.is_multiplicative:
				player.health_regen_rate *= (1.0 + effect.value)
			else:
				player.health_regen_rate += effect.value
		"movement_speed":
			# You'll need to add this property to your player
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
		# Add more stat modifications as needed

func create_all_upgrades():
	# COMBAT UPGRADES
	var berserker_rage = UpgradeChoice.new()
	berserker_rage.name = "Berserker's Rage"
	berserker_rage.description = "+50% damage, -10 max health"
	berserker_rage.category = "combat"
	berserker_rage.rarity = "uncommon"
	berserker_rage.add_effect("damage_multiplier", 0.5, true)
	berserker_rage.add_effect("max_health", -10)
	all_upgrades.append(berserker_rage)
	
	var glass_cannon = UpgradeChoice.new()
	glass_cannon.name = "Glass Cannon"
	glass_cannon.description = "+100% damage, -25% max health"
	glass_cannon.category = "combat"
	glass_cannon.rarity = "rare"
	glass_cannon.add_effect("damage_multiplier", 1.0, true)
	glass_cannon.add_effect("max_health", -0.25, true)
	all_upgrades.append(glass_cannon)
	
	var blood_pact = UpgradeChoice.new()
	blood_pact.name = "Blood Pact"
	blood_pact.description = "+25% damage per missing 10% health"
	blood_pact.category = "combat"
	blood_pact.rarity = "rare"
	blood_pact.add_effect("blood_pact", 1.0)  # Special effect handled separately
	all_upgrades.append(blood_pact)
	
	var sharpened_blade = UpgradeChoice.new()
	sharpened_blade.name = "Sharpened Blade"
	sharpened_blade.description = "+20% damage, +15% swing speed"
	sharpened_blade.category = "combat"
	sharpened_blade.rarity = "common"
	sharpened_blade.add_effect("damage_multiplier", 0.2, true)
	sharpened_blade.add_effect("swing_speed", 0.15, true)
	all_upgrades.append(sharpened_blade)
	
	var vampiric_strike = UpgradeChoice.new()
	vampiric_strike.name = "Vampiric Strike"
	vampiric_strike.description = "Heal 15% of damage dealt, -20% max health"
	vampiric_strike.category = "combat"
	vampiric_strike.rarity = "uncommon"
	vampiric_strike.add_effect("lifesteal", 0.15)
	vampiric_strike.add_effect("max_health", -0.2, true)
	all_upgrades.append(vampiric_strike)
	
	# DEFENSE UPGRADES
	var iron_will = UpgradeChoice.new()
	iron_will.name = "Iron Will"
	iron_will.description = "+30 max health, -10% movement speed"
	iron_will.category = "defense"
	iron_will.rarity = "common"
	iron_will.add_effect("max_health", 30)
	iron_will.add_effect("movement_speed", -0.1, true)
	all_upgrades.append(iron_will)
	
	var thorns = UpgradeChoice.new()
	thorns.name = "Thorny Skin"
	thorns.description = "Reflect 50% melee damage, -15 max health"
	thorns.category = "defense"
	thorns.rarity = "uncommon"
	thorns.add_effect("damage_reflection", 0.5)
	thorns.add_effect("max_health", -15)
	all_upgrades.append(thorns)
	
	var stone_skin = UpgradeChoice.new()
	stone_skin.name = "Stone Skin"
	stone_skin.description = "Take 25% less damage, -20% movement speed"
	stone_skin.category = "defense"
	stone_skin.rarity = "uncommon"
	stone_skin.add_effect("damage_reduction", 0.25)
	stone_skin.add_effect("movement_speed", -0.2, true)
	all_upgrades.append(stone_skin)
	
	var regeneration = UpgradeChoice.new()
	regeneration.name = "Regeneration"
	regeneration.description = "+100% health regen, +50% food consumption"
	regeneration.category = "defense"
	regeneration.rarity = "common"
	regeneration.add_effect("health_regen_rate", 1.0, true)
	regeneration.add_effect("food_consumption_rate", 0.5, true)
	all_upgrades.append(regeneration)
	
	# UTILITY UPGRADES
	var swift_feet = UpgradeChoice.new()
	swift_feet.name = "Swift Feet"
	swift_feet.description = "+30% movement speed, +25% food consumption while moving"
	swift_feet.category = "utility"
	swift_feet.rarity = "common"
	swift_feet.add_effect("movement_speed", 0.3, true)
	swift_feet.add_effect("movement_food_decay_rate", 0.25, true)
	all_upgrades.append(swift_feet)
	
	var hunters_instinct = UpgradeChoice.new()
	hunters_instinct.name = "Hunter's Instinct"
	hunters_instinct.description = "See enemies through walls, +20% damage at low health"
	hunters_instinct.category = "utility"
	hunters_instinct.rarity = "uncommon"
	hunters_instinct.add_effect("enemy_vision", 1.0)
	hunters_instinct.add_effect("low_health_damage", 0.2, true)
	all_upgrades.append(hunters_instinct)
	
	var pack_rat = UpgradeChoice.new()
	pack_rat.name = "Pack Rat"
	pack_rat.description = "+3 inventory slots, -15% movement speed"
	pack_rat.category = "utility"
	pack_rat.rarity = "common"
	pack_rat.add_effect("max_inventory_size", 3)
	pack_rat.add_effect("movement_speed", -0.15, true)
	all_upgrades.append(pack_rat)
	
	# CURSED UPGRADES (High risk, high reward)
	var cursed_strength = UpgradeChoice.new()
	cursed_strength.name = "Cursed Strength"
	cursed_strength.description = "+150% damage, health constantly drains"
	cursed_strength.category = "curse"
	cursed_strength.rarity = "legendary"
	cursed_strength.add_effect("damage_multiplier", 1.5, true)
	cursed_strength.add_effect("health_drain", 2.0)  # Drain 2 HP/sec
	all_upgrades.append(cursed_strength)
	
	var glass_heart = UpgradeChoice.new()
	glass_heart.name = "Glass Heart"
	glass_heart.description = "Die in 1 hit, +200% damage, +100% movement speed"
	glass_heart.category = "curse"
	glass_heart.rarity = "legendary"
	glass_heart.add_effect("max_health", 1)  # Set to 1 HP
	glass_heart.add_effect("damage_multiplier", 2.0, true)
	glass_heart.add_effect("movement_speed", 1.0, true)
	all_upgrades.append(glass_heart)
	
	var chaos_magic = UpgradeChoice.new()
	chaos_magic.name = "Chaos Magic"
	chaos_magic.description = "Random stat changes every 30 seconds"
	chaos_magic.category = "curse"
	chaos_magic.rarity = "legendary"
	chaos_magic.add_effect("chaos_timer", 30.0)
	all_upgrades.append(chaos_magic)
	
	# Add 15+ more upgrades with various combinations...
	# FOOD/SURVIVAL UPGRADES
	var glutton = UpgradeChoice.new()
	glutton.name = "Glutton"
	glutton.description = "+50 max food, food items give 50% more, +20% food decay"
	glutton.category = "utility"
	glutton.rarity = "uncommon"
	glutton.add_effect("max_food", 50)
	glutton.add_effect("food_efficiency", 0.5, true)
	glutton.add_effect("food_consumption_rate", 0.2, true)
	all_upgrades.append(glutton)
	
	var survivor = UpgradeChoice.new()
	survivor.name = "Survivor"
	survivor.description = "Can survive at 0 food for 60 seconds, -25% max health"
	survivor.category = "utility"
	survivor.rarity = "rare"
	survivor.add_effect("starvation_immunity", 60.0)
	survivor.add_effect("max_health", -0.25, true)
	all_upgrades.append(survivor)
	
	# Continue adding more upgrades to reach 30+ total...
