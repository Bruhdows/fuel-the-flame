extends Area2D

var max_health: float = 60.0  # Reduced for faster testing
var current_health: float = 60.0
var wood_drops: int = 3

@onready var icon: Sprite2D = $Icon
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var dropped_item_scene = preload("res://scenes/dropped_item.tscn")

var is_being_destroyed: bool = false

func _ready():
	add_to_group("trees")
	
	# Set up collision detection
	if collision_shape:
		collision_layer = 16  # Layer 5 (bit 16)
		collision_mask = 0
	
	# Connect area signals for debugging
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)

func _on_area_entered(area):
	print("Area entered tree: ", area.name)

func _on_body_entered(body):
	print("Body entered tree: ", body.name)

func take_damage(amount: float):
	if is_being_destroyed:
		return
		
	current_health -= amount
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	print("Tree took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Show damage effect
	create_damage_number(amount)
	
	if current_health <= 0:
		break_tree()

func create_damage_number(damage: float):
	var damage_label = Label.new()
	damage_label.text = "-" + str(int(damage))
	damage_label.modulate = Color.RED
	damage_label.position = Vector2(randf_range(-20, 20), -30)
	add_child(damage_label)
	
	# Animate damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(damage_label, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(damage_label.queue_free)

func break_tree():
	if is_being_destroyed:
		return
	
	is_being_destroyed = true
	print("Tree broken!")
	
	# Visual breaking effect
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "rotation", randf_range(-PI/4, PI/4), 0.5)
		tween.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
	
	# Drop wood items with delay
	await get_tree().create_timer(0.3).timeout
	drop_wood_items()
	
	# Remove tree
	await get_tree().create_timer(0.5).timeout
	queue_free()

func create_wood_item() -> ItemResource:
	var texture = preload("res://assets/wood.png")
	return ItemResource.new("Wood", texture, "", 1)

func drop_wood_items():
	for i in wood_drops:
		var wood_item = create_wood_item()
		var dropped_item = dropped_item_scene.instantiate()
		dropped_item.set_item(wood_item)
		
		# Spread items around the tree
		var angle = (i / float(wood_drops)) * TAU
		var offset = Vector2.from_angle(angle) * randf_range(20, 40)
		dropped_item.global_position = global_position + offset
		
		get_parent().add_child(dropped_item)
		
		# Add slight delay between drops
		await get_tree().create_timer(0.1).timeout
