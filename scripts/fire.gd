extends StaticBody2D

@onready var fire_value: Label = $FireProgress

@export var max_value: int = 9999

var current_value: int = 150
var elapsed_time: float = 0.0

func _ready() -> void:
	fire_value.text = str(current_value)
	$FireAnimation.play("Burn")
	$FireAnimation.play("Smoke")

func _process(delta: float) -> void:
	elapsed_time += delta

func _on_timer_timeout() -> void:
	current_value -= 1
	fire_value.text = str(current_value)

	if current_value <= 0:
		$Timer.stop()
		set_process(false)
		get_tree().root.set_meta("final_game_time", int(elapsed_time))
		call_deferred("change_to_game_ending")

func change_to_game_ending() -> void:
	get_tree().change_scene_to_file("res://scenes/game_ending.tscn")
