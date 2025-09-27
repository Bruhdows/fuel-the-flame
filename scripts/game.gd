extends Node2D
const ENEMY = preload("uid://wtupsuect0s4")


@onready var time_label: Label = $GUI/GUIControl/TimeLabel
@onready var wave_label: Label = $GUI/GUIControl/WaveLabel
@onready var player: CharacterBody2D = %Player
@onready var level_bar: ProgressBar = %LevelBar

# Wave and timer system
var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var wave_timer: float = 0.0
var wave_duration: float = 30.0  # 30 seconds per wave
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0  # Spawn enemy every 2 seconds
var game_time: float = 0.0

# Experience and leveling system
var current_experience: float = 0.0
var experience_to_next_level: float = 100.0
var current_level: int = 1
var experience_multiplier: float = 1.5  # XP requirement multiplier per level

# Spawn configuration
var min_spawn_distance: float = 10.0 * 50  # 20 blocks * 50 pixels per block
var max_spawn_distance: float = 20.0 * 50  # 30 blocks * 50 pixels per block

# Enemy tracking for experience
var active_enemies: Array = []

signal enemy_died(enemy, experience_value)
signal player_leveled_up(new_level)

func create_sword_item() -> ItemResource:
	var texture = preload("res://assets/wooden_sword.png")
	return ItemResource.new("Wooden Sword", texture, "An weak wooden sword", 1, "weapon")

func create_wood_item() -> ItemResource:
	var texture = preload("res://assets/wood.png")
	return ItemResource.new("Wood", texture, "", 1)

func _ready() -> void:
	var sword = create_sword_item()
	sword.damage = 10
	player.add_item(sword)
	
	# Initialize wave system
	update_wave_label()
	update_time_label()
	
	# Initialize experience system
	setup_experience_system()
	
	# Connect player signals if available
	if player.has_signal("experience_gained"):
		player.experience_gained.connect(_on_player_gained_experience)

func setup_experience_system():
	# Set up the level bar
	if level_bar:
		level_bar.min_value = 0
		level_bar.max_value = 100  # We'll use percentage
		level_bar.value = 0
		level_bar.show_percentage = false
	
	# Update level display
	update_experience_bar()

func _process(delta: float) -> void:
	# Update game time
	game_time += delta
	wave_timer += delta
	spawn_timer += delta
	
	# Update UI
	update_time_label()
	
	# Check if wave should advance
	if wave_timer >= wave_duration:
		advance_wave()
	
	# Spawn enemies during wave
	if spawn_timer >= spawn_interval and enemies_spawned_this_wave < enemies_per_wave:
		spawn_random_enemy()
		spawn_timer = 0.0

func spawn_random_enemy() -> void:
	if not player:
		return
	
	var spawn_position = get_random_spawn_position()
	var enemy = ENEMY.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	enemy.global_position = spawn_position
	enemy.player = player
	
	# Set up enemy experience value based on wave
	var base_exp = 25.0
	var wave_multiplier = 1.0 + (current_wave - 1) * 0.1  # 10% more exp per wave
	var enemy_exp_value = base_exp * wave_multiplier
	
	# Connect enemy death signal for experience
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy, enemy_exp_value))
	elif enemy.has_method("set_experience_value"):
		enemy.set_experience_value(enemy_exp_value)
	
	# Track active enemies
	active_enemies.append(enemy)
	
	add_child(enemy)
	enemies_spawned_this_wave += 1

func _on_enemy_died(enemy_node: Node, exp_value: float):
	# Remove from active enemies list
	if enemy_node in active_enemies:
		active_enemies.erase(enemy_node)
	
	# Award experience to player
	add_experience(exp_value)
	
	# Emit signal for any other systems that need to know
	enemy_died.emit(enemy_node, exp_value)
	
	print("Enemy died! Gained ", exp_value, " experience")

func _on_player_gained_experience(amount: float):
	add_experience(amount)

func add_experience(amount: float):
	current_experience += amount
	
	# Check for level up
	while current_experience >= experience_to_next_level:
		level_up()
	
	# Update the experience bar
	update_experience_bar()
	
	print("Current XP: ", current_experience, "/", experience_to_next_level)

func level_up():
	# Calculate overflow experience
	var overflow_exp = current_experience - experience_to_next_level
	
	# Level up
	current_level += 1
	current_experience = overflow_exp
	
	# Calculate new experience requirement
	experience_to_next_level = calculate_experience_requirement(current_level)
	
	# Update UI
	update_experience_bar()
	
	# Emit level up signal
	player_leveled_up.emit(current_level)
	
	# Trigger upgrade choices (connect to your upgrade manager)
	var upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		upgrade_manager.level_up()
	
	print("LEVEL UP! Now level ", current_level)
	print("Next level requires: ", experience_to_next_level, " XP")

func calculate_experience_requirement(level: int) -> float:
	# Formula: base_exp * (multiplier ^ (level - 1))
	# Example: Level 1->2: 100, Level 2->3: 150, Level 3->4: 225, etc.
	var base_exp = 100.0
	return base_exp * pow(experience_multiplier, level - 1)

func update_experience_bar():
	if level_bar:
		var experience_percentage = (current_experience / experience_to_next_level) * 100.0
		
		# Animate the progress bar smoothly
		var tween = create_tween()
		tween.tween_property(level_bar, "value", experience_percentage, 0.3)
		
		# Optional: Add a tooltip or label showing exact numbers
		level_bar.tooltip_text = str(int(current_experience)) + " / " + str(int(experience_to_next_level)) + " XP"

func get_random_spawn_position() -> Vector2:
	"""Get a random position around the player at minimum distance of 20 blocks"""
	var player_pos = player.global_position
	
	# Generate random angle (0 to 2π radians)
	var angle = randf() * TAU
	
	# Generate random distance between min and max spawn distance
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	
	# Calculate spawn position using polar coordinates
	var spawn_offset = Vector2.from_angle(angle) * distance
	return player_pos + spawn_offset

func advance_wave() -> void:
	current_wave += 1
	enemies_spawned_this_wave = 0
	wave_timer = 0.0
	
	# Increase difficulty each wave
	enemies_per_wave += 2  # 2 more enemies per wave
	spawn_interval = max(0.5, spawn_interval - 0.1)  # Faster spawning, minimum 0.5 seconds
	
	update_wave_label()
	
	# Award bonus experience for surviving a wave
	var wave_bonus_exp = 50.0 * current_wave
	add_experience(wave_bonus_exp)
	
	print("Wave ", current_wave, " started! Bonus XP: ", wave_bonus_exp)

func update_wave_label() -> void:
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)

func update_time_label() -> void:
	if time_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

# Alternative spawn method for spawning in a ring around player
func get_random_ring_spawn_position(inner_radius: float = 1000.0, outer_radius: float = 1500.0) -> Vector2:
	"""Spawn in a ring around the player for more controlled spawning"""
	var player_pos = player.global_position
	
	# Random angle
	var angle = randf() * TAU
	
	# Random distance in ring
	var distance = randf_range(inner_radius, outer_radius)
	
	# Calculate position
	var spawn_offset = Vector2.from_angle(angle) * distance
	return player_pos + spawn_offset

# Method to spawn multiple enemies at once (for wave start)
func spawn_wave_enemies() -> void:
	for i in enemies_per_wave:
		var spawn_position = get_random_spawn_position()
		var enemy = ENEMY.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		enemy.global_position = spawn_position
		enemy.player = player
		
		# Set up experience for this enemy
		var base_exp = 25.0
		var wave_multiplier = 1.0 + (current_wave - 1) * 0.1
		var enemy_exp_value = base_exp * wave_multiplier
		
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died.bind(enemy, enemy_exp_value))
		
		active_enemies.append(enemy)
		add_child(enemy)
		
		# Add small delay between spawns to avoid all spawning at once
		await get_tree().create_timer(0.2).timeout
	
	enemies_spawned_this_wave = enemies_per_wave

# Method to clear all enemies (useful for wave transitions)
func clear_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")  # Assumes enemies are in "enemies" group
	for enemy in enemies:
		if enemy in active_enemies:
			active_enemies.erase(enemy)
		enemy.queue_free()

# Debug functions
func add_debug_experience(amount: float = 50.0):
	"""Call this function to test experience gain"""
	add_experience(amount)

func _input(event):
	# Debug: Press X to gain experience (remove this in final game)
	if event.is_action_pressed("ui_accept"):  # Change to any debug key
		add_debug_experience(25.0)

# Getters for other systems
func get_current_level() -> int:
	return current_level

func get_experience_percentage() -> float:
	return (current_experience / experience_to_next_level)

func get_total_experience() -> float:
	# Calculate total experience gained across all levels
	var total = current_experience
	for i in range(1, current_level):
		total += calculate_experience_requirement(i)
	return total
