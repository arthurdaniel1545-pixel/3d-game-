extends CharacterBody2D
class_name Player

signal health_changed(current: float, max_value: float)
signal hunger_changed(current: float, max_value: float)
signal thirst_changed(current: float, max_value: float)
signal energy_changed(current: float, max_value: float)
signal died
signal inventory_toggled

@export var walk_speed: float = 110.0
@export var run_speed: float = 170.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var interact_ray: RayCast2D = $InteractRay
@onready var attack_cooldown: Timer = $AttackCooldown

var gender: String = "male"
var customization: Dictionary = {}

var health: float = 100.0
var max_health: float = 100.0
var hunger: float = 100.0
var max_hunger: float = 100.0
var thirst: float = 100.0
var max_thirst: float = 100.0
var energy: float = 100.0
var max_energy: float = 100.0
var temperature: float = 37.0

var facing_dir: String = "down"
var is_running: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var equipped_weapon: String = "knife" # knife, pistol, etc.

var _hunger_timer: float = 0.0
var _thirst_timer: float = 0.0
var _energy_regen_timer: float = 0.0
var _temp_timer: float = 0.0

var projectile_scene: PackedScene = preload("res://scenes/objects/projectile.tscn")


func _ready() -> void:
	add_to_group("player")
	gender = GameManager.selected_gender
	customization = GameManager.character_customization.duplicate(true)
	_load_stats_from_manager()
	_setup_animations()
	_update_hud_signals()

func _load_stats_from_manager() -> void:
	var p := GameManager.player_data
	health = float(p.get("health", max_health))
	max_health = float(p.get("max_health", 100.0))
	hunger = float(p.get("hunger", max_hunger))
	max_hunger = float(p.get("max_hunger", 100.0))
	thirst = float(p.get("thirst", max_thirst))
	max_thirst = float(p.get("max_thirst", 100.0))
	energy = float(p.get("energy", max_energy))
	max_energy = float(p.get("max_energy", 100.0))
	if GameManager.player_data.has("position") and GameManager.player_data["position"] is Vector2:
		var pos: Vector2 = GameManager.player_data["position"]
		if pos != Vector2.ZERO or not GameManager.is_new_game:
			global_position = pos

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	is_running = Input.is_action_pressed("run") and energy > 5.0 and input_dir != Vector2.ZERO
	var speed := run_speed if is_running else walk_speed
	velocity = input_dir * speed
	move_and_slide()
	
	_update_facing(input_dir)
	_update_animation(input_dir)
	_update_survival(delta, input_dir)
	
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _update_facing(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	# 8 directions mapped to available 6-direction sprites
	var angle := dir.angle()
	# Convert to octant
	var oct := int(round(angle / (PI / 4.0))) # -4..4
	match oct:
		0: facing_dir = "right_down" # right (approx) - will flip logic handled in anim
		1: facing_dir = "right_down"
		2: facing_dir = "down"
		3: facing_dir = "left_down"
		4, -4: facing_dir = "left_down" # left
		-3: facing_dir = "left_up"
		-2: facing_dir = "up"
		-1: facing_dir = "right_up"
	# Better mapping for 8 dirs
	if dir.x > 0.5 and abs(dir.y) < 0.35:
		facing_dir = "right_down" # use as right, mirror in sprite
		animated_sprite.flip_h = true
	elif dir.x < -0.5 and abs(dir.y) < 0.35:
		facing_dir = "left_down" # use as left
		animated_sprite.flip_h = false
	elif dir.y > 0.5 and abs(dir.x) < 0.35:
		facing_dir = "down"
		animated_sprite.flip_h = false
	elif dir.y < -0.5 and abs(dir.x) < 0.35:
		facing_dir = "up"
		animated_sprite.flip_h = false
	elif dir.x > 0 and dir.y > 0:
		facing_dir = "right_down"
		animated_sprite.flip_h = false
	elif dir.x < 0 and dir.y > 0:
		facing_dir = "left_down"
		animated_sprite.flip_h = false
	elif dir.x > 0 and dir.y < 0:
		facing_dir = "right_up"
		animated_sprite.flip_h = false
	elif dir.x < 0 and dir.y < 0:
		facing_dir = "left_up"
		animated_sprite.flip_h = false

func _update_animation(dir: Vector2) -> void:
	var prefix := "run_" if is_running else "walk_"
	if dir == Vector2.ZERO:
		prefix = "idle_"
	var anim_name := prefix + facing_dir
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		# fallback to walk/idle down
		anim_name = prefix + "down"
		if not animated_sprite.sprite_frames.has_animation(anim_name):
			anim_name = "idle_down"
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var directions := ["down", "up", "left_down", "right_down", "left_up", "right_up"]
	var frame_count := 6
	var frame_size := Vector2i(64, 64)
	
	for dir in directions:
		# Walk
		var walk_path := CharacterCustomization.get_walk_frames_path(gender, dir)
		_add_strip_animation(frames, "walk_" + dir, walk_path, frame_count, frame_size, 10.0, true)
		_add_strip_animation(frames, "run_" + dir, walk_path, frame_count, frame_size, 14.0, true)
		# Idle
		var idle_path := CharacterCustomization.get_idle_frames_path(gender, dir)
		_add_strip_animation(frames, "idle_" + dir, idle_path, frame_count, frame_size, 6.0, true)
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle_down")
	# Apply simple skin tint to visualize customization
	var skin: Color = customization.get("skin_color", Color(0.93, 0.78, 0.67))
	animated_sprite.modulate = skin.lerp(Color.WHITE, 0.4)

func _add_strip_animation(frames: SpriteFrames, anim_name: String, tex_path: String, count: int, frame_size: Vector2i, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	if not ResourceLoader.exists(tex_path):
		return
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim_name, atlas)

func _update_survival(delta: float, dir: Vector2) -> void:
	_hunger_timer += delta
	_thirst_timer += delta
	_temp_timer += delta
	if _hunger_timer >= 30.0:
		_hunger_timer = 0.0
		hunger = maxf(hunger - 1.5, 0.0)
		hunger_changed.emit(hunger, max_hunger)
	if _thirst_timer >= 20.0:
		_thirst_timer = 0.0
		thirst = maxf(thirst - 2.0, 0.0)
		thirst_changed.emit(thirst, max_thirst)
	
	if dir != Vector2.ZERO and is_running:
		energy = maxf(energy - delta * 8.0, 0.0)
		energy_changed.emit(energy, max_energy)
	elif dir == Vector2.ZERO:
		energy = minf(energy + delta * 6.0, max_energy)
		energy_changed.emit(energy, max_energy)
	elif dir != Vector2.ZERO:
		energy = minf(energy + delta * 1.5, max_energy)
		energy_changed.emit(energy, max_energy)
	
	# Temperature/shelter: cold at night or in storm without nearby building
	if _temp_timer >= 10.0:
		_temp_timer = 0.0
		var temp := TimeManager.temperature_c
		var sheltered := _is_sheltered()
		if (temp < 10.0 or TimeManager.is_night()) and not sheltered:
			health = maxf(health - 1.0, 0.0)
			health_changed.emit(health, max_health)
	
	# Starvation/dehydration damage
	if hunger <= 0.0 or thirst <= 0.0:
		receive_damage(delta * 2.0)

func _is_sheltered() -> bool:
	var buildings := get_tree().get_nodes_in_group("building")
	if buildings.is_empty():
		# Also check world buildings container by distance
		var world := get_tree().get_first_node_in_group("world")
		if world and world.has_node("Buildings"):
			for b in world.get_node("Buildings").get_children():
				if global_position.distance_to(b.global_position) < 80.0:
					return true
		return false
	for b in buildings:
		if b is Node2D and global_position.distance_to(b.global_position) < 80.0:
			return true
	return false


func _try_attack() -> void:
	if not can_attack:
		return
	can_attack = false
	# Ranged if pistol equipped and in inventory
	if equipped_weapon == "pistol" and InventoryManager.has_item("pistol", 1):
		attack_cooldown.start(0.4)
		_fire_projectile(25.0)
		return
	attack_cooldown.start(0.5)
	# Melee hit
	var space := get_world_2d().direct_space_state
	var dir_vec := _facing_to_vector()
	var reach := 40.0
	var dmg := 15.0
	if InventoryManager.has_item("axe", 1):
		dmg = 20.0
	elif InventoryManager.has_item("knife", 1):
		dmg = 18.0
	var params := PhysicsRayQueryParameters2D.create(global_position, global_position + dir_vec * reach)
	params.exclude = [self]
	params.collision_mask = 0b00001100 # enemies + animals
	var result := space.intersect_ray(params)
	if result and result.has("collider"):
		var target = result["collider"]
		if target.has_method("receive_damage"):
			target.receive_damage(dmg, self)
	if is_running:
		energy = maxf(energy - 5.0, 0.0)
		energy_changed.emit(energy, max_energy)

func _fire_projectile(dmg: float) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position + _facing_to_vector() * 16.0
	if proj.has_method("setup"):
		proj.setup(_facing_to_vector(), dmg, self)
	get_tree().current_scene.add_child(proj)

func equip_weapon(item_id: String) -> void:
	equipped_weapon = item_id


func _try_interact() -> void:
	var dir_vec := _facing_to_vector()
	interact_ray.target_position = dir_vec * 40.0
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var obj = interact_ray.get_collider()
		if obj and obj.has_method("interact"):
			obj.interact(self)
		elif obj and obj.has_method("collect"):
			obj.collect(self)

func _facing_to_vector() -> Vector2:
	match facing_dir:
		"down": return Vector2.DOWN
		"up": return Vector2.UP
		"left_down": return Vector2(-1, 1).normalized()
		"right_down": return Vector2(1, 1).normalized()
		"left_up": return Vector2(-1, -1).normalized()
		"right_up": return Vector2(1, -1).normalized()
	return Vector2.DOWN

func receive_damage(amount: float, _source: Node = null) -> void:
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	modulate = Color(1, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.2)
	if health <= 0.0:
		died.emit()
		# Simple respawn at menu for now
		GameManager.go_to_main_menu()

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)

func eat(hunger_amount: float, thirst_amount: float = 0.0) -> void:
	hunger = minf(hunger + hunger_amount, max_hunger)
	thirst = minf(thirst + thirst_amount, max_thirst)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)

func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func _update_hud_signals() -> void:
	health_changed.emit(health, max_health)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)
	energy_changed.emit(energy, max_energy)

func get_save_data() -> Dictionary:
	return {
		"position": global_position,
		"health": health,
		"max_health": max_health,
		"hunger": hunger,
		"max_hunger": max_hunger,
		"thirst": thirst,
		"max_thirst": max_thirst,
		"energy": energy,
		"max_energy": max_energy,
		"temperature": temperature
	}

func apply_save_data(data: Dictionary) -> void:
	GameManager.player_data = data.duplicate(true)
	_load_stats_from_manager()
	_update_hud_signals()
