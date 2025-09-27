extends CharacterBody2D

var inventory = []
var max_inventory_size = 5
var selected_slot = 0

# Health and Food system
var max_health = 100.0
var current_health = 100.0
var max_food = 100.0
var current_food = 100.0
var health_regen_rate = 10.0
var food_consumption_rate = 5.0
var movement_food_decay_rate = 0.5
var is_moving = false
var elapsed_time: float = 0.0

# Item holding system
var held_item_sprite: Sprite2D
var is_swinging = false
var swing_duration = 0.3
var swing_timer = 0.0
var original_held_item_rotation = 0.0

@onready var health_bar: ProgressBar = %HealthBar
@onready var food_bar: ProgressBar = %FoodBar

signal inventory_changed
signal slot_selected(slot_index: int)
signal health_changed(new_health: float)
signal food_changed(new_food: float)
signal player_died

var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

func _ready():
	setup_held_item_sprite()
	update_health_bar()
	update_food_bar()
	update_held_item_display()

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
	velocity = input_direction * 400
	
	is_moving = input_direction.length() > 0
	
	handle_slot_selection()
	
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()
	
	if Input.is_action_just_pressed("swing") and not is_swinging:
		swing_item()

func handle_slot_selection():
	for i in range(5):
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

func handle_swing_animation(delta):
	if is_swinging:
		swing_timer += delta
		var progress = swing_timer / swing_duration
		
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
	query.collision_mask = 4  # Enemy layer (set enemies to layer 3, mask bit 4)
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			var current_item = get_selected_item()
			var damage = 25.0  # Default sword damage
			if current_item and current_item.has_method("get_damage"):
				damage = current_item.get_damage()
			body.take_damage(damage)
			print("Hit enemy for ", damage, " damage!")

func check_tree_damage():
	var swing_range = 64.0  # Increased range for better detection
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Use Area2D overlap detection instead of distance calculation
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position + direction * swing_range
	query.collision_mask = 16  # Set trees to collision layer 5 (bit 16)
	
	var result = space_state.intersect_point(query)
	
	# Alternative method: Check all trees in range
	var trees = get_tree().get_nodes_in_group("trees")
	for tree in trees:
		if tree and is_instance_valid(tree):
			var distance = global_position.distance_to(tree.global_position)
			if distance <= swing_range:
				# Check if tree is in the swing direction
				var tree_direction = (tree.global_position - global_position).normalized()
				var dot_product = direction.dot(tree_direction)
				
				# Only hit trees in front of the player (dot product > 0.5 means roughly same direction)
				if dot_product > 0.5:
					var current_item = get_selected_item()
					var damage = 15.0
					if current_item and current_item.has_method("get_damage"):
						damage = current_item.get_damage() * 0.6
					
					if tree.has_method("take_damage"):
						tree.take_damage(damage)
						print("Hit tree for ", damage, " damage!")
					break  # Only hit one tree per swing

func handle_food_decay(delta):
	if is_moving and current_food > 0:
		current_food = max(0, current_food - movement_food_decay_rate * delta)
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

func add_item(item: ItemResource) -> bool:
	if inventory.size() < max_inventory_size:
		inventory.append(item)
		inventory_changed.emit()
		update_held_item_display()
		return true
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
		
		if item.has_method("get_food_value") && item.is_food():
			consume_food_item(item)

func consume_food_item(food_item: ItemResource):
	var food_value = food_item.get_food_value() if food_item.has_method("get_food_value") else 20.0
	current_food = min(max_food, current_food + food_value)
	update_food_bar()
	print("Consumed ", food_item.name, " (+", food_value, " food)")
	
	remove_item(selected_slot)

func take_damage(amount: float):
	current_health = max(0, current_health - amount)
	update_health_bar()
	health_changed.emit(current_health)
	
	print("Took ", amount, " damage. Health: ", current_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(max_health, current_health + amount)
	update_health_bar()
	health_changed.emit(current_health)
	print("Healed ", amount, " health. Health: ", current_health)

func add_food(amount: float):
	current_food = min(max_food, current_food + amount)
	update_food_bar()
	food_changed.emit(current_food)

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
