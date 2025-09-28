extends CharacterBody2D

@onready var fire: StaticBody2D = $"../Fire"

var inventory = []
var max_inventory_size = 5
var selected_slot = 0

# Base Health and Food system
var base_max_health = 100.0
var base_max_food = 100.0
var base_health_regen_rate = 10.0
var base_food_consumption_rate = 5.0
var base_movement_food_decay_rate = 0.5

# Current Health and Food system (modified by upgrades)
var max_health = 100.0
var current_health = 100.0
var max_food = 100.0
var current_food = 100.0
var health_regen_rate = 10.0
var food_consumption_rate = 5.0
var movement_food_decay_rate = 0.5
var is_moving = false
var elapsed_time: float = 0.0

# Base movement and combat stats
var base_movement_speed = 400.0
var base_swing_duration = 0.3
var base_damage = 25.0

# Current movement and combat stats (modified by upgrades)
var movement_speed = 400.0
var swing_duration = 0.3
var damage_multiplier = 1.0
var swing_speed_multiplier = 1.0
var movement_speed_multiplier = 1.0

# Upgrade effects
var damage_reduction = 0.0
var lifesteal = 0.0
var damage_reflection = 0.0
var health_drain_rate = 0.0
var food_efficiency_multiplier = 1.0
var starvation_immunity_time = 0.0
var starvation_timer = 0.0

# Special upgrade flags
var has_blood_pact = false
var has_chaos_magic = false
var has_enemy_vision = false
var chaos_timer = 0.0
var chaos_interval = 30.0

# Item holding system
var held_item_sprite: Sprite2D
var is_swinging = false
var swing_timer = 0.0
var original_held_item_rotation = 0.0

# Experience system
var experience = 0.0
var player_level = 1

@onready var health_bar: ProgressBar = %HealthBar
@onready var food_bar: ProgressBar = %FoodBar

signal inventory_changed
signal slot_selected(slot_index: int)
signal health_changed(new_health: float)
signal food_changed(new_food: float)
signal player_died
signal experience_gained(amount: float)
signal level_up(new_level: int)

var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

func _ready():
	setup_held_item_sprite()
	update_health_bar()
	update_food_bar()
	update_held_item_display()
	
	# Connect to upgrade manager if it exists
	var upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		upgrade_manager.level_up_choices_ready.connect(_on_level_up_choices)

func _on_level_up_choices(choices):
	# Pause game when level up choices appear
	get_tree().paused = true

func setup_held_item_sprite():
	held_item_sprite = Sprite2D.new()
	held_item_sprite.position = Vector2(0, 0)
	held_item_sprite.scale = Vector2(3, 3)
	held_item_sprite.z_index = 1
	add_child(held_item_sprite)

func _process(delta: float) -> void:
	elapsed_time += delta

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * movement_speed * movement_speed_multiplier
	
	is_moving = input_direction.length() > 0
	
	handle_slot_selection()
	
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()
	
	if Input.is_action_just_pressed("swing") and not is_swinging:
		swing_item()

func handle_slot_selection():
	for i in range(min(5, max_inventory_size)):
		if Input.is_action_just_pressed("slot_" + str(i + 1)):
			selected_slot = i
			slot_selected.emit(i)
			update_held_item_display()
	
	if Input.is_action_just_pressed("drop_item"):
		drop_selected_item()

func _physics_process(delta):
	get_input()
	move_and_slide()
	
	handle_food_decay(delta)
	handle_health_regeneration(delta)
	handle_swing_animation(delta)
	update_held_item_position()
	
	# Handle upgrade-specific effects
	handle_health_drain(delta)
	handle_chaos_magic(delta)
	handle_starvation_immunity(delta)

func handle_swing_animation(delta):
	if is_swinging:
		swing_timer += delta
		var current_swing_duration = swing_duration / swing_speed_multiplier
		var progress = swing_timer / current_swing_duration
		
		if progress >= 1.0:
			is_swinging = false
			swing_timer = 0.0
			held_item_sprite.rotation = original_held_item_rotation
		else:
			var swing_angle = sin(progress * PI) * PI/4  # 45 degrees max
			held_item_sprite.rotation = original_held_item_rotation + swing_angle

func update_held_item_position():
	if held_item_sprite:
		var mouse_pos = get_global_mouse_position()
		var direction = (mouse_pos - global_position).normalized()
		var angle = direction.angle()
		
		if not is_swinging:
			held_item_sprite.rotation = angle
			original_held_item_rotation = angle
		
		held_item_sprite.position = direction * 32

func update_held_item_display():
	if held_item_sprite:
		var current_item = get_selected_item()
		if current_item and current_item.texture:
			held_item_sprite.texture = current_item.texture
			held_item_sprite.visible = true
		else:
			held_item_sprite.visible = false

func get_selected_item() -> ItemResource:
	if selected_slot < inventory.size() and inventory[selected_slot]:
		return inventory[selected_slot]
	return null

func swing_item():
	var current_item = get_selected_item()
	if current_item and current_item.has_method("is_weapon") and current_item.is_weapon():
		is_swinging = true
		swing_timer = 0.0
		print("Swinging ", current_item.name, "!")
		
		check_swing_damage()
		check_tree_damage()
		
func check_swing_damage():
	var space_state = get_world_2d().direct_space_state
	var swing_range = 48.0
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = swing_range
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position + direction * swing_range * 0.5)
	query.collision_mask = 4  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			var current_item = get_selected_item()
			var base_damage = base_damage
			if current_item and current_item.has_method("get_damage"):
				base_damage = current_item.get_damage()
			
			# Apply all damage modifiers
			var final_damage = calculate_final_damage(base_damage)
			body.take_damage(final_damage)
			
			# Apply lifesteal
			if lifesteal > 0:
				heal(final_damage * lifesteal)
			
			print("Hit enemy for ", final_damage, " damage!")
			
			# Add experience for hitting enemies
			add_experience(10)

func check_tree_damage():
	var swing_range = 96.0
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		if tree and is_instance_valid(tree):
			var distance = global_position.distance_to(tree.global_position)
			if distance <= swing_range:
				var tree_direction = (tree.global_position - global_position).normalized()
				var dot_product = direction.dot(tree_direction)
				
				if dot_product > 0.5:
					var current_item = get_selected_item()
					var base_damage = 15.0
					if current_item and current_item.has_method("get_damage"):
						base_damage = current_item.get_damage() * 0.6
					
					var final_damage = calculate_final_damage(base_damage)
					
					if tree.has_method("take_damage"):
						tree.take_damage(final_damage)
						print("Hit tree for ", final_damage, " damage!")
					break

func calculate_final_damage(base_damage: float) -> float:
	var final_damage = base_damage * damage_multiplier
	
	# Blood pact: +25% damage per missing 10% health
	if has_blood_pact:
		var health_percentage = current_health / max_health
		var missing_health_chunks = int((1.0 - health_percentage) * 10)
		final_damage *= (1.0 + (missing_health_chunks * 0.25))
	
	return final_damage

func handle_food_decay(delta):
	var effective_decay_rate = movement_food_decay_rate
	
	if is_moving and current_food > 0:
		current_food = max(0, current_food - effective_decay_rate * delta)
		update_food_bar()

func handle_health_regeneration(delta):
	if current_food > 0 and current_health < max_health:
		var health_to_regen = health_regen_rate * delta
		var food_needed = health_to_regen * food_consumption_rate / health_regen_rate
		
		if current_food >= food_needed:
			current_health = min(max_health, current_health + health_to_regen)
			current_food = max(0, current_food - food_needed)
			update_health_bar()
			update_food_bar()

func handle_health_drain(delta):
	if health_drain_rate > 0:
		current_health = max(1, current_health - health_drain_rate * delta)
		update_health_bar()

func handle_chaos_magic(delta):
	if has_chaos_magic:
		chaos_timer += delta
		if chaos_timer >= chaos_interval:
			chaos_timer = 0.0
			apply_random_chaos_effect()

func handle_starvation_immunity(delta):
	if current_food <= 0 and starvation_immunity_time > 0:
		starvation_timer += delta
		if starvation_timer >= starvation_immunity_time:
			# Starvation immunity expired, start taking damage
			take_damage(5.0 * delta)

func apply_random_chaos_effect():
	# Random stat changes for chaos magic
	var effects = [
		{"stat": "damage_multiplier", "change": randf_range(-0.5, 1.0)},
		{"stat": "movement_speed_multiplier", "change": randf_range(-0.3, 0.8)},
		{"stat": "health_regen_rate", "change": randf_range(-5.0, 15.0)},
		{"stat": "swing_speed_multiplier", "change": randf_range(-0.2, 0.6)}
	]
	
	var chosen_effect = effects[randi() % effects.size()]
	
	match chosen_effect.stat:
		"damage_multiplier":
			damage_multiplier = max(0.1, damage_multiplier + chosen_effect.change)
		"movement_speed_multiplier":
			movement_speed_multiplier = max(0.1, movement_speed_multiplier + chosen_effect.change)
		"health_regen_rate":
			health_regen_rate = max(0, health_regen_rate + chosen_effect.change)
		"swing_speed_multiplier":
			swing_speed_multiplier = max(0.1, swing_speed_multiplier + chosen_effect.change)
	
	print("Chaos magic effect: ", chosen_effect.stat, " changed by ", chosen_effect.change)

# UPGRADE SYSTEM INTEGRATION
func apply_upgrade_effect(stat_name: String, value: float, is_multiplicative: bool = false):
	match stat_name:
		"max_health":
			if is_multiplicative:
				max_health = base_max_health * (1.0 + value)
			else:
				max_health = base_max_health + value
			# Heal player when max health increases (but not decrease current health when max decreases)
			if value > 0:
				current_health = min(current_health + value, max_health)
			else:
				current_health = min(current_health, max_health)
			update_health_bar()
			
		"health_regen_rate":
			if is_multiplicative:
				health_regen_rate = base_health_regen_rate * (1.0 + value)
			else:
				health_regen_rate = base_health_regen_rate + value
				
		"movement_speed":
			if is_multiplicative:
				movement_speed_multiplier *= (1.0 + value)
			else:
				movement_speed = base_movement_speed + value
				
		"damage_multiplier":
			if is_multiplicative:
				damage_multiplier *= (1.0 + value)
			else:
				damage_multiplier += value
				
		"swing_speed":
			if is_multiplicative:
				swing_speed_multiplier *= (1.0 + value)
			else:
				swing_speed_multiplier += value
				
		"max_food":
			if is_multiplicative:
				max_food = base_max_food * (1.0 + value)
			else:
				max_food = base_max_food + value
			update_food_bar()
			
		"max_inventory_size":
			max_inventory_size += int(value)
			
		"food_consumption_rate":
			if is_multiplicative:
				food_consumption_rate = base_food_consumption_rate * (1.0 + value)
			else:
				food_consumption_rate = base_food_consumption_rate + value
				
		"movement_food_decay_rate":
			if is_multiplicative:
				movement_food_decay_rate = base_movement_food_decay_rate * (1.0 + value)
			else:
				movement_food_decay_rate = base_movement_food_decay_rate + value
				
		"damage_reduction":
			damage_reduction += value
			damage_reduction = clamp(damage_reduction, 0.0, 0.95)  # Max 95% reduction
			
		"lifesteal":
			lifesteal += value
			
		"damage_reflection":
			damage_reflection += value
			
		"health_drain":
			health_drain_rate += value
			
		"food_efficiency":
			if is_multiplicative:
				food_efficiency_multiplier *= (1.0 + value)
			else:
				food_efficiency_multiplier += value
				
		"starvation_immunity":
			starvation_immunity_time = value
			
		"blood_pact":
			has_blood_pact = true
			
		"chaos_timer":
			has_chaos_magic = true
			chaos_interval = value
			
		"enemy_vision":
			has_enemy_vision = true
			# You would implement enemy highlighting/vision here

# MODIFIED: Complete rewrite of add_item function for stacking
func add_item(new_item: ItemResource) -> bool:
	if not new_item:
		return false
	
	var remaining_quantity = new_item.quantity
	
	# First, try to stack with existing items if stackable
	if new_item.is_stackable():
		for i in range(inventory.size()):
			if inventory[i] and inventory[i].can_stack_with(new_item):
				var leftover = inventory[i].add_quantity(remaining_quantity)
				remaining_quantity = leftover
				if remaining_quantity <= 0:
					inventory_changed.emit()
					update_held_item_display()
					return true
	
	# If there's still quantity left, try to add to empty slots or create new stacks
	while remaining_quantity > 0 and inventory.size() < max_inventory_size:
		var stack_size = min(remaining_quantity, new_item.stack_size)
		var new_stack = new_item.duplicate_item()
		new_stack.quantity = stack_size
		
		inventory.append(new_stack)
		remaining_quantity -= stack_size
	
	# Try to fill any empty slots in existing inventory
	for i in range(inventory.size()):
		if not inventory[i] and remaining_quantity > 0:
			var stack_size = min(remaining_quantity, new_item.stack_size)
			var new_stack = new_item.duplicate_item()
			new_stack.quantity = stack_size
			
			inventory[i] = new_stack
			remaining_quantity -= stack_size
	
	if remaining_quantity < new_item.quantity:
		inventory_changed.emit()
		update_held_item_display()
		return remaining_quantity == 0
	
	return false

func drop_selected_item():
	if selected_slot < inventory.size() and inventory[selected_slot]:
		var item_to_drop = inventory[selected_slot]
		remove_item(selected_slot)
		update_held_item_display()
		
		var dropped_item = dropped_item_scene.instantiate()
		dropped_item.set_item(item_to_drop)
		dropped_item.global_position = global_position + Vector2(0, -96)
		
		get_parent().add_child(dropped_item)

func remove_item(slot_index: int):
	if slot_index >= 0 and slot_index < inventory.size():
		inventory.remove_at(slot_index)
		inventory_changed.emit()
		update_held_item_display()

func get_item(slot_index: int) -> ItemResource:
	if slot_index >= 0 and slot_index < inventory.size():
		return inventory[slot_index]
	return null

func use_selected_item():
	if selected_slot < inventory.size() and inventory[selected_slot]:
		var item = inventory[selected_slot]
		
		if item.name == "Wood":
			fire.current_value += 20
			fire.fire_value.text = str(fire.current_value)
			remove_item(selected_slot)
			print("Consumed wood")
			pass
		
		if item.is_food():
			consume_food_item(item)

# MODIFIED: Updated to handle quantity and food efficiency
func consume_food_item(food_item: ItemResource):
	var base_food_value = food_item.get_food_value() if food_item.has_method("get_food_value") else 20.0
	var final_food_value = base_food_value * food_efficiency_multiplier
	
	current_food = min(max_food, current_food + final_food_value)
	update_food_bar()
	
	print("Consumed ", food_item.name, " (+", final_food_value, " food)")
	
	# Reset starvation timer when eating
	starvation_timer = 0.0
	
	# Decrease quantity instead of removing entire stack
	food_item.quantity -= 1
	if food_item.quantity <= 0:
		remove_item(selected_slot)
	else:
		inventory_changed.emit()
		update_held_item_display()

func take_damage(amount: float):
	# Apply damage reduction
	var final_damage = amount * (1.0 - damage_reduction)
	
	# Apply damage reflection if attacker can be found
	if damage_reflection > 0:
		# This would need to be expanded to track the damage source
		var reflected_damage = final_damage * damage_reflection
		print("Reflected ", reflected_damage, " damage back!")
	
	current_health = max(0, current_health - final_damage)
	update_health_bar()
	health_changed.emit(current_health)
	
	print("Took ", final_damage, " damage. Health: ", current_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(max_health, current_health + amount)
	update_health_bar()
	health_changed.emit(current_health)
	print("Healed ", amount, " health. Health: ", current_health)

func add_food(amount: float):
	var final_amount = amount * food_efficiency_multiplier
	current_food = min(max_food, current_food + final_amount)
	update_food_bar()
	food_changed.emit(current_food)

func add_experience(amount: float):
	experience += amount
	experience_gained.emit(amount)
	
	# Check for level up
	var upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		upgrade_manager.add_experience(amount)

func set_health(amount: float):
	current_health = clamp(amount, 0, max_health)
	update_health_bar()
	health_changed.emit(current_health)

func set_food(amount: float):
	current_food = clamp(amount, 0, max_food)
	update_food_bar()
	food_changed.emit(current_food)

func get_health_percentage() -> float:
	return current_health / max_health

func get_food_percentage() -> float:
	return current_food / max_food

func is_alive() -> bool:
	return current_health > 0

func is_hungry() -> bool:
	return current_food < max_food * 0.3

func is_starving() -> bool:
	return current_food <= 0

func die():
	print("Player died!")
	player_died.emit()

	# Save player's elapsed time instead of fire's
	get_tree().root.set_meta("final_game_time", int(elapsed_time))
	call_deferred("_go_to_game_ending")

func _go_to_game_ending():
	get_tree().change_scene_to_file("res://scenes/game_ending.tscn")
func update_health_bar():
	if health_bar:
		health_bar.value = (current_health / max_health) * 100

func update_food_bar():
	if food_bar:
		food_bar.value = (current_food / max_food) * 100
