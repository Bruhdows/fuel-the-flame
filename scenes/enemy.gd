# Enemy.gd
extends CharacterBody2D
class_name Enemy

# Enemy Stats
@export var max_health: float = 50.0
@export var movement_speed: float = 100.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 48.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 200.0

# Current state
var current_health: float
var player_target: CharacterBody2D = null
var is_attacking: bool = false
var attack_timer: float = 0.0
var is_dead: bool = false

# Navigation
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HealthBar

# Collision shapes
@onready var detection_collision: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

signal enemy_died(enemy: Enemy)
signal enemy_attacked_player(damage: float)

func _ready():
	current_health = max_health
	setup_navigation()
	setup_detection_areas()
	update_health_bar()

func setup_navigation():
	# Configure NavigationAgent2D
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = attack_range * 0.8
	
	# Wait for navigation to be ready
	call_deferred("actor_setup")

func setup_detection_areas():
	# Setup detection area
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	
	# Setup attack area  
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = attack_range
	attack_collision.shape = attack_shape
	
	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func actor_setup():
	# Wait for NavigationServer to sync
	await get_tree().physics_frame
	
	# Set initial target if player is already in range
	if player_target:
		nav_agent.target_position = player_target.global_position

func _physics_process(delta):
	if is_dead:
		return
		
	handle_attack_cooldown(delta)
	handle_movement()
	handle_attack()

func handle_attack_cooldown(delta):
	if attack_timer > 0:
		attack_timer -= delta

func handle_movement():
	if not player_target or is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Update target position
	nav_agent.target_position = player_target.global_position
	
	# Check if navigation is finished or we're close enough to attack
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Get next path position and move towards it
	var next_path_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	
	velocity = direction * movement_speed
	move_and_slide()
	
	# Flip sprite based on movement direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func handle_attack():
	if not player_target or is_dead or is_attacking or attack_timer > 0:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if distance_to_player <= attack_range:
		perform_attack()

func perform_attack():
	if not player_target or attack_timer > 0:
		return
		
	is_attacking = true
	attack_timer = attack_cooldown
	
	# Play attack animation if available
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# Deal damage to player
	if player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage)
		enemy_attacked_player.emit(attack_damage)
		print("Enemy attacked player for ", attack_damage, " damage!")
	
	# Reset attacking state after a short delay
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func take_damage(amount: float):
	if is_dead:
		return
		
	current_health = max(0, current_health - amount)
	update_health_bar()
	
	# Flash red when taking damage
	flash_damage()
	
	print("Enemy took ", amount, " damage. Health: ", current_health)
	
	if current_health <= 0:
		die()

func flash_damage():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color.WHITE

func heal(amount: float):
	if is_dead:
		return
		
	current_health = min(max_health, current_health + amount)
	update_health_bar()

func die():
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	
	# Play death animation if available
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	enemy_died.emit(self)
	print("Enemy died!")
	
	# Remove enemy after death
	queue_free()

func update_health_bar():
	if health_bar:
		health_bar.value = (current_health / max_health) * 100
		health_bar.visible = current_health < max_health

func _on_detection_area_body_entered(body):
	if body.name == "Player" or body.has_method("take_damage"):
		player_target = body
		print("Enemy detected player")

func _on_detection_area_body_exited(body):
	if body == player_target:
		player_target = null
		print("Player left detection range")

func _on_attack_area_body_entered(body):
	# This is handled in handle_attack() function
	pass

func _on_attack_area_body_exited(body):
	# This is handled in handle_attack() function  
	pass

func get_health_percentage() -> float:
	return current_health / max_health

func is_alive() -> bool:
	return current_health > 0 and not is_dead

func set_target(target: CharacterBody2D):
	player_target = target
