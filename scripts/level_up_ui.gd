# level_up_ui.gd
extends Control

@onready var choice_container = $ChoiceContainer
@onready var choice_button_scene = preload("res://scenes/upgrade_choice_button.tscn")

var current_choices: Array[UpgradeChoice] = []

func _ready():
	var upgrade_manager = get_node("/root/UpgradeManager")
	upgrade_manager.level_up_choices_ready.connect(_on_choices_ready)
	hide()

func _on_choices_ready(choices: Array[UpgradeChoice]):
	current_choices = choices
	display_choices()

func display_choices():
	# Clear previous choices
	for child in choice_container.get_children():
		child.queue_free()
	
	# Create new choice buttons
	for i in range(current_choices.size()):
		var choice = current_choices[i]
		var button = choice_button_scene.instantiate()
		button.setup_choice(choice, i)
		button.choice_selected.connect(_on_choice_selected)
		choice_container.add_child(button)
	
	show()
	get_tree().paused = true

func _on_choice_selected(choice_index: int):
	var selected_upgrade = current_choices[choice_index]
	var upgrade_manager = get_node("/root/UpgradeManager")
	upgrade_manager.apply_upgrade(selected_upgrade)
	
	hide()
	get_tree().paused = false
