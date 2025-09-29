extends Node2D

const ENEMY = preload("uid://wtupsuect0s4")
const TREE = preload("uid://b8p16piq1eels")

@onready var time_label: Label = $GUI/GUIControl/TimeLabel
@onready var wave_label: Label = $GUI/GUIControl/WaveLabel
@onready var player: CharacterBody2D = %Player

var current_wave: int = 1
var enemies_per_wave: int = 5
var enemies_spawned_this_wave: int = 0
var wave_timer: float = 0.0
var wave_duration: float = 30.0
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var game_time: float = 0.0

var current_experience: float = 0.0
var experience_to_next_level: float = 100.0
var current_level: int = 1
var experience_multiplier: float = 1.5

var min_spawn_distance: float = 500.0
var max_spawn_distance: float = 1000.0

var tree_spawn_radius: float = 2500.0
var min_tree_distance_from_player: float = 500.0
var max_trees_in_world: int = 150
var tree_spawn_timer: float = 0.0
var tree_spawn_interval: float = 1.0
var trees_per_spawn_attempt: int = 3
var active_trees: Array[Node2D] = []
var spawned_tree_positions: Array[Vector2] = []
var min_tree_distance: float = 150.0

var active_enemies: Array[Node2D] = []

signal enemy_died(enemy: Node2D, experience_value: float)
signal player_leveled_up(new_level: int)
signal tree_spawned(tree_position: Vector2)

var dropped_item_scene: PackedScene = preload("res://scenes/dropped_item.tscn")

func create_sword_item() -> ItemResource:
	var texture: Texture2D = preload("res://assets/wooden_sword.png")
	var sword: ItemResource = ItemResource.new("Wooden Sword", texture, "An weak wooden sword", 1, "weapon")
	sword.damage = 10
	return sword

func create_wood_item() -> ItemResource:
	var texture: Texture2D = preload("res://assets/wood.png")
	return ItemResource.new("Wood", texture, "", 1)

func _ready() -> void:
	player.add_item(create_sword_item())
	
	update_wave_label()
	update_time_label()
	setup_tree_spawning()
	
	if player.has_signal("experience_gained"):
		player.experience_gained.connect(_on_player_gained_experience)

func setup_tree_spawning() -> void:
	spawn_initial_trees()

func _process(delta: float) -> void:
	game_time += delta
	wave_timer += delta
	spawn_timer += delta
	tree_spawn_timer += delta
	
	update_time_label()
	
	if wave_timer >= wave_duration:
		advance_wave()
	
	if spawn_timer >= spawn_interval and enemies_spawned_this_wave < enemies_per_wave:
		spawn_random_enemy()
		spawn_timer = 0.0
	
	if tree_spawn_timer >= tree_spawn_interval:
		attempt_tree_spawning()
		tree_spawn_timer = 0.0
	
	cleanup_distant_trees()

func spawn_initial_trees() -> void:
	var initial_tree_count: int = 50
	
	for i: int in initial_tree_count:
		var tree_position: Vector2 = get_random_tree_spawn_position()
		if tree_position != Vector2.ZERO:
			spawn_tree_at_position(tree_position)
		await get_tree().process_frame

func attempt_tree_spawning() -> void:
	if active_trees.size() >= max_trees_in_world:
		return
	
	var trees_to_spawn: int = mini(trees_per_spawn_attempt, max_trees_in_world - active_trees.size())
	
	for i: int in trees_to_spawn:
		var tree_position: Vector2 = get_random_tree_spawn_position()
		if tree_position != Vector2.ZERO:
			spawn_tree_at_position(tree_position)

func get_random_tree_spawn_position() -> Vector2:
	var player_pos: Vector2 = player.global_position
	var max_attempts: int = 20
	
	for attempt: int in max_attempts:
		var angle: float = randf() * TAU
		var distance: float = randf_range(min_tree_distance_from_player, tree_spawn_radius)
		var spawn_offset: Vector2 = Vector2.from_angle(angle) * distance
		var potential_position: Vector2 = player_pos + spawn_offset
		
		if is_valid_tree_position(potential_position):
			return potential_position
	
	return Vector2.ZERO

func is_valid_tree_position(position: Vector2) -> bool:
	var distance_to_player: float = position.distance_to(player.global_position)
	if distance_to_player < min_tree_distance_from_player:
		return false
	
	for tree_pos: Vector2 in spawned_tree_positions:
		var distance_to_tree: float = position.distance_to(tree_pos)
		if distance_to_tree < min_tree_distance:
			return false
	
	for enemy: Node2D in active_enemies:
		if is_instance_valid(enemy):
			var distance_to_enemy: float = position.distance_to(enemy.global_position)
			if distance_to_enemy < 100.0:
				return false
	
	return true

func spawn_tree_at_position(position: Vector2) -> void:
	var tree: Node2D = TREE.instantiate()
	tree.global_position = position
	
	active_trees.append(tree)
	spawned_tree_positions.append(position)
	
	setup_tree_properties(tree)
	add_child(tree)
	tree_spawned.emit(position)

func setup_tree_properties(tree: Node2D) -> void:
	tree.add_to_group("trees")
	
	if tree.has_signal("tree_destroyed"):
		tree.tree_destroyed.connect(_on_tree_destroyed)
	
	if tree.has_method("set_tree_variant"):
		var variant: int = randi() % 3
		tree.set_tree_variant(variant)
	
	var scale_variation: float = randf_range(0.8, 1.2)
	tree.scale = Vector2(scale_variation, scale_variation)

func cleanup_distant_trees() -> void:
	var player_pos: Vector2 = player.global_position
	var cleanup_distance: float = tree_spawn_radius + 500.0
	
	for i: int in range(active_trees.size() - 1, -1, -1):
		var tree: Node2D = active_trees[i]
		if not is_instance_valid(tree):
			active_trees.remove_at(i)
			if i < spawned_tree_positions.size():
				spawned_tree_positions.remove_at(i)
			continue
		
		var distance_to_player: float = tree.global_position.distance_to(player_pos)
		if distance_to_player > cleanup_distance:
			remove_tree(i)

func remove_tree(index: int) -> void:
	if index < 0 or index >= active_trees.size():
		return
	
	var tree: Node2D = active_trees[index]
	if is_instance_valid(tree):
		tree.queue_free()
	
	active_trees.remove_at(index)
	if index < spawned_tree_positions.size():
		spawned_tree_positions.remove_at(index)

func _on_tree_destroyed(tree_node: Node2D) -> void:
	var index: int = active_trees.find(tree_node)
	if index != -1:
		add_experience(15.0)
		
		var wood_item: ItemResource = create_wood_item()
		if player.has_method("add_item_at_position"):
			player.add_item_at_position(wood_item, tree_node.global_position)
		
		active_trees.remove_at(index)
		if index < spawned_tree_positions.size():
			spawned_tree_positions.remove_at(index)

func get_random_spawn_position() -> Vector2:
	var player_pos: Vector2 = player.global_position
	var max_attempts: int = 30
	
	for attempt: int in max_attempts:
		var angle: float = randf() * TAU
		var distance: float = randf_range(min_spawn_distance, max_spawn_distance)
		var spawn_offset: Vector2 = Vector2.from_angle(angle) * distance
		var potential_position: Vector2 = player_pos + spawn_offset
		
		var too_close_to_tree: bool = false
		for tree_pos: Vector2 in spawned_tree_positions:
			if potential_position.distance_to(tree_pos) < 150.0:
				too_close_to_tree = true
				break
		
		if not too_close_to_tree:
			return potential_position
	
	var angle: float = randf() * TAU
	var distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	var spawn_offset: Vector2 = Vector2.from_angle(angle) * distance
	return player_pos + spawn_offset

func spawn_random_enemy() -> void:
	if not player:
		return
	
	var spawn_position: Vector2 = get_random_spawn_position()
	var enemy: CharacterBody2D = ENEMY.instantiate()
	enemy.position = spawn_position
	enemy.player = player
	
	var base_exp: float = 25.0
	var wave_multiplier: float = 1.0 + (current_wave - 1) * 0.1
	var enemy_exp_value: float = base_exp * wave_multiplier
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy, enemy_exp_value))
	elif enemy.has_method("set_experience_value"):
		enemy.set_experience_value(enemy_exp_value)
	
	active_enemies.append(enemy)
	add_child(enemy)
	enemies_spawned_this_wave += 1

func _on_enemy_died(enemy_node: Node2D, exp_value: float) -> void:
	if enemy_node in active_enemies:
		active_enemies.erase(enemy_node)
		
	if randf() < 0.2:
		var item_to_drop: ItemResource = create_food_item()
		var dropped_item: DroppedItem = dropped_item_scene.instantiate()
		dropped_item.set_item(item_to_drop)
		dropped_item.global_position = enemy_node.global_position
		get_parent().add_child(dropped_item)
	
	add_experience(exp_value)
	enemy_died.emit(enemy_node, exp_value)

func _on_player_gained_experience(amount: float) -> void:
	add_experience(amount)

func add_experience(amount: float) -> void:
	current_experience += amount
	
	while current_experience >= experience_to_next_level:
		level_up()

func level_up() -> void:
	var overflow_exp: float = current_experience - experience_to_next_level
	
	current_level += 1
	current_experience = overflow_exp
	experience_to_next_level = calculate_experience_requirement(current_level)
	
	player_leveled_up.emit(current_level)
	
	var upgrade_manager: Node = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		upgrade_manager.level_up()

func create_food_item() -> ItemResource:
	var texture: Texture2D = preload("res://assets/rotten.png")
	var item: ItemResource = ItemResource.new("Rotten Beef", texture, "", 1, "food")
	item.food_value = 20
	return item

func calculate_experience_requirement(level: int) -> float:
	var base_exp: float = 100.0
	return base_exp * pow(experience_multiplier, level - 1)

func advance_wave() -> void:
	current_wave += 1
	enemies_spawned_this_wave = 0
	wave_timer = 0.0
	
	enemies_per_wave += 2
	spawn_interval = maxf(0.5, spawn_interval - 0.1)
	
	update_wave_label()
	
	var wave_bonus_exp: float = 50.0 * current_wave
	add_experience(wave_bonus_exp)

func update_wave_label() -> void:
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)

func update_time_label() -> void:
	if time_label:
		var minutes: int = int(game_time) / 60
		var seconds: int = int(game_time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func get_current_level() -> int:
	return current_level

func get_experience_percentage() -> float:
	return current_experience / experience_to_next_level

func get_total_experience() -> float:
	var total: float = current_experience
	for i: int in range(1, current_level):
		total += calculate_experience_requirement(i)
	return total
