extends StaticBody2D

@onready var fire_value: Label = $FireProgress

var current_value: int = 150

func _ready() -> void:
	fire_value.text = str(current_value)

func _on_timer_timeout() -> void:
	current_value -= 1
	if current_value < 0:
		current_value = 0
	fire_value.text = str(current_value)
