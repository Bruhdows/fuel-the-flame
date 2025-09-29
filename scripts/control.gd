extends Control

@onready var player: CharacterBody2D = %Player
var slot_buttons: Array[TextureButton] = []
var slot_backgrounds: Array[Panel] = []

const SLOT_SIZE: int = 64
const TOTAL_SLOTS: int = 5

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_inventory_slots()
	player.inventory_changed.connect(_on_inventory_changed)
	player.slot_selected.connect(_on_slot_selected)

func create_inventory_slots() -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.anchor_top = 1.0
	hbox.anchor_bottom = 1.0
	
	var half_center_slot_offset: int = (2 * SLOT_SIZE) + (SLOT_SIZE / 2)
	hbox.offset_left = -half_center_slot_offset
	hbox.offset_right = -half_center_slot_offset + (TOTAL_SLOTS * SLOT_SIZE)
	hbox.offset_top = -70
	hbox.offset_bottom = -6
	
	add_child(hbox)
	
	for i: int in TOTAL_SLOTS:
		var slot_container: Control = Control.new()
		slot_container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		
		var background: Panel = Panel.new()
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = Color.GRAY
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.WHITE
		
		background.add_theme_stylebox_override("panel", style_box)
		slot_container.add_child(background)
		slot_backgrounds.append(background)
		
		var button: TextureButton = TextureButton.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_slot_pressed.bind(i))
		
		slot_container.add_child(button)
		slot_buttons.append(button)
		hbox.add_child(slot_container)
	
	highlight_slot(0)

func _on_inventory_changed() -> void:
	for i: int in slot_buttons.size():
		if i < player.inventory.size() and player.inventory[i] != null:
			slot_buttons[i].texture_normal = player.inventory[i].texture
		else:
			slot_buttons[i].texture_normal = null

func _on_slot_selected(slot_index: int) -> void:
	highlight_slot(slot_index)

func _on_slot_pressed(slot_index: int) -> void:
	player.selected_slot = slot_index
	player.slot_selected.emit(slot_index)
	
func highlight_slot(slot_index: int) -> void:
	for i: int in slot_backgrounds.size():
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = Color.GRAY
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.YELLOW if i == slot_index else Color.WHITE
		slot_backgrounds[i].add_theme_stylebox_override("panel", style_box)
