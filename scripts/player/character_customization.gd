extends RefCounted
class_name CharacterCustomization

const HAIR_STYLES := ["Curto", "Médio", "Longo", "Raspado"]
const OUTFITS := ["basic", "adventurer", "survivor", "warm"]

static func default_customization() -> Dictionary:
	return {
		"hair_style": 0,
		"hair_color": Color(0.35, 0.22, 0.12),
		"skin_color": Color(0.93, 0.78, 0.67),
		"eye_color": Color(0.2, 0.45, 0.7),
		"outfit": "basic",
		"name": "Sobrevivente"
	}

static func randomize_customization() -> Dictionary:
	var hair_colors := [
		Color(0.15, 0.10, 0.08),
		Color(0.35, 0.22, 0.12),
		Color(0.65, 0.45, 0.20),
		Color(0.85, 0.75, 0.45),
		Color(0.2, 0.2, 0.2)
	]
	var skin_colors := [
		Color(0.96, 0.87, 0.77),
		Color(0.93, 0.78, 0.67),
		Color(0.82, 0.64, 0.50),
		Color(0.62, 0.45, 0.33),
		Color(0.45, 0.32, 0.24)
	]
	var eye_colors := [
		Color(0.2, 0.45, 0.7),
		Color(0.25, 0.55, 0.25),
		Color(0.45, 0.30, 0.20),
		Color(0.3, 0.3, 0.3)
	]
	return {
		"hair_style": randi() % HAIR_STYLES.size(),
		"hair_color": hair_colors[randi() % hair_colors.size()],
		"skin_color": skin_colors[randi() % skin_colors.size()],
		"eye_color": eye_colors[randi() % eye_colors.size()],
		"outfit": OUTFITS[randi() % OUTFITS.size()],
		"name": "Sobrevivente"
	}

static func get_sprite_base_path(gender: String) -> String:
	if gender == "female":
		return "res://assets/characters/female/"
	return "res://assets/characters/male/"

static func get_walk_frames_path(gender: String, direction: String) -> String:
	var base := get_sprite_base_path(gender)
	if gender == "female":
		# Female uses capitalized naming
		match direction:
			"down": return base + "Walk/walk_Down.png"
			"up": return base + "Walk/walk_Up.png"
			"left_down": return base + "Walk/walk_Left_Down.png"
			"left_up": return base + "Walk/walk_Left_Up.png"
			"right_down": return base + "Walk/walk_Right_Down.png"
			"right_up": return base + "Walk/walk_Right_Up.png"
			_: return base + "Walk/walk_Down.png"
	else:
		match direction:
			"down": return base + "Walk/walk_down.png"
			"up": return base + "Walk/walk_up.png"
			"left_down": return base + "Walk/walk_left_down.png"
			"left_up": return base + "Walk/walk_left_up.png"
			"right_down": return base + "Walk/walk_right_down.png"
			"right_up": return base + "Walk/walk_right_up.png"
			_: return base + "Walk/walk_down.png"

static func get_idle_frames_path(gender: String, direction: String) -> String:
	var base := get_sprite_base_path(gender)
	if gender == "female":
		match direction:
			"down": return base + "Idle/Idle_Down.png"
			"up": return base + "Idle/Idle_Up.png"
			"left_down": return base + "Idle/Idle_Left_Down.png"
			"left_up": return base + "Idle/Idle_Left_Up.png"
			"right_down": return base + "Idle/Idle_Right_Down.png"
			"right_up": return base + "Idle/Idle_Right_Up.png"
			_: return base + "Idle/Idle_Down.png"
	else:
		match direction:
			"down": return base + "Idle/idle_down.png"
			"up": return base + "Idle/idle_up.png"
			"left_down": return base + "Idle/idle_left_down.png"
			"left_up": return base + "Idle/idle_left_up.png"
			"right_down": return base + "Idle/idle_right_down.png"
			"right_up": return base + "Idle/idle_right_up.png"
			_: return base + "Idle/idle_down.png"

static func get_preview_texture_path(gender: String) -> String:
	var base := get_sprite_base_path(gender)
	if gender == "female":
		return base + "Idle/Idle_Down.png"
	return base + "Idle/idle_down.png"
