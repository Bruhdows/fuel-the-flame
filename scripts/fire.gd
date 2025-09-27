# fire.gd
extends StaticBody2D

@onready var fire_value: Label = $FireProgress
@onready var time_label: Label = $FireTimerLabel  # optional

@export var max_value: int = 9999  # optional cap for the fire value

var current_value: int = 150
var elapsed_time: float = 0.0  # tracks total time in seconds

func _ready() -> void:
	fire_value.text = str(current_value)
	set_process(true)  # enable _process to count elapsed_time
	$FireAnimation.play("Burn")



func _process(delta: float) -> void:
	elapsed_time += delta
	if time_label:
		@warning_ignore("integer_division")
		var minutes = int(elapsed_time) / 60
		var seconds = int(elapsed_time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_timer_timeout() -> void:
	current_value -= 1
	fire_value.text = str(current_value)

	if current_value <= 0:
		$Timer.stop()
		set_process(false)  # stop counting elapsed time

		# Store final elapsed time in the root so the ending scene can read it
		get_tree().root.set_meta("final_game_time", int(elapsed_time))

		# Change scene safely
		call_deferred("change_to_game_ending")

func change_to_game_ending() -> void:
	get_tree().change_scene_to_file("res://scenes/game_ending.tscn")
