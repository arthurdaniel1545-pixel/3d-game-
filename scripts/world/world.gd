extends Node2D

@onready var generator: WorldGenerator = $WorldGenerator
@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var resources_container: Node2D = $Resources
@onready var buildings_container: Node2D = $Buildings
@onready var entities_container: Node2D = $Entities
@onready var day_night_modulate: CanvasModulate = $DayNightModulate
@onready var hud: CanvasLayer = $HUD
@onready var player_spawn: Marker2D = $PlayerSpawn

var player_scene := preload("res://scenes/player/player.tscn")
var tree_scene := preload("res://scenes/objects/tree.tscn")
var rock_scene := preload("res://scenes/objects/rock.tscn")
var berry_scene := preload("res://scenes/objects/berry_bush.tscn")
var zombie_scene := preload("res://scenes/enemies/zombie.tscn")
var fast_zombie_scene := preload("res://scenes/enemies/fast_zombie.tscn")
var tank_zombie_scene := preload("res://scenes/enemies/tank_zombie.tscn")
var wolf_scene := preload("res://scenes/enemies/wolf.tscn")
var animal_scene := preload("res://scenes/animals/animal.tscn")

var loot_chest_scene := preload("res://scenes/objects/loot_chest.tscn")
var metal_scene := preload("res://scenes/objects/scrap_metal.tscn")
var cloth_scene := preload("res://scenes/objects/cloth_pile.tscn")
var herb_scene := preload("res://scenes/objects/herb_plant.tscn")



var player: Player
var _spawn_timer := 0.0
var _horde_timer := 0.0
var _max_enemies := 12
var _max_animals := 10
var _last_horde_day := 0



func _ready() -> void:
	add_to_group("world")
	_setup_terrain_tileset()
	if not GameManager.is_new_game and not GameManager.buildings_data.is_empty():
		# Restore from save - generator seed already in GameManager
		generator.seed = int(GameManager.world_data.get("seed", generator.seed))
		generator.generate()
	else:
		_generate_world()
	_spawn_player()
	_spawn_resources()
	_spawn_initial_entities()
	if not GameManager.is_new_game:
		_restore_buildings()
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.weather_changed.connect(_on_weather_changed)
	call_deferred("_update_weather_effects")
	_on_time_changed(TimeManager.time_minutes, TimeManager.day)


func _restore_buildings() -> void:
	for b in GameManager.buildings_data:
		if b is Dictionary:
			var node := _create_building_node(str(b.get("type", "wall_wood")))
			if node:
				node.global_position = Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
				buildings_container.add_child(node)


func _process(delta: float) -> void:
	_spawn_timer += delta
	_horde_timer += delta
	if _spawn_timer >= 20.0:
		_spawn_timer = 0.0
		_maintain_entities()
	if _horde_timer >= 10.0:
		_horde_timer = 0.0
		_check_horde_event()
	_check_build_placement()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hud and hud.build_open:
			_try_place_building(get_global_mouse_position())
	if event is InputEventScreenTouch and event.pressed:
		if hud and hud.build_open:
			_try_place_building(get_global_mouse_position())


func _setup_terrain_tileset() -> void:
	# Create a simple procedural tileset with colored tiles
	var tile_size := 32
	var image := Image.create(tile_size * 5, tile_size, false, Image.FORMAT_RGBA8)
	# 0: grass, 1: dirt, 2: sand, 3: water, 4: stone_ground
	image.fill_rect(Rect2i(0, 0, tile_size, tile_size), Color(0.25, 0.55, 0.22, 1))
	image.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), Color(0.45, 0.32, 0.20, 1))
	image.fill_rect(Rect2i(tile_size * 2, 0, tile_size, tile_size), Color(0.76, 0.68, 0.42, 1))
	image.fill_rect(Rect2i(tile_size * 3, 0, tile_size, tile_size), Color(0.20, 0.40, 0.75, 1))
	image.fill_rect(Rect2i(tile_size * 4, 0, tile_size, tile_size), Color(0.38, 0.38, 0.40, 1))
	var tex := ImageTexture.create_from_image(image)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(tile_size, tile_size)
	ts.add_source(source, 0)
	# create tiles
	for i in range(5):
		source.create_tile(Vector2i(i, 0))
	terrain_layer.tile_set = ts


func _generate_world() -> void:
	# Render terrain from generator
	for cell in generator.terrain_map.keys():
		var type: String = generator.terrain_map[cell]
		var atlas_x := 0
		match type:
			"grass": atlas_x = 0
			"dirt": atlas_x = 1
			"sand": atlas_x = 2
			"water": atlas_x = 3
			"stone_ground": atlas_x = 4
		terrain_layer.set_cell(cell, 0, Vector2i(atlas_x, 0))


func _spawn_player() -> void:
	player = player_scene.instantiate() as Player
	player.global_position = player_spawn.global_position
	# Apply saved position if continuing
	if not GameManager.is_new_game and GameManager.player_data.has("position"):
		var pos = GameManager.player_data["position"]
		if pos is Vector2 and pos != Vector2.ZERO:
			player.global_position = pos
	entities_container.add_child(player)

func _spawn_resources() -> void:
	# Limit spawn count for performance
	var max_trees := 400
	var max_rocks := 200
	var max_berries := 150
	var max_metal := 80
	var max_cloth := 80
	var max_herbs := 100
	var count := 0
	for pos in generator.tree_positions:
		if count >= max_trees: break
		_spawn_resource(tree_scene, pos)
		count += 1
	count = 0
	for pos in generator.rock_positions:
		if count >= max_rocks: break
		_spawn_resource(rock_scene, pos)
		count += 1
	count = 0
	for pos in generator.berry_positions:
		if count >= max_berries: break
		_spawn_resource(berry_scene, pos)
		count += 1
	count = 0
	for pos in generator.metal_positions:
		if count >= max_metal: break
		_spawn_resource(metal_scene, pos)
		count += 1
	count = 0
	for pos in generator.cloth_positions:
		if count >= max_cloth: break
		_spawn_resource(cloth_scene, pos)
		count += 1
	count = 0
	for pos in generator.herb_positions:
		if count >= max_herbs: break
		_spawn_resource(herb_scene, pos)
		count += 1
	_spawn_pois()


func _spawn_resource(scene: PackedScene, pos: Vector2) -> void:
	if scene == null:
		return
	var node := scene.instantiate()
	node.global_position = pos
	resources_container.add_child(node)

func _spawn_pois() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = generator.seed + 777
	for poi in generator.pois:
		var p: Vector2 = poi["pos"]
		var ptype: String = poi.get("type", "village")
		var radius: float = float(poi.get("radius", 80))
		# Spawn some buildings
		var count := rng.randi_range(2, 5)
		for i in count:
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(20, radius * 0.7)
			var bpos := p + Vector2(cos(ang), sin(ang)) * dist
			bpos = Vector2(snapped(bpos.x, 32), snapped(bpos.y, 32))
			var btype := "wall_wood"
			match ptype:
				"village":
					btype = ["wall_wood", "floor_wood", "door_wood", "campfire"][rng.randi() % 4]
				"city":
					btype = ["wall_wood", "window_wood", "door_wood", "floor_wood", "roof_wood"][rng.randi() % 5]
				"hospital":
					btype = ["wall_wood", "door_wood", "window_wood"][rng.randi() % 3]
				"market":
					btype = ["wall_wood", "door_wood", "floor_wood"][rng.randi() % 3]
				"military":
					btype = ["bunker_wall", "door_wood", "floor_wood"][rng.randi() % 3]
				"cave":
					btype = ["bunker_wall", "wall_wood"][rng.randi() % 2]
			var b := _create_building_node(btype)
			if b:
				b.global_position = bpos
				buildings_container.add_child(b)
		# Spawn loot chests
		var chest_count := rng.randi_range(1, 3)
		for i in chest_count:
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(10, radius * 0.5)
			var cpos := p + Vector2(cos(ang), sin(ang)) * dist
			if loot_chest_scene:
				var chest := loot_chest_scene.instantiate() as LootChest
				match ptype:
					"hospital": chest.chest_type = "medical"
					"military": chest.chest_type = "military"
					"market": chest.chest_type = "food"
					_: chest.chest_type = "generic"
				chest.global_position = cpos
				resources_container.add_child(chest)
		# Spawn extra enemies around dangerous POIs
		if ptype in ["military", "city", "cave"] and zombie_scene:
			for i in rng.randi_range(2, 4):
				var ang := rng.randf() * TAU
				var dist := rng.randf_range(40, radius)
				var z := zombie_scene.instantiate()
				z.global_position = p + Vector2(cos(ang), sin(ang)) * dist
				entities_container.add_child(z)


var _weather_overlay: ColorRect = null
var _build_ghost: ColorRect = null
var _build_ghost_valid: bool = false


func _on_time_changed(_minutes: float, _day: int) -> void:
	var factor := TimeManager.get_daylight_factor()
	var c := lerpf(0.25, 1.0, factor)
	# Weather darkens
	if TimeManager.weather == "rain":
		c *= 0.85
	elif TimeManager.weather == "storm":
		c *= 0.7
	elif TimeManager.weather == "cloudy":
		c *= 0.92
	day_night_modulate.color = Color(c, c, lerpf(0.35, 1.0, factor), 1.0)

func _on_weather_changed(_weather: String) -> void:
	_update_weather_effects()
	_on_time_changed(TimeManager.time_minutes, TimeManager.day)

func _ensure_weather_overlay() -> void:
	if _weather_overlay != null:
		return
	_weather_overlay = ColorRect.new()
	_weather_overlay.name = "WeatherOverlay"
	_weather_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_weather_overlay.color = Color(0, 0, 0, 0)
	if hud:
		hud.add_child(_weather_overlay)
		hud.move_child(_weather_overlay, 0)

func _update_weather_effects() -> void:
	_ensure_weather_overlay()
	if _weather_overlay == null:
		return
	match TimeManager.weather:
		"rain":
			_weather_overlay.color = Color(0.3, 0.4, 0.6, 0.12)
		"storm":
			_weather_overlay.color = Color(0.2, 0.25, 0.4, 0.22)
		"cloudy":
			_weather_overlay.color = Color(0.4, 0.4, 0.45, 0.05)
		_:
			_weather_overlay.color = Color(0, 0, 0, 0)


func _spawn_initial_entities() -> void:
	for i in range(4):
		_spawn_zombie_near_player()
	for i in range(5):
		_spawn_animal_near_player()
	for i in range(2):
		_spawn_wildlife_near_player()


func _maintain_entities() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy").size()
	var animals := get_tree().get_nodes_in_group("animal").size()
	var target_enemies := 6
	if TimeManager.is_night():
		target_enemies = 10
	target_enemies = mini(target_enemies + int(TimeManager.day / 2), _max_enemies)
	if enemies < target_enemies:
		_spawn_zombie_near_player()
	if animals < _max_animals:
		_spawn_animal_near_player()
	# Occasionally spawn hostile wildlife in dangerous areas
	if randf() < 0.3:
		_spawn_wildlife_near_player()

func _spawn_wildlife_near_player() -> void:
	if player == null: return
	var diff := _get_difficulty()
	var scene := animal_scene
	if diff >= 2 and randf() < 0.4:
		scene = wolf_scene
	var angle := randf() * TAU
	var dist := randf_range(200, 500)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var a = scene.instantiate()
	a.global_position = pos
	entities_container.add_child(a)


func _get_difficulty() -> int:
	var diff := 1 + int(TimeManager.day / 3)
	if player and generator:
		var poi := generator.get_poi_at(player.global_position)
		if not poi.is_empty():
			diff = maxi(diff, int(poi.get("difficulty", 1)))
	return clampi(diff, 1, 5)

func _spawn_zombie_near_player() -> void:
	if player == null: return
	var angle := randf() * TAU
	var dist := randf_range(280, 600)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var diff := _get_difficulty()
	var scene := zombie_scene
	var roll := randf()
	if diff >= 3 and roll < 0.25:
		scene = tank_zombie_scene
	elif diff >= 2 and roll < 0.5:
		scene = fast_zombie_scene
	elif TimeManager.is_night() and roll < 0.35:
		scene = fast_zombie_scene
	var z = scene.instantiate()
	z.global_position = pos
	entities_container.add_child(z)

func _check_horde_event() -> void:
	if not TimeManager.is_night():
		return
	if TimeManager.day == _last_horde_day:
		return
	# Horde chance increases with days, guaranteed every few nights
	var chance := 0.2 + TimeManager.day * 0.05
	if randf() > chance and TimeManager.day % 3 != 0:
		return
	_last_horde_day = TimeManager.day
	_spawn_horde()

func _spawn_horde() -> void:
	if player == null:
		return
	if player.has_signal("status_message"):
		player.status_message.emit("Horda noturna se aproxima!")
	var count := 4 + mini(TimeManager.day, 6)
	for i in count:
		var angle := randf() * TAU
		var dist := randf_range(350, 700)
		var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
		var scene := zombie_scene
		var roll := randf()
		if roll < 0.3:
			scene = fast_zombie_scene
		elif roll < 0.45 and TimeManager.day >= 3:
			scene = tank_zombie_scene
		var z = scene.instantiate()
		z.global_position = pos
		entities_container.add_child(z)


func _spawn_animal_near_player() -> void:
	if player == null: return
	var angle := randf() * TAU
	var dist := randf_range(200, 500)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var a := animal_scene.instantiate()
	a.global_position = pos
	entities_container.add_child(a)

var selected_build_item: String = ""

func _check_build_placement() -> void:
	_update_build_ghost()

func _ensure_build_ghost() -> void:
	if _build_ghost != null:
		return
	_build_ghost = ColorRect.new()
	_build_ghost.size = Vector2(30, 30)
	_build_ghost.position = Vector2(-15, -15)
	_build_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ghost.visible = false
	_build_ghost.z_index = 10
	add_child(_build_ghost)

func _update_build_ghost() -> void:
	_ensure_build_ghost()
	if hud == null or not hud.build_open or hud.selected_build_item == "":
		_build_ghost.visible = false
		return
	_build_ghost.visible = true
	var world_pos := get_global_mouse_position()
	var snapped := Vector2(snapped(world_pos.x, 32), snapped(world_pos.y, 32))
	_build_ghost.global_position = snapped
	_build_ghost_valid = _is_valid_build_position(snapped, hud.selected_build_item)
	_build_ghost.color = Color(0.2, 0.9, 0.2, 0.45) if _build_ghost_valid else Color(0.9, 0.2, 0.2, 0.45)

func _is_valid_build_position(pos: Vector2, item_id: String) -> bool:
	if not InventoryManager.has_item(item_id, 1):
		return false
	# Check terrain - don't place on water
	if generator:
		var cell := Vector2i(int(round(pos.x / 32.0)), int(round(pos.y / 32.0)))
		var terrain = generator.terrain_map.get(cell, "grass")
		if terrain == "water":
			return false
	# Check overlap with existing buildings
	for b in buildings_container.get_children():
		if b is Node2D and b.global_position.distance_to(pos) < 24.0:
			return false
	# Check distance from player (reasonable range)
	if player and player.global_position.distance_to(pos) > 180.0:
		return false
	return true


func _try_place_building(world_pos: Vector2) -> void:
	var buildables := ["wall_wood", "floor_wood", "door_wood", "roof_wood", "window_wood", "bunker_wall", "campfire", "chest", "workbench"]
	var to_place := ""
	if hud and hud.selected_build_item != "":
		to_place = hud.selected_build_item
	else:
		for b in buildables:
			if InventoryManager.has_item(b, 1):
				to_place = b
				break
	if to_place == "":
		return
	var snapped := Vector2(snapped(world_pos.x, 32), snapped(world_pos.y, 32))
	if not _is_valid_build_position(snapped, to_place):
		return
	if not InventoryManager.remove_item(to_place, 1):
		return
	var building := _create_building_node(to_place)
	if building:
		building.global_position = snapped
		buildings_container.add_child(building)
		GameManager.buildings_data.append({"type": to_place, "x": snapped.x, "y": snapped.y})
		if player and player.has_signal("status_message"):
			player.status_message.emit("Construído: %s" % to_place)
	_update_build_ghost()



func _create_building_node(item_id: String) -> Node2D:
	var node := StaticBody2D.new()
	node.collision_layer = 32 # buildings
	node.collision_mask = 0
	node.add_to_group("building")
	var rect := ColorRect.new()
	rect.size = Vector2(30, 30)
	rect.position = Vector2(-15, -15)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	col.shape = shape
	node.add_child(rect)
	node.add_child(col)
	match item_id:
		"wall_wood":
			rect.color = Color(0.45, 0.30, 0.15)
		"floor_wood":
			rect.color = Color(0.55, 0.40, 0.22)
			node.collision_layer = 0
		"door_wood":
			rect.color = Color(0.35, 0.22, 0.10)
		"roof_wood":
			rect.color = Color(0.35, 0.25, 0.12)
			node.collision_layer = 0
		"window_wood":
			rect.color = Color(0.45, 0.55, 0.65, 0.8)
		"bunker_wall":
			rect.color = Color(0.35, 0.35, 0.38)
		"campfire":
			rect.color = Color(0.9, 0.4, 0.1)
			node.collision_layer = 0
		"chest":
			rect.color = Color(0.5, 0.35, 0.18)
		"workbench":
			rect.color = Color(0.4, 0.28, 0.14)
		_:
			rect.color = Color(0.5, 0.5, 0.5)

	node.set_meta("building_type", item_id)
	return node


func get_save_data() -> Dictionary:
	# Collect buildings from container
	var buildings := []
	for child in buildings_container.get_children():
		if child.has_meta("building_type"):
			buildings.append({
				"type": child.get_meta("building_type"),
				"x": child.global_position.x,
				"y": child.global_position.y
			})
	GameManager.buildings_data = buildings
	return {
		"seed": generator.seed,
		"buildings": buildings,
		"objects": GameManager.world_objects_data.duplicate(true)
	}

func apply_save_data(data: Dictionary) -> void:
	generator.load_save_data(data)
	# Restore buildings
	var buildings = data.get("buildings", [])
	for b in buildings:
		var node := _create_building_node(str(b.get("type", "wall_wood")))
		if node:
			node.global_position = Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
			buildings_container.add_child(node)
	GameManager.buildings_data = buildings.duplicate(true)

