extends RefCounted
class_name POIGenerator

# Generates points of interest and structure data for the world

static func generate_pois(seed_val: int, map_size: Vector2i) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val + 999
	var pois: Array[Dictionary] = []
	var half := map_size / 2
	
	# Villages
	for i in range(3):
		pois.append({
			"type": "village",
			"pos": Vector2(rng.randi_range(-half.x + 40, half.x - 40) * 32, rng.randi_range(-half.y + 40, half.y - 40) * 32),
			"radius": rng.randi_range(80, 140),
			"difficulty": 1
		})
	# Abandoned cities
	for i in range(2):
		pois.append({
			"type": "city",
			"pos": Vector2(rng.randi_range(-half.x + 50, half.x - 50) * 32, rng.randi_range(-half.y + 50, half.y - 50) * 32),
			"radius": rng.randi_range(120, 200),
			"difficulty": 2
		})
	# Hospitals
	for i in range(2):
		pois.append({
			"type": "hospital",
			"pos": Vector2(rng.randi_range(-half.x + 30, half.x - 30) * 32, rng.randi_range(-half.y + 30, half.y - 30) * 32),
			"radius": rng.randi_range(60, 90),
			"difficulty": 2
		})
	# Markets
	for i in range(2):
		pois.append({
			"type": "market",
			"pos": Vector2(rng.randi_range(-half.x + 30, half.x - 30) * 32, rng.randi_range(-half.y + 30, half.y - 30) * 32),
			"radius": rng.randi_range(50, 80),
			"difficulty": 1
		})
	# Military bases
	for i in range(2):
		pois.append({
			"type": "military",
			"pos": Vector2(rng.randi_range(-half.x + 40, half.x - 40) * 32, rng.randi_range(-half.y + 40, half.y - 40) * 32),
			"radius": rng.randi_range(80, 120),
			"difficulty": 3
		})
	# Caves (dangerous regions)
	for i in range(3):
		pois.append({
			"type": "cave",
			"pos": Vector2(rng.randi_range(-half.x + 30, half.x - 30) * 32, rng.randi_range(-half.y + 30, half.y - 30) * 32),
			"radius": rng.randi_range(60, 100),
			"difficulty": 3
		})
	return pois

static func get_biome_at(pos: Vector2, seed_val: int) -> String:
	var noise := FastNoiseLite.new()
	noise.seed = seed_val + 500
	noise.frequency = 0.003
	var val := noise.get_noise_2d(pos.x, pos.y)
	if val < -0.25:
		return "forest"
	elif val < 0.1:
		return "plains"
	elif val < 0.3:
		return "dangerous"
	else:
		return "wasteland"

static func get_difficulty_at(pos: Vector2, pois: Array[Dictionary], day: int) -> int:
	var base := 1 + int(day / 3)
	for poi in pois:
		if pos.distance_to(poi["pos"]) < poi["radius"]:
			base = maxi(base, int(poi.get("difficulty", 1)))
	return clampi(base, 1, 5)
