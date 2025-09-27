# upgrade_choice_button.gd
extends Control
class_name UpgradeChoiceButton

signal choice_selected(choice_index: int)

@onready var background_panel: Panel = $BackgroundPanel
@onready var icon_texture: TextureRect = $ContentContainer/HeaderContainer/IconTexture
@onready var name_label: Label = $ContentContainer/HeaderContainer/NameLabel
@onready var description_label: Label = $ContentContainer/DescriptionLabel
@onready var effects_container: VBoxContainer = $ContentContainer/EffectsContainer
@onready var select_button: Button = $SelectButton

var choice_index: int = -1
var upgrade_choice: UpgradeChoice

func _ready():
	select_button.pressed.connect(_on_button_pressed)
	select_button.mouse_entered.connect(_on_button_hover_entered)
	select_button.mouse_exited.connect(_on_button_hover_exited)
	
	# Style the button to be transparent initially
	select_button.flat = true
	select_button.modulate = Color.TRANSPARENT

func setup_choice(choice: UpgradeChoice, index: int):
	upgrade_choice = choice
	choice_index = index
	
	# Set basic info
	name_label.text = choice.name
	description_label.text = choice.description
	
	# Set icon if available
	if choice.icon:
		icon_texture.texture = choice.icon
		icon_texture.visible = true
	else:
		icon_texture.visible = false
	
	# Clear existing effect labels
	for child in effects_container.get_children():
		if child != effects_container.get_child(0):  # Keep the first one as template
			child.queue_free()
	
	# Create effect labels
	if choice.effects.size() > 0:
		var first_effect_label = effects_container.get_child(0) as Label
		first_effect_label.text = format_effect(choice.effects[0])
		first_effect_label.visible = true
		
		# Create additional labels for remaining effects
		for i in range(1, choice.effects.size()):
			var effect_label = first_effect_label.duplicate()
			effect_label.text = format_effect(choice.effects[i])
			effects_container.add_child(effect_label)
	else:
		effects_container.get_child(0).visible = false
	
	# Apply rarity styling
	apply_rarity_styling()

func format_effect(effect) -> String:
	var effect_text = ""
	var value_text = ""
	
	# Format the value based on type
	if effect.is_multiplicative:
		var percentage = effect.value * 100
		if effect.value > 0:
			value_text = "+" + str(percentage) + "%"
		else:
			value_text = str(percentage) + "%"
	else:
		if effect.value > 0:
			value_text = "+" + str(effect.value)
		else:
			value_text = str(effect.value)
	
	# Format based on stat type
	match effect.stat_name:
		"max_health":
			effect_text = value_text + " Max Health"
		"health_regen_rate":
			effect_text = value_text + " Health Regen"
		"damage_multiplier":
			effect_text = value_text + " Damage"
		"movement_speed":
			effect_text = value_text + " Movement Speed"
		"swing_speed":
			effect_text = value_text + " Attack Speed"
		"max_food":
			effect_text = value_text + " Max Food"
		"damage_reduction":
			effect_text = value_text + " Damage Reduction"
		"lifesteal":
			effect_text = value_text + " Lifesteal"
		"max_inventory_size":
			effect_text = value_text + " Inventory Slots"
		"food_consumption_rate":
			effect_text = value_text + " Food Consumption"
		"movement_food_decay_rate":
			effect_text = value_text + " Food Decay While Moving"
		"health_drain":
			effect_text = value_text + "/sec Health Drain"
		"food_efficiency":
			effect_text = value_text + " Food Efficiency"
		_:
			effect_text = effect.stat_name + ": " + value_text
	
	return effect_text

func apply_rarity_styling():
	if not upgrade_choice:
		return
	
	var rarity_colors = {
		"common": Color(0.8, 0.8, 0.8),      # Light gray
		"uncommon": Color(0.3, 0.8, 0.3),    # Green
		"rare": Color(0.3, 0.3, 0.9),        # Blue  
		"legendary": Color(0.9, 0.7, 0.2)    # Gold
	}
	
	var border_colors = {
		"common": Color(0.5, 0.5, 0.5),
		"uncommon": Color(0.1, 0.6, 0.1),
		"rare": Color(0.1, 0.1, 0.7),
		"legendary": Color(0.7, 0.5, 0.1)
	}
	
	var rarity_color = rarity_colors.get(upgrade_choice.rarity, Color.WHITE)
	var border_color = border_colors.get(upgrade_choice.rarity, Color.GRAY)
	
	# Style the name label with rarity color
	name_label.modulate = rarity_color
	
	# Create a stylebox for the background panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Dark background
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = border_color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	# Apply the style
	background_panel.add_theme_stylebox_override("panel", style_box)

func _on_button_pressed():
	choice_selected.emit(choice_index)

func _on_button_hover_entered():
	# Highlight effect on hover
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	
	# Add glow effect to background
	var style_box = background_panel.get_theme_stylebox("panel").duplicate()
	if style_box is StyleBoxFlat:
		style_box.shadow_color = Color(1, 1, 1, 0.3)
		style_box.shadow_size = 5
		background_panel.add_theme_stylebox_override("panel", style_box)

func _on_button_hover_exited():
	# Remove highlight effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Remove glow effect
	apply_rarity_styling()  # Reapply original styling

# Optional: Add gamepad/keyboard navigation support
func _gui_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ENTER, KEY_SPACE:
					_on_button_pressed()
				KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
					# Handle navigation between choices
					pass

func _can_drop_data(position, data):
	return false  # Prevent drag and drop on upgrade buttons

# Utility method to get the button for external focus management
func get_select_button() -> Button:
	return select_button

# Method to programmatically select this choice (for keyboard navigation)
func select_choice():
	_on_button_pressed()

# Method to focus this button for keyboard navigation
func focus_button():
	select_button.grab_focus()
