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

func _ready() -> void:
	select_button.pressed.connect(_on_button_pressed)
	select_button.mouse_entered.connect(_on_button_hover_entered)
	select_button.mouse_exited.connect(_on_button_hover_exited)
	
	select_button.flat = true
	select_button.modulate = Color.TRANSPARENT

func setup_choice(choice: UpgradeChoice, index: int) -> void:
	upgrade_choice = choice
	choice_index = index
	
	name_label.text = choice.name
	description_label.text = choice.description
	
	if choice.icon:
		icon_texture.texture = choice.icon
		icon_texture.visible = true
	else:
		icon_texture.visible = false
	
	for child: Node in effects_container.get_children():
		if child != effects_container.get_child(0):
			child.queue_free()
	
	if choice.effects.size() > 0:
		var first_effect_label: Label = effects_container.get_child(0) as Label
		first_effect_label.text = format_effect(choice.effects[0])
		first_effect_label.visible = true
		
		for i: int in range(1, choice.effects.size()):
			var effect_label: Label = first_effect_label.duplicate()
			effect_label.text = format_effect(choice.effects[i])
			effects_container.add_child(effect_label)
	else:
		effects_container.get_child(0).visible = false
	
	apply_rarity_styling()

func format_effect(effect: UpgradeEffect) -> String:
	var effect_text: String = ""
	var value_text: String = ""
	
	if effect.is_multiplicative:
		var percentage: float = effect.value * 100
		if effect.value > 0:
			value_text = "+" + str(percentage) + "%"
		else:
			value_text = str(percentage) + "%"
	else:
		if effect.value > 0:
			value_text = "+" + str(effect.value)
		else:
			value_text = str(effect.value)
	
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

func apply_rarity_styling() -> void:
	if not upgrade_choice:
		return
	
	var rarity_colors: Dictionary = {
		"common": Color(0.8, 0.8, 0.8),
		"uncommon": Color(0.3, 0.8, 0.3),
		"rare": Color(0.3, 0.3, 0.9),
		"legendary": Color(0.9, 0.7, 0.2)
	}
	
	var border_colors: Dictionary = {
		"common": Color(0.5, 0.5, 0.5),
		"uncommon": Color(0.1, 0.6, 0.1),
		"rare": Color(0.1, 0.1, 0.7),
		"legendary": Color(0.7, 0.5, 0.1)
	}
	
	var rarity_color: Color = rarity_colors.get(upgrade_choice.rarity, Color.WHITE)
	var border_color: Color = border_colors.get(upgrade_choice.rarity, Color.GRAY)
	
	name_label.modulate = rarity_color
	
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = border_color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	background_panel.add_theme_stylebox_override("panel", style_box)

func _on_button_pressed() -> void:
	choice_selected.emit(choice_index)

func _on_button_hover_entered() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	
	var style_box: StyleBoxFlat = background_panel.get_theme_stylebox("panel").duplicate()
	if style_box is StyleBoxFlat:
		style_box.shadow_color = Color(1, 1, 1, 0.3)
		style_box.shadow_size = 5
		background_panel.add_theme_stylebox_override("panel", style_box)

func _on_button_hover_exited() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	apply_rarity_styling()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ENTER, KEY_SPACE:
					_on_button_pressed()

func _can_drop_data(position: Vector2, data: Variant) -> bool:
	return false

func get_select_button() -> Button:
	return select_button

func select_choice() -> void:
	_on_button_pressed()

func focus_button() -> void:
	select_button.grab_focus()
