extends Resource
class_name ItemResource

@export var name: String
@export var texture: Texture2D
@export var description: String
@export var stack_size: int = 1
@export var item_type: String = "generic"
@export var damage: float = 0.0
@export var food_value: float = 0.0

func _init(item_name: String = "", item_texture: Texture2D = null, item_description: String = "", item_stack_size: int = 1, type: String = "generic"):
	name = item_name
	texture = item_texture
	description = item_description
	stack_size = item_stack_size
	item_type = type

func is_weapon() -> bool:
	return item_type == "weapon"

func is_food() -> bool:
	return item_type == "food"

func get_damage() -> float:
	return damage

func get_food_value() -> float:
	return food_value
