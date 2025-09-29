extends Control

@onready var game_title: Label = $GameTitle
@onready var start_button: Button = $StartButton

func _ready() -> void:
	if not game_title or not start_button:
		push_error("GameTitle or StartButton node not found!")
		return
	_position_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_ui()

func _position_ui() -> void:
	if not game_title or not start_button:
		return

	var screen_size: Vector2 = get_viewport_rect().size
	
	game_title.position = Vector2(
		(screen_size.x - game_title.size.x) / 2,
		50
	)
	
	start_button.custom_minimum_size = Vector2(250, 80)
	start_button.position = Vector2(
		200,
		(screen_size.y - start_button.size.y) / 2 + 50
	)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
