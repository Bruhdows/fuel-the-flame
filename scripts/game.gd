extends Node2D

const ENEMY = preload("uid://bgdracsuhgysh")

@onready var time_label: Label = $GUI/GUIControl/TimeLabel
@onready var wave_label: Label = $GUI/GUIControl/WaveLabel
@onready var player: CharacterBody2D = %Player

# Wave and timer system
var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var wave_timer: float = 0.0
var wave_duration: float = 30.0  # 30 seconds per wave
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0  # Spawn enemy every 2 seconds
var game_time: float = 0.0

# Spawn configuration
var min_spawn_distance: float = 10.0 * 50  # 20 blocks * 50 pixels per block
var max_spawn_distance: float = 20.0 * 50  # 30 blocks * 50 pixels per block

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
	add_child(enemy)
	
	enemies_spawned_this_wave += 1

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
	
	# Optional: Show wave notification
	print("Wave ", current_wave, " started!")

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
		add_child(enemy)
		
		# Add small delay between spawns to avoid all spawning at once
		await get_tree().create_timer(0.2).timeout
	
	enemies_spawned_this_wave = enemies_per_wave

# Method to clear all enemies (useful for wave transitions)
func clear_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")  # Assumes enemies are in "enemies" group
	for enemy in enemies:
		enemy.queue_free()
