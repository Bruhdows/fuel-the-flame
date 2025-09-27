extends StaticBody2D

@onready var fire_value: Label = $FireProgress


var current_value: int = 150


func _ready() -> void:
	fire_value.text = str(current_value)

func _on_timer_timeout() -> void:
	current_value -= 1
	fire_value.text = str(current_value)

	if current_value <= 0:
		# Stop the timer
		$Timer.stop()
		# Defer the scene change safely
		call_deferred("change_to_game_ending")


func change_to_game_ending() -> void:
	# Godot 4 method for changing scene
	get_tree().change_scene_to_file("res://scenes/game_ending.tscn")
