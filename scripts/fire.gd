# fire.gd
extends StaticBody2D

@onready var fire_value: Label = $FireProgress
@onready var time_label: Label = $FireTimerLabel  # optional
@onready var fuel_zone: Area2D = $NIGGER3000     # the Area2D you added

@export var max_value: int = 9999  # optional cap for the fire value

var current_value: int = 150
var elapsed_time: float = 0.0  # tracks total time in seconds

func _ready() -> void:
	print("FuelZone:", get_children())
	fire_value.text = str(current_value)
	set_process(true)  # enable _process to count elapsed_time

	# connect fuel zone signal
	if fuel_zone:
		print("Hello There")
		# robust connection
		fuel_zone.connect("area_entered", Callable(self, "_on_fuel_zone_area_entered"))

func _process(delta: float) -> void:
	elapsed_time += delta
	if time_label:
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

# Called when any Area2D enters the FuelZone
func _on_fuel_zone_area_entered(area: Area2D) -> void:
	# Make sure it's a DroppedItem (you have class_name DroppedItem)
	if not area:
		return
	if area is DroppedItem:
		var res : ItemResource = area.item_resource
		if res:
			# Prefer explicit fuel_value, but keep a small fallback for legacy resources
			var fuel_amount := 0
			if res.has_method("get_fuel_value"):
				fuel_amount = res.get_fuel_value()
			else:
				# fallback: name-based (legacy)
				if res.name == "Wood":
					fuel_amount = 20

			if fuel_amount > 0:
				# add fuel with optional cap
				current_value = clamp(current_value + fuel_amount, 0, max_value)
				fire_value.text = str(current_value)

				# optional: play particle/sound here (e.g. $AddFuelSound.play())
				# remove the dropped item from the world
				area.queue_free()
