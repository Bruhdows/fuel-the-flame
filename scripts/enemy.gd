extends CharacterBody2D

@export var health: float = 50.0
@export var speed: float = 80.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 50.0

var player: CharacterBody2D
var attack_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite2D

# Add the death signal
signal died

func _physics_process(delta: float) -> void:
	attack_timer -= delta
	
	if not player:
		return
	
	var direction: Vector2 = global_position.direction_to(player.global_position)
	velocity = direction * speed
	sprite.flip_h = velocity.x < 0
	
	if global_position.distance_to(player.global_position) < attack_range and attack_timer <= 0:
		attack_player()
	
	move_and_slide()

func attack_player() -> void:
	attack_timer = 1.5
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)

func take_damage(amount: float) -> void:
	health -= amount
	var old_modulate: Color = sprite.modulate
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = old_modulate
	
	if health <= 0:
		died.emit()
		queue_free()
