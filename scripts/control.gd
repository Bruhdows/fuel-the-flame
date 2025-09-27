extends Control

@onready var player: CharacterBody2D = %Player
var slot_buttons = []
var slot_backgrounds = []

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
		# Create a container for each slot
		var slot_container = Control.new()
		slot_container.custom_minimum_size = Vector2(slot_size, slot_size)
		
		# Create background panel
		var background = Panel.new()
		background.anchor_left = 0
		background.anchor_right = 1
		background.anchor_top = 0
		background.anchor_bottom = 1
		
		# Style the background panel
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color.GRAY
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.WHITE
		
		background.add_theme_stylebox_override("panel", style_box)
		slot_container.add_child(background)
		slot_backgrounds.append(background)
		
		# Create the texture button on top
		var button = TextureButton.new()
		button.anchor_left = 0
		button.anchor_right = 1
		button.anchor_top = 0
		button.anchor_bottom = 1
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_slot_pressed.bind(i))
		
		# Make the button transparent so background shows through
		button.modulate = Color.WHITE
		
		slot_container.add_child(button)
		slot_buttons.append(button)
		
		hbox.add_child(slot_container)
	
	highlight_slot(0)

func _on_inventory_changed():
	for i in range(slot_buttons.size()):
		if i < player.inventory.size() and player.inventory[i] != null:
			slot_buttons[i].texture_normal = player.inventory[i].texture
		else:
			slot_buttons[i].texture_normal = null

func _on_slot_selected(slot_index: int):
	highlight_slot(slot_index)

func _on_slot_pressed(slot_index: int):
	player.selected_slot = slot_index
	player.slot_selected.emit(slot_index)
	
func highlight_slot(slot_index: int):
	for i in range(slot_backgrounds.size()):
		# Create new style for each background to avoid shared references
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color.GRAY
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		
		if i == slot_index:
			style_box.border_color = Color.YELLOW
		else:
			style_box.border_color = Color.WHITE
			
		slot_backgrounds[i].add_theme_stylebox_override("panel", style_box)
