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
var animal_scene := preload("res://scenes/animals/animal.tscn")

var player: Player
var _spawn_timer := 0.0
var _max_enemies := 12
var _max_animals := 10


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
	if _spawn_timer >= 20.0:
		_spawn_timer = 0.0
		_maintain_entities()
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
	var image := Image.create(tile_size * 4, tile_size, false, Image.FORMAT_RGBA8)
	# 0: grass, 1: dirt, 2: sand, 3: water
	image.fill_rect(Rect2i(0, 0, tile_size, tile_size), Color(0.25, 0.55, 0.22, 1))
	image.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), Color(0.45, 0.32, 0.20, 1))
	image.fill_rect(Rect2i(tile_size * 2, 0, tile_size, tile_size), Color(0.76, 0.68, 0.42, 1))
	image.fill_rect(Rect2i(tile_size * 3, 0, tile_size, tile_size), Color(0.20, 0.40, 0.75, 1))
	var tex := ImageTexture.create_from_image(image)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(tile_size, tile_size)
	ts.add_source(source, 0)
	# create tiles
	for i in range(4):
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

func _spawn_resource(scene: PackedScene, pos: Vector2) -> void:
	if scene == null:
		return
	var node := scene.instantiate()
	node.global_position = pos
	resources_container.add_child(node)

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
	_on_time_changed(TimeManager.time_minutes, TimeManager.day)

func _spawn_initial_entities() -> void:
	for i in range(4):
		_spawn_zombie_near_player()
	for i in range(5):
		_spawn_animal_near_player()

func _maintain_entities() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy").size()
	var animals := get_tree().get_nodes_in_group("animal").size()
	if enemies < _max_enemies and TimeManager.is_night():
		_spawn_zombie_near_player()
	elif enemies < 6:
		_spawn_zombie_near_player()
	if animals < _max_animals:
		_spawn_animal_near_player()

func _spawn_zombie_near_player() -> void:
	if player == null: return
	var angle := randf() * TAU
	var dist := randf_range(300, 600)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var z := zombie_scene.instantiate()
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
	# Simple: if build panel open and player has building item, allow placement via click
	pass

func _try_place_building(world_pos: Vector2) -> void:
	# Find if player has any buildable item selected (simplified: place first available buildable)
	var buildables := ["wall_wood", "floor_wood", "door_wood", "campfire", "chest", "workbench"]
	var to_place := ""
	for b in buildables:
		if InventoryManager.has_item(b, 1):
			to_place = b
			break
	if to_place == "":
		return
	if not InventoryManager.remove_item(to_place, 1):
		return
	var building := _create_building_node(to_place)
	if building:
		# Snap to grid
		var snapped := Vector2(snapped(world_pos.x, 32), snapped(world_pos.y, 32))
		building.global_position = snapped
		buildings_container.add_child(building)
		GameManager.buildings_data.append({"type": to_place, "x": snapped.x, "y": snapped.y})

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

