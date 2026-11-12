extends Node

signal save_completed(success: bool)
signal load_completed(success: bool)

const SAVE_PATH := "user://savegame.json"
const AUTOSAVE_INTERVAL := 120.0

var _autosave_timer: float = 0.0
var autosave_enabled: bool = true

func _process(delta: float) -> void:
	if not autosave_enabled:
		return
	if not get_tree().current_scene:
		return
	if get_tree().current_scene.scene_file_path != "res://scenes/world/world.tscn":
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var data := GameManager.get_save_dict()
	# Sync from live systems if present
	if is_instance_valid(InventoryManager):
		data["inventory_data"] = InventoryManager.get_save_data()
	if is_instance_valid(TimeManager):
		data["world_data"]["day"] = TimeManager.day
		data["world_data"]["time_minutes"] = TimeManager.time_minutes
		data["world_data"]["weather"] = TimeManager.weather
	
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_save_data"):
		var pd: Dictionary = player.get_save_data()
		data["player_data"] = GameManager._serialize_player_data(pd)
		# keep runtime copy in sync
		GameManager.player_data = pd.duplicate(true)
	elif player:
		data["player_data"]["position"] = {"x": player.global_position.x, "y": player.global_position.y}
		GameManager.player_data["position"] = player.global_position

	
	var world := get_tree().get_first_node_in_group("world")
	if world and world.has_method("get_save_data"):
		var world_save: Dictionary = world.get_save_data()
		data["buildings_data"] = world_save.get("buildings", [])
		data["world_objects_data"] = world_save.get("objects", {})
		data["world_data"]["seed"] = world_save.get("seed", data["world_data"].get("seed", 0))
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(true)
	return true

func load_game() -> bool:
	if not has_save():
		load_completed.emit(false)
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		load_completed.emit(false)
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		load_completed.emit(false)
		return false
	GameManager.apply_save_dict(parsed)
	if is_instance_valid(InventoryManager):
		InventoryManager.load_save_data(parsed.get("inventory_data", {}))
	if is_instance_valid(TimeManager):
		TimeManager.day = int(parsed.get("world_data", {}).get("day", 1))
		TimeManager.time_minutes = float(parsed.get("world_data", {}).get("time_minutes", 480.0))
		TimeManager.weather = str(parsed.get("world_data", {}).get("weather", "clear"))
	load_completed.emit(true)
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
