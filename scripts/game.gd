extends Node2D

@onready var player: CharacterBody2D = %Player

const ENEMY = preload("uid://bgdracsuhgysh")

func create_sword_item() -> ItemResource:
	var sword_texture = preload("res://assets/wooden_sword.png")
	return ItemResource.new("Wooden Sword", sword_texture, "An weak wooden sword", 1, "weapon")
	
func _ready() -> void:
	var sword = create_sword_item()
	sword.damage = 10
	player.add_item(sword)
	
	var enemy = ENEMY.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
