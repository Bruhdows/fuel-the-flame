extends CharacterBody2D

@export var health: float = 50.0
@export var speed: float = 80.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 50.0

var player: CharacterBody2D
var attack_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

func _physics_process(delta):
	attack_timer -= delta
	
	# Move toward player
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	
	sprite.flip_h = velocity.x < 0
	
	if global_position.distance_to(player.global_position) < attack_range and attack_timer <= 0:
		attack_player()
	
	move_and_slide()

func attack_player():
	attack_timer = 1.5
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)

func take_damage(amount: float):
	health -= amount
	var oldModulate = sprite.modulate
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = oldModulate
	
	if health <= 0:
		queue_free()
