extends CharacterBody2D

var inventory = []
var max_inventory_size = 5
var selected_slot = 0

# Health and Food system
var max_health = 100.0
var current_health = 100.0
var max_food = 100.0
var current_food = 100.0
var health_regen_rate = 10.0  # Health per second when regenerating
var food_consumption_rate = 5.0  # Food consumed per health point regenerated
var movement_food_decay_rate = 0.5  # Food lost per second when moving
var is_moving = false

@onready var health_bar: ProgressBar = %HealthBar
@onready var food_bar: ProgressBar = %FoodBar

signal inventory_changed
signal slot_selected(slot_index: int)
signal health_changed(new_health: float)
signal food_changed(new_food: float)
signal player_died

# Preload dropped item scene
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

func _ready():
	update_health_bar()
	update_food_bar()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * 400
	
	# Check if player is moving
	is_moving = input_direction.length() > 0
	
	handle_slot_selection()
	
	# Use item input
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()

func handle_slot_selection():
	for i in range(5):
		if Input.is_action_just_pressed("slot_" + str(i + 1)):
			selected_slot = i
			slot_selected.emit(i)
	
	# Drop item
	if Input.is_action_just_pressed("drop_item"):
		drop_selected_item()

func _physics_process(delta):
	get_input()
	move_and_slide()
	
	# Handle health and food systems
	handle_food_decay(delta)
	handle_health_regeneration(delta)

func handle_food_decay(delta):
	# Only lose food when moving around, and only very slowly
	if is_moving and current_food > 0:
		current_food = max(0, current_food - movement_food_decay_rate * delta)
		update_food_bar()

func handle_health_regeneration(delta):
	# Only regenerate health if we have food and health is not full
	if current_food > 0 and current_health < max_health:
		var health_to_regen = health_regen_rate * delta
		var food_needed = health_to_regen * food_consumption_rate / health_regen_rate
		
		# Check if we have enough food
		if current_food >= food_needed:
			current_health = min(max_health, current_health + health_to_regen)
			current_food = max(0, current_food - food_needed)
			update_health_bar()
			update_food_bar()

func add_item(item: ItemResource) -> bool:
	if inventory.size() < max_inventory_size:
		inventory.append(item)
		inventory_changed.emit()
		return true
	return false

func drop_selected_item():
	if selected_slot < inventory.size() and inventory[selected_slot]:
		var item_to_drop = inventory[selected_slot]
		remove_item(selected_slot)
		
		# Create dropped item in world
		var dropped_item = dropped_item_scene.instantiate()
		dropped_item.set_item(item_to_drop)
		dropped_item.global_position = global_position + Vector2(0, -96)
		
		get_parent().add_child(dropped_item)

func remove_item(slot_index: int):
	if slot_index >= 0 and slot_index < inventory.size():
		inventory.remove_at(slot_index)
		inventory_changed.emit()

func get_item(slot_index: int) -> ItemResource:
	if slot_index >= 0 and slot_index < inventory.size():
		return inventory[slot_index]
	return null

func use_selected_item():
	if selected_slot < inventory.size() and inventory[selected_slot]:
		var item = inventory[selected_slot]
		
		# Check if item is consumable (food)
		if item.has_method("get_food_value"):
			consume_food_item(item)

func consume_food_item(food_item: ItemResource):
	var food_value = food_item.get_food_value() if food_item.has_method("get_food_value") else 20.0
	current_food = min(max_food, current_food + food_value)
	update_food_bar()
	print("Consumed ", food_item.name, " (+", food_value, " food)")

# Health system utility methods
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
	return current_food < max_food * 0.3  # Hungry when food is below 30%

func is_starving() -> bool:
	return current_food <= 0

func die():
	print("Player died!")
	player_died.emit()
	# Add death logic here (respawn, game over screen, etc.)

func update_health_bar():
	if health_bar:
		health_bar.value = (current_health / max_health) * 100

func update_food_bar():
	if food_bar:
		food_bar.value = (current_food / max_food) * 100
