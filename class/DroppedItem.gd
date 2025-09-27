# DroppedItem.gd
extends Area2D
class_name DroppedItem

@export var item_resource: ItemResource
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	if item_resource:
		sprite.texture = item_resource.texture
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("add_item"):
		if body.add_item(item_resource):
			queue_free()

func set_item(item: ItemResource):
	item_resource = item
	if sprite:
		sprite.texture = item.texture
