extends Node
class_name WorldGenerator

@export var map_size: Vector2i = Vector2i(256, 256)
@export var seed: int = 12345

var noise_terrain: FastNoiseLite
var noise_trees: FastNoiseLite
var noise_rocks: FastNoiseLite

var terrain_map: Dictionary = {}
var tree_positions: Array[Vector2] = []
var rock_positions: Array[Vector2] = []
var berry_positions: Array[Vector2] = []

func _ready() -> void:
	if GameManager.world_data.has("seed") and GameManager.world_data["seed"] != 0:
		seed = int(GameManager.world_data["seed"])
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
	
	generate()

func generate() -> void:
	terrain_map.clear()
	tree_positions.clear()
	rock_positions.clear()
	berry_positions.clear()
	var half := map_size / 2
	for x in range(-half.x, half.x):
		for y in range(-half.y, half.y):
			var val := noise_terrain.get_noise_2d(x, y)
			if val < -0.35:
				terrain_map[Vector2i(x,y)] = "water"
			elif val < -0.1:
				terrain_map[Vector2i(x,y)] = "sand"
			elif val < 0.4:
				terrain_map[Vector2i(x,y)] = "grass"
			else:
				terrain_map[Vector2i(x,y)] = "dirt"
	
	# Place resources
	for x in range(-half.x + 10, half.x - 10):
		for y in range(-half.y + 10, half.y - 10):
			var cell := Vector2i(x,y)
			if terrain_map.get(cell, "grass") != "grass":
				continue
			var tval := noise_trees.get_noise_2d(x, y)
			if tval > 0.3 and randf() < 0.08:
				tree_positions.append(Vector2(x * 32, y * 32))
			var rval := noise_rocks.get_noise_2d(x, y)
			if rval > 0.4 and randf() < 0.04:
				rock_positions.append(Vector2(x * 32, y * 32))
			if tval > -0.2 and tval < 0.1 and randf() < 0.02:
				berry_positions.append(Vector2(x * 32, y * 32))

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
