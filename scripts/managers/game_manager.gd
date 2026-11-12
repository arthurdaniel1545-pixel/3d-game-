extends Node

signal game_started
signal game_loaded
signal character_selected(data: Dictionary)

const DEFAULT_SAVE_PATH := "user://savegame.json"

var is_new_game: bool = true
var current_save_path: String = DEFAULT_SAVE_PATH

var selected_gender: String = "male" # "male" or "female"
var character_customization: Dictionary = {
	"hair_style": 0,
	"hair_color": Color(0.35, 0.22, 0.12),
	"skin_color": Color(0.93, 0.78, 0.67),
	"eye_color": Color(0.2, 0.45, 0.7),
	"outfit": "basic",
	"name": "Sobrevivente"
}

var player_data: Dictionary = {
	"position": Vector2.ZERO,
	"health": 100.0,
	"max_health": 100.0,
	"hunger": 100.0,
	"max_hunger": 100.0,
	"thirst": 100.0,
	"max_thirst": 100.0,
	"energy": 100.0,
	"max_energy": 100.0,
	"sleep": 100.0,
	"max_sleep": 100.0,
	"wounds": 0.0,
	"sickness": 0.0,
	"temperature": 37.0,
	"equipped_weapon": "knife"
}


var world_data: Dictionary = {
	"seed": 0,
	"day": 1,
	"time_minutes": 480.0, # 08:00
	"weather": "clear"
}

var inventory_data: Dictionary = {}
var buildings_data: Array = []
var world_objects_data: Dictionary = {}

func _ready() -> void:
	randomize()

func reset_new_game() -> void:
	is_new_game = true
	world_data.seed = randi()
	world_data.day = 1
	world_data.time_minutes = 480.0
	world_data.weather = "clear"
	player_data = {
		"position": Vector2.ZERO,
		"health": 100.0,
		"max_health": 100.0,
		"hunger": 100.0,
		"max_hunger": 100.0,
		"thirst": 100.0,
		"max_thirst": 100.0,
		"energy": 100.0,
		"max_energy": 100.0,
		"sleep": 100.0,
		"max_sleep": 100.0,
		"wounds": 0.0,
		"sickness": 0.0,
		"temperature": 37.0,
		"equipped_weapon": "knife"
	}
	inventory_data = {}
	buildings_data = []
	world_objects_data = {}


func set_character_selection(gender: String, customization: Dictionary) -> void:
	selected_gender = gender
	character_customization = customization.duplicate(true)
	character_selected.emit({
		"gender": selected_gender,
		"customization": character_customization
	})

func start_new_game() -> void:
	reset_new_game()
	is_new_game = true
	# Starting kit
	InventoryManager.clear()
	InventoryManager.add_item("food_berry", 5)
	InventoryManager.add_item("water", 2)
	InventoryManager.add_item("knife", 1)
	InventoryManager.add_item("axe", 1)
	InventoryManager.add_item("bandage", 2)
	InventoryManager.add_item("cloth", 2)
	InventoryManager.add_item("herbs", 1)
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")



func continue_game() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
		is_new_game = false
		game_loaded.emit()
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
	else:
		go_to_character_selection()


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func go_to_character_selection() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/character_selection.tscn")

func go_to_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")

func quit_game() -> void:
	get_tree().quit()

func get_save_dict() -> Dictionary:
	return {
		"selected_gender": selected_gender,
		"character_customization": _serialize_customization(character_customization),
		"player_data": _serialize_player_data(player_data),
		"world_data": world_data.duplicate(true),
		"inventory_data": inventory_data.duplicate(true),
		"buildings_data": buildings_data.duplicate(true),
		"world_objects_data": world_objects_data.duplicate(true)
	}

func apply_save_dict(data: Dictionary) -> void:
	selected_gender = data.get("selected_gender", "male")
	character_customization = _deserialize_customization(data.get("character_customization", {}))
	player_data = _deserialize_player_data(data.get("player_data", {}))
	world_data = data.get("world_data", world_data).duplicate(true)
	inventory_data = data.get("inventory_data", {}).duplicate(true)
	buildings_data = data.get("buildings_data", []).duplicate(true)
	world_objects_data = data.get("world_objects_data", {}).duplicate(true)

func _serialize_customization(c: Dictionary) -> Dictionary:
	var out := c.duplicate(true)
	for key in ["hair_color", "skin_color", "eye_color"]:
		if out.has(key) and out[key] is Color:
			out[key] = (out[key] as Color).to_html()
	return out

func _deserialize_customization(c: Dictionary) -> Dictionary:
	var base := {
		"hair_style": 0,
		"hair_color": Color(0.35, 0.22, 0.12),
		"skin_color": Color(0.93, 0.78, 0.67),
		"eye_color": Color(0.2, 0.45, 0.7),
		"outfit": "basic",
		"name": "Sobrevivente"
	}
	for k in c.keys():
		if k in ["hair_color", "skin_color", "eye_color"] and c[k] is String:
			base[k] = Color.from_string(c[k], base[k])
		else:
			base[k] = c[k]
	return base

func _serialize_player_data(p: Dictionary) -> Dictionary:
	var out := p.duplicate(true)
	if out.has("position") and out["position"] is Vector2:
		out["position"] = {"x": out["position"].x, "y": out["position"].y}
	return out

func _deserialize_player_data(p: Dictionary) -> Dictionary:
	var out := player_data.duplicate(true)
	for k in p.keys():
		if k == "position" and p[k] is Dictionary:
			out[k] = Vector2(p[k].get("x", 0), p[k].get("y", 0))
		else:
			out[k] = p[k]
	return out
