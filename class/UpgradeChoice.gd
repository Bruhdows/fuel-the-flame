extends Resource
class_name UpgradeChoice

@export var name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: String = "common"
@export var category: String = "combat"

var effects: Array[UpgradeEffect] = []

func add_effect(stat: String, value: float, is_multiplicative: bool = false) -> void:
	var effect: UpgradeEffect = UpgradeEffect.new()
	effect.stat_name = stat
	effect.value = value
	effect.is_multiplicative = is_multiplicative
	effects.append(effect)
