extends Control

@onready var game_title = $GameTitle
@onready var start_button = $StartButton

const BUTTON_OFFSET_Y = 50

func _ready():
	if not game_title or not start_button:
		push_error("GameTitle or StartButton node not found! Check node names/paths.")
		return
	_position_ui()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_ui()

func _position_ui():
	if not game_title or not start_button:
		return

	var screen_size = get_viewport_rect().size
	
	# --- Title (Label) ---
	game_title.position = Vector2(
		(screen_size.x - game_title.size.x) / 2,
		50
	)
	
	# --- Start Button (Left-Center, adjusted) ---
	start_button.custom_minimum_size = Vector2(250, 80)
	var horizontal_offset = 200  # further from left, closer to center
	var vertical_offset = 50     # slightly lower than exact vertical center
	start_button.position = Vector2(
		horizontal_offset,
		(screen_size.y - start_button.size.y) / 2 + vertical_offset
	)



func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
