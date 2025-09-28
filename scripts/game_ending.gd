extends Control

@onready var game_title = $GameTitle
@onready var start_button = $StartButton
@onready var score_label = $ScoreLabel

const BUTTON_OFFSET_Y = 50

func _ready():
	_position_ui()
	
	# Get final elapsed time from root
	var final_time = 0
	if get_tree().root.has_meta("final_game_time"):
		final_time = get_tree().root.get_meta("final_game_time")
	
	score_label.text = "Final time: " + format_time(final_time)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_ui()

func _position_ui():
	if not game_title or not start_button or not score_label:
		return

	var screen_size = get_viewport_rect().size
	
	# --- Title ---
	game_title.position = Vector2(
		(screen_size.x - game_title.size.x) / 2,
		50
	)
	
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
