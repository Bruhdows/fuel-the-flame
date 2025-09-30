extends Control

@onready var game_title: Label = $GameTitle
@onready var start_button: Button = $StartButton
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	_position_ui()
	print("Game ending loaded")
	var final_time: int = 0
	if get_tree().root.has_meta("final_game_time"):
		final_time = get_tree().root.get_meta("final_game_time")
	
	score_label.text = "Final time: " + format_time(final_time)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_ui()

func _position_ui() -> void:
	if not game_title or not start_button or not score_label:
		return

	var screen_size: Vector2 = get_viewport_rect().size
	
	game_title.position = Vector2(
		(screen_size.x - game_title.size.x) / 2,
		50
	)
	
	score_label.position = Vector2(
		(screen_size.x - score_label.size.x) / 2,
		game_title.position.y + game_title.size.y + 20
	)
	
	start_button.custom_minimum_size = Vector2(250, 80)
	start_button.position = Vector2(
		200,
		(screen_size.y - start_button.size.y) / 2 + 50
	)
	
func format_time(seconds: int) -> String:
	var minutes: int = seconds / 60
	var secs: int = seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
