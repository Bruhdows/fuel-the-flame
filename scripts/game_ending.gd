extends Control

@onready var game_title = $GameTitle
@onready var start_button = $StartButton
<<<<<<< Updated upstream
<<<<<<< Updated upstream
@onready var score_label = $ScoreLabel
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

const BUTTON_OFFSET_Y = 50

func _ready():
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	_position_ui()
	
	# Get final elapsed time from root
	var final_time = 0
	if get_tree().root.has_meta("final_game_time"):
		final_time = get_tree().root.get_meta("final_game_time")
	
	score_label.text = "Final time: " + format_time(final_time)
=======
=======
>>>>>>> Stashed changes
	if not game_title or not start_button:
		push_error("GameTitle or StartButton node not found! Check node names/paths.")
		return
	_position_ui()
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_ui()

func _position_ui():
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	if not game_title or not start_button or not score_label:
=======
	if not game_title or not start_button:
>>>>>>> Stashed changes
=======
	if not game_title or not start_button:
>>>>>>> Stashed changes
		return

	var screen_size = get_viewport_rect().size
	
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	# --- Title ---
=======
	# --- Title (Label) ---
>>>>>>> Stashed changes
=======
	# --- Title (Label) ---
>>>>>>> Stashed changes
	game_title.position = Vector2(
		(screen_size.x - game_title.size.x) / 2,
		50
	)
	
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	# --- Score label (under title) ---
	score_label.position = Vector2(
		(screen_size.x - score_label.size.x) / 2,
		game_title.position.y + game_title.size.y + 20
	)
	
	# --- Start button ---
	start_button.custom_minimum_size = Vector2(250, 80)
	start_button.position = Vector2(
		200,
		(screen_size.y - start_button.size.y) / 2 + 50
	)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]
=======
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
