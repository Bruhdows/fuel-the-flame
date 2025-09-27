# ItemResource.gd
extends Resource
class_name ItemResource

@export var name: String
@export var texture: Texture2D
@export var description: String
@export var stack_size: int = 1
@export var item_type: String = "generic"
@export var damage: float = 0.0
@export var food_value: float = 0.0
@export var quantity: int = 1  # Added quantity property

# NEW: how much this item adds to a fire when consumed
@export var fuel_value: int = 0

func _init(item_name: String = "", item_texture: Texture2D = null, item_description: String = "", item_stack_size: int = 1, type: String = "generic"):
	name = item_name
	texture = item_texture
	description = item_description
	stack_size = item_stack_size
	item_type = type
	quantity = 1

func is_weapon() -> bool:
	return item_type == "weapon"

func is_food() -> bool:
	return item_type == "food"

func get_damage() -> float:
	return damage

func get_food_value() -> float:
	return food_value

func is_stackable() -> bool:
	return stack_size > 1

func can_stack_with(other_item: ItemResource) -> bool:
	if not other_item or not is_stackable() or not other_item.is_stackable():
		return false
	return name == other_item.name and item_type == other_item.item_type

func add_quantity(amount: int) -> int:
	var space_available = stack_size - quantity
	var amount_to_add = min(amount, space_available)
	quantity += amount_to_add
	return amount - amount_to_add  # Return leftover amount

func can_add_quantity(amount: int) -> bool:
	return quantity + amount <= stack_size

func is_full_stack() -> bool:
	return quantity >= stack_size

func duplicate_item() -> ItemResource:
	var new_item = ItemResource.new(name, texture, description, stack_size, item_type)
	new_item.damage = damage
	new_item.food_value = food_value
	return new_item

func get_fuel_value() -> int:
	return fuel_value
