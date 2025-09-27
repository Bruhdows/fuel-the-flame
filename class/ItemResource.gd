extends Resource
class_name ItemResource

@export var name: String
@export var texture: Texture2D
@export var description: String
@export var stack_size: int = 1

func _init(item_name: String = "", item_texture: Texture2D = null, item_description: String = "", item_stack_size: int = 1):
	name = item_name
	texture = item_texture
	description = item_description
	stack_size = item_stack_size
