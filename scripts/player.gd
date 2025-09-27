extends CharacterBody2D

var inventory = []
var max_inventory_size = 5
var selected_slot = 0

signal inventory_changed
signal slot_selected(slot_index: int)

# Preload dropped item scene
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * 400
	
	handle_slot_selection()

func handle_slot_selection():
	for i in range(5):
		if Input.is_action_just_pressed("slot_" + str(i + 1)):
			selected_slot = i
			slot_selected.emit(i)
	
	# Drop item
	if Input.is_action_just_pressed("drop_item"):
		drop_selected_item()

func _physics_process(_delta):
	get_input()
	move_and_slide()

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
		dropped_item.global_position = global_position + Vector2(0, -96)  # Drop slightly below player
		
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
		print("Used item: ", item.name)
		remove_item(selected_slot)
