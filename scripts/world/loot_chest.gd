extends Area2D
class_name LootChest

@export var loot_table: Array[Dictionary] = []
@export var chest_type: String = "generic" # generic, medical, military, food
@export var opened: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	add_to_group("loot")
	if loot_table.is_empty():
		_generate_loot_table()

func _generate_loot_table() -> void:
	match chest_type:
		"medical":
			loot_table = [
				{"item": "bandage", "min": 1, "max": 3, "chance": 0.9},
				{"item": "medkit", "min": 1, "max": 1, "chance": 0.4},
				{"item": "herbs", "min": 1, "max": 4, "chance": 0.7},
				{"item": "water", "min": 1, "max": 2, "chance": 0.5},
			]
		"military":
			loot_table = [
				{"item": "pistol", "min": 1, "max": 1, "chance": 0.25},
				{"item": "rifle", "min": 1, "max": 1, "chance": 0.1},
				{"item": "ammo_pistol", "min": 5, "max": 20, "chance": 0.5},
				{"item": "armor_vest", "min": 1, "max": 1, "chance": 0.2},
				{"item": "helmet_basic", "min": 1, "max": 1, "chance": 0.2},
				{"item": "canned_food", "min": 1, "max": 3, "chance": 0.6},
			]
		"food":
			loot_table = [
				{"item": "canned_food", "min": 1, "max": 3, "chance": 0.8},
				{"item": "water", "min": 1, "max": 3, "chance": 0.7},
				{"item": "food_berry", "min": 2, "max": 5, "chance": 0.6},
				{"item": "food_cooked_meat", "min": 1, "max": 2, "chance": 0.3},
			]
		_:
			loot_table = [
				{"item": "wood", "min": 2, "max": 6, "chance": 0.6},
				{"item": "stone", "min": 2, "max": 5, "chance": 0.5},
				{"item": "cloth", "min": 1, "max": 3, "chance": 0.4},
				{"item": "scrap_metal", "min": 1, "max": 3, "chance": 0.3},
				{"item": "bandage", "min": 1, "max": 2, "chance": 0.3},
				{"item": "canned_food", "min": 1, "max": 2, "chance": 0.25},
			]

func interact(player: Node) -> void:
	if opened:
		return
	opened = true
	var got_any := false
	for entry in loot_table:
		if randf() <= float(entry.get("chance", 0.5)):
			var count := randi_range(int(entry.get("min", 1)), int(entry.get("max", 1)))
			InventoryManager.add_item(str(entry.get("item")), count)
			got_any = true
	# Visual feedback
	if sprite:
		sprite.modulate = Color(0.6, 0.6, 0.6)
	if got_any and player and player.has_method("status_message" if false else ""):
		pass
	# Mark for removal after looting (or keep as opened)
	queue_free()

func get_save_data() -> Dictionary:
	return {"type": chest_type, "x": global_position.x, "y": global_position.y, "opened": opened}
