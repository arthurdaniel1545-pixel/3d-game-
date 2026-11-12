extends Node
class_name WorldGenerator

@export var map_size: Vector2i = Vector2i(256, 256)
@export var seed: int = 12345

var noise_terrain: FastNoiseLite
var noise_trees: FastNoiseLite
var noise_rocks: FastNoiseLite
var noise_moisture: FastNoiseLite

var terrain_map: Dictionary = {}
var tree_positions: Array[Vector2] = []
var rock_positions: Array[Vector2] = []
var berry_positions: Array[Vector2] = []
var metal_positions: Array[Vector2] = []
var cloth_positions: Array[Vector2] = []
var herb_positions: Array[Vector2] = []
var pois: Array[Dictionary] = []


func _ready() -> void:
	if GameManager.world_data.has("seed") and GameManager.world_data["seed"] != 0:
		seed = int(GameManager.world_data["seed"])
	_init_noise()
	generate()

func _init_noise() -> void:
	noise_terrain = FastNoiseLite.new()
	noise_terrain.seed = seed
	noise_terrain.frequency = 0.01
	noise_terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	noise_trees = FastNoiseLite.new()
	noise_trees.seed = seed + 100
	noise_trees.frequency = 0.05
	
	noise_rocks = FastNoiseLite.new()
	noise_rocks.seed = seed + 200
	noise_rocks.frequency = 0.08
	
	noise_moisture = FastNoiseLite.new()
	noise_moisture.seed = seed + 300
	noise_moisture.frequency = 0.02


func generate() -> void:
	terrain_map.clear()
	tree_positions.clear()
	rock_positions.clear()
	berry_positions.clear()
	metal_positions.clear()
	cloth_positions.clear()
	herb_positions.clear()
	var half := map_size / 2
	for x in range(-half.x, half.x):
		for y in range(-half.y, half.y):
			var val := noise_terrain.get_noise_2d(x, y)
			var moisture := noise_moisture.get_noise_2d(x, y)
			if val < -0.38:
				terrain_map[Vector2i(x,y)] = "water"
			elif val < -0.12:
				terrain_map[Vector2i(x,y)] = "sand"
			elif val < 0.35:
				# Biome variation: forest-like in moist areas
				terrain_map[Vector2i(x,y)] = "grass" if moisture > -0.1 else "dirt"
			elif val < 0.55:
				terrain_map[Vector2i(x,y)] = "dirt"
			else:
				terrain_map[Vector2i(x,y)] = "stone_ground"
	
	# Generate POIs
	pois = POIGenerator.generate_pois(seed, map_size)
	
	# Place resources with biome/POI awareness
	for x in range(-half.x + 10, half.x - 10):
		for y in range(-half.y + 10, half.y - 10):
			var cell := Vector2i(x,y)
			var terrain = terrain_map.get(cell, "grass")
			if terrain == "water":
				continue
			var world_pos := Vector2(x * 32, y * 32)
			var tval := noise_trees.get_noise_2d(x, y)
			var rval := noise_rocks.get_noise_2d(x, y)
			var mval := noise_moisture.get_noise_2d(x, y)
			var biome := POIGenerator.get_biome_at(world_pos, seed)
			
			# Trees denser in forest biomes
			var tree_chance := 0.08
			if biome == "forest": tree_chance = 0.14
			elif biome == "dangerous": tree_chance = 0.05
			if terrain in ["grass", "dirt"] and tval > 0.25 and randf() < tree_chance:
				tree_positions.append(world_pos)
			
			# Rocks
			if terrain in ["grass", "dirt", "sand", "stone_ground"] and rval > 0.35 and randf() < 0.045:
				rock_positions.append(world_pos)
			
			# Berries/herbs in plains/forest
			if terrain in ["grass", "dirt"] and tval > -0.25 and tval < 0.15 and randf() < 0.025:
				berry_positions.append(world_pos)
			if terrain in ["grass", "dirt"] and mval > 0.2 and randf() < 0.015:
				herb_positions.append(world_pos)
			
			# Scrap metal and cloth near POIs (cities, military, villages)
			var near_poi := false
			var poi_type := ""
			for poi in pois:
				if world_pos.distance_to(poi["pos"]) < poi["radius"] * 1.2:
					near_poi = true
					poi_type = poi["type"]
					break
			if near_poi and randf() < 0.02:
				if poi_type in ["city", "military", "village"]:
					metal_positions.append(world_pos)
				if poi_type in ["city", "village", "hospital", "market"]:
					cloth_positions.append(world_pos)
			# Occasional scrap in dangerous/wasteland
			if biome in ["dangerous", "wasteland"] and randf() < 0.008:
				metal_positions.append(world_pos)

func get_poi_at(pos: Vector2) -> Dictionary:
	for poi in pois:
		if pos.distance_to(poi["pos"]) < poi.get("radius", 50):
			return poi
	return {}


func get_save_data() -> Dictionary:
	return {
		"seed": seed,
		"tree_positions": tree_positions,
		"rock_positions": rock_positions,
		"berry_positions": berry_positions
	}

func load_save_data(data: Dictionary) -> void:
	seed = int(data.get("seed", seed))
	tree_positions.assign(data.get("tree_positions", []))
	rock_positions.assign(data.get("rock_positions", []))
	berry_positions.assign(data.get("berry_positions", []))
	noise_terrain = FastNoiseLite.new()
	noise_terrain.seed = seed
	noise_terrain.frequency = 0.01
	noise_trees = FastNoiseLite.new()
	noise_trees.seed = seed + 100
	noise_trees.frequency = 0.05
	noise_rocks = FastNoiseLite.new()
	noise_rocks.seed = seed + 200
	noise_rocks.frequency = 0.08
	generate()
