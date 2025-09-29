extends Area2D
class_name DroppedItem

@export var item_resource: ItemResource
@onready var sprite: Sprite2D = $ItemTexture
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if item_resource:
		sprite.texture = item_resource.texture
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_item") and body.add_item(item_resource):
		queue_free()

func set_item(item: ItemResource) -> void:
	item_resource = item
	if sprite:
		sprite.texture = item.texture
