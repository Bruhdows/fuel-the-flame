extends Control

@onready var player: CharacterBody2D = %Player
var slot_buttons = []

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_inventory_slots()
	player.inventory_changed.connect(_on_inventory_changed)
	player.slot_selected.connect(_on_slot_selected)

func create_inventory_slots():
	var hbox = HBoxContainer.new()
	
	# Calculate positioning based on center slot
	var slot_size = 64
	var total_slots = 5
	var center_slot_index = 2  # Middle slot (0-indexed)
	
	# Position so the center slot (index 2) is at screen center
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	
	# Offset to center the middle slot at screen center
	var half_center_slot_offset = (center_slot_index * slot_size) + (slot_size / 2)
	hbox.offset_left = -half_center_slot_offset
	hbox.offset_right = -half_center_slot_offset + (total_slots * slot_size)
	hbox.offset_top = -70
	hbox.offset_bottom = -6
	
	add_child(hbox)
	
	for i in range(5):
		# Use TextureButton instead of Button for texture display
		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(slot_size, slot_size)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_slot_pressed.bind(i))
		
		# Add background styling for inventory slots
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color.GRAY
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.WHITE
		button.add_theme_stylebox_override("normal", style_box)
		
		hbox.add_child(button)
		slot_buttons.append(button)
	
	highlight_slot(0)

func _on_inventory_changed():
	for i in range(slot_buttons.size()):
		if i < player.inventory.size() and player.inventory[i] != null:
			slot_buttons[i].texture_normal = player.inventory[i].texture
		else:
			slot_buttons[i].texture_normal = null

func _on_slot_selected(slot_index: int):
	for button in slot_buttons:
		button.modulate = Color.WHITE
	slot_buttons[slot_index].modulate = Color.YELLOW

func _on_slot_pressed(slot_index: int):
	player.selected_slot = slot_index
	player.slot_selected.emit(slot_index)
	
func highlight_slot(slot_index: int):
	for i in range(slot_buttons.size()):
		var style_box = slot_buttons[i].get_theme_stylebox("normal")
		if i == slot_index:
			style_box.border_color = Color.YELLOW
		else:
			style_box.border_color = Color.WHITE
