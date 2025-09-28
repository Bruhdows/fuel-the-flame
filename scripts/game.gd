extends Node2D

const ENEMY = preload("uid://wtupsuect0s4")
const TREE = preload("uid://b8p16piq1eels")

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

# Tree spawning system
var tree_spawn_radius: float = 50.0 * 50  # 50 blocks radius around player
var min_tree_distance_from_player: float = 10.0 * 50  # 10 blocks minimum distance
var max_trees_in_world: int = 150  # Maximum trees at once
var tree_spawn_timer: float = 0.0
var tree_spawn_interval: float = 1.0  # Try to spawn tree every second
var trees_per_spawn_attempt: int = 3  # Attempt to spawn 3 trees per interval
var active_trees: Array = []
var spawned_tree_positions: Array = []  # Track tree positions to avoid overlap
var min_tree_distance: float = 3.0 * 50  # Minimum 3 blocks between trees

# Enemy tracking for experience
var active_enemies: Array = []

signal enemy_died(enemy, experience_value)
signal player_leveled_up(new_level)
signal tree_spawned(tree_position)

var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

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
	
	# Initialize tree spawning
	setup_tree_spawning()
	
	# Connect player signals if available
	if player.has_signal("experience_gained"):
		player.experience_gained.connect(_on_player_gained_experience)

func setup_tree_spawning():
	"""Initialize the tree spawning system"""
	# Spawn initial trees around the player
	spawn_initial_trees()

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
	tree_spawn_timer += delta
	
	# Update UI
	update_time_label()
	
	# Check if wave should advance
	if wave_timer >= wave_duration:
		advance_wave()
	
	# Spawn enemies during wave
	if spawn_timer >= spawn_interval and enemies_spawned_this_wave < enemies_per_wave:
		spawn_random_enemy()
		spawn_timer = 0.0
	
	# Handle tree spawning
	if tree_spawn_timer >= tree_spawn_interval:
		attempt_tree_spawning()
		tree_spawn_timer = 0.0
	
	# Clean up distant trees to maintain performance
	cleanup_distant_trees()

func spawn_initial_trees():
	"""Spawn initial trees around the player when the game starts"""
	var initial_tree_count = 50  # Spawn 50 trees initially
	
	for i in initial_tree_count:
		var tree_position = get_random_tree_spawn_position()
		if tree_position != Vector2.ZERO:  # Valid position found
			spawn_tree_at_position(tree_position)
		
		# Small delay to spread out spawning
		await get_tree().process_frame

func attempt_tree_spawning():
	"""Attempt to spawn new trees if below maximum count"""
	if active_trees.size() >= max_trees_in_world:
		return
	
	var trees_to_spawn = min(trees_per_spawn_attempt, max_trees_in_world - active_trees.size())
	
	for i in trees_to_spawn:
		var tree_position = get_random_tree_spawn_position()
		if tree_position != Vector2.ZERO:  # Valid position found
			spawn_tree_at_position(tree_position)

func get_random_tree_spawn_position() -> Vector2:
	"""Get a random valid position for tree spawning"""
	var player_pos = player.global_position
	var max_attempts = 20  # Prevent infinite loops
	
	for attempt in max_attempts:
		# Generate random angle (0 to 2π radians)
		var angle = randf() * TAU
		
		# Generate random distance between min distance and spawn radius
		var distance = randf_range(min_tree_distance_from_player, tree_spawn_radius)
		
		# Calculate potential spawn position
		var spawn_offset = Vector2.from_angle(angle) * distance
		var potential_position = player_pos + spawn_offset
		
		# Check if position is valid (not too close to other trees)
		if is_valid_tree_position(potential_position):
			return potential_position
	
	# Return zero vector if no valid position found
	return Vector2.ZERO

func is_valid_tree_position(position: Vector2) -> bool:
	"""Check if a position is valid for tree spawning"""
	# Check distance from player
	var distance_to_player = position.distance_to(player.global_position)
	if distance_to_player < min_tree_distance_from_player:
		return false
	
	# Check distance from existing trees
	for tree_pos in spawned_tree_positions:
		var distance_to_tree = position.distance_to(tree_pos)
		if distance_to_tree < min_tree_distance:
			return false
	
	# Check distance from active enemies (optional - prevents spawning too close to enemies)
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var distance_to_enemy = position.distance_to(enemy.global_position)
			if distance_to_enemy < 2.0 * 50:  # 2 blocks minimum from enemies
				return false
	
	return true

func spawn_tree_at_position(position: Vector2):
	"""Spawn a tree at the specified position"""
	var tree = TREE.instantiate()
	tree.global_position = position
	
	# Add tree to tracking arrays
	active_trees.append(tree)
	spawned_tree_positions.append(position)
	
	# Set up tree properties if needed
	setup_tree_properties(tree)
	
	# Add to scene
	add_child(tree)
	
	# Emit signal for other systems
	tree_spawned.emit(position)
	
	print("Tree spawned at: ", position)

func setup_tree_properties(tree: Node):
	"""Configure tree properties and connections"""
	# Add tree to a group for easy management
	tree.add_to_group("trees")
	
	# Connect tree destruction signal if available
	if tree.has_signal("tree_destroyed"):
		tree.tree_destroyed.connect(_on_tree_destroyed)
	
	# Set random tree variant if your tree scene supports it
	if tree.has_method("set_tree_variant"):
		var variant = randi() % 3  # Assuming 3 tree variants
		tree.set_tree_variant(variant)
	
	# Random scale variation for visual diversity
	var scale_variation = randf_range(0.8, 1.2)
	tree.scale = Vector2(scale_variation, scale_variation)

func cleanup_distant_trees():
	"""Remove trees that are too far from the player to maintain performance"""
	var player_pos = player.global_position
	var cleanup_distance = tree_spawn_radius + 10.0 * 50  # Extra buffer
	
	for i in range(active_trees.size() - 1, -1, -1):  # Iterate backwards
		var tree = active_trees[i]
		if not is_instance_valid(tree):
			# Remove invalid tree references
			active_trees.remove_at(i)
			if i < spawned_tree_positions.size():
				spawned_tree_positions.remove_at(i)
			continue
		
		var distance_to_player = tree.global_position.distance_to(player_pos)
		if distance_to_player > cleanup_distance:
			# Remove distant tree
			remove_tree(i)

func remove_tree(index: int):
	"""Remove a tree by index"""
	if index < 0 or index >= active_trees.size():
		return
	
	var tree = active_trees[index]
	if is_instance_valid(tree):
		tree.queue_free()
	
	active_trees.remove_at(index)
	if index < spawned_tree_positions.size():
		spawned_tree_positions.remove_at(index)

func _on_tree_destroyed(tree_node: Node):
	"""Handle when a tree is destroyed (e.g., by player chopping)"""
	var index = active_trees.find(tree_node)
	if index != -1:
		# Award experience for chopping tree
		add_experience(15.0)  # 15 XP for chopping a tree
		
		# Drop wood item
		var wood_item = create_wood_item()
		if player.has_method("add_item_at_position"):
			player.add_item_at_position(wood_item, tree_node.global_position)
		
		# Remove from tracking
		active_trees.remove_at(index)
		if index < spawned_tree_positions.size():
			spawned_tree_positions.remove_at(index)
		
		print("Tree destroyed! Gained wood and experience.")

# Enhanced spawn method that considers tree positions
func get_random_spawn_position() -> Vector2:
	"""Get a random position around the player at minimum distance, avoiding trees"""
	var player_pos = player.global_position
	var max_attempts = 30  # More attempts to avoid trees
	
	for attempt in max_attempts:
		# Generate random angle (0 to 2π radians)
		var angle = randf() * TAU
		
		# Generate random distance between min and max spawn distance
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		
		# Calculate spawn position using polar coordinates
		var spawn_offset = Vector2.from_angle(angle) * distance
		var potential_position = player_pos + spawn_offset
		
		# Check if position is not too close to trees
		var too_close_to_tree = false
		for tree_pos in spawned_tree_positions:
			if potential_position.distance_to(tree_pos) < 3.0 * 50:  # 3 blocks from trees
				too_close_to_tree = true
				break
		
		if not too_close_to_tree:
			return potential_position
	
	# Fallback to original method if no clear space found
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	var spawn_offset = Vector2.from_angle(angle) * distance
	return player_pos + spawn_offset

# Additional tree management methods
func get_trees_near_position(position: Vector2, radius: float) -> Array:
	"""Get all trees within a certain radius of a position"""
	var nearby_trees = []
	for tree in active_trees:
		if is_instance_valid(tree):
			if tree.global_position.distance_to(position) <= radius:
				nearby_trees.append(tree)
	return nearby_trees

func clear_trees_in_area(position: Vector2, radius: float):
	"""Clear all trees in a specific area (useful for building/events)"""
	var trees_to_remove = get_trees_near_position(position, radius)
	for tree in trees_to_remove:
		var index = active_trees.find(tree)
		if index != -1:
			remove_tree(index)

func get_tree_count() -> int:
	"""Get current number of active trees"""
	return active_trees.size()

# Keep all your existing methods unchanged below this line
func spawn_random_enemy() -> void:
	if not player:
		return
	
	var spawn_position = get_random_spawn_position()
	var enemy = ENEMY.instantiate()
	enemy.position = spawn_position
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
	
	# Check for 	var item_to_drop = create_food_item()
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
		var enemy = ENEMY.instantiate()
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
	
	# Debug: Press T to spawn tree manually
	if event.is_action_pressed("ui_select"):  # Change to any debug key
		var tree_pos = get_random_tree_spawn_position()
		if tree_pos != Vector2.ZERO:
			spawn_tree_at_position(tree_pos)

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
