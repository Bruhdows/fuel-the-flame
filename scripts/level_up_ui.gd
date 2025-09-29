extends Control

@onready var choice_container: Control = $ChoiceContainer
@onready var choice_button_scene: PackedScene = preload("res://scenes/upgrade_choice_button.tscn")

var current_choices: Array[UpgradeChoice] = []

func _ready() -> void:
	var upgrade_manager: Node = get_node("/root/UpgradeManager")
	upgrade_manager.level_up_choices_ready.connect(_on_choices_ready)
	hide()

func _on_choices_ready(choices: Array[UpgradeChoice]) -> void:
	current_choices = choices
	display_choices()

func display_choices() -> void:
	for child: Node in choice_container.get_children():
		child.queue_free()
	
	for i: int in current_choices.size():
		var choice: UpgradeChoice = current_choices[i]
		var button: UpgradeChoiceButton = choice_button_scene.instantiate()
		button.setup_choice(choice, i)
		button.choice_selected.connect(_on_choice_selected)
		choice_container.add_child(button)
	
	show()
	get_tree().paused = true

func _on_choice_selected(choice_index: int) -> void:
	var selected_upgrade: UpgradeChoice = current_choices[choice_index]
	var upgrade_manager: Node = get_node("/root/UpgradeManager")
	upgrade_manager.apply_upgrade(selected_upgrade)
	
	hide()
	get_tree().paused = false
