extends CharacterBody2D
class_name Player

signal health_changed(current: float, max_value: float)
signal hunger_changed(current: float, max_value: float)
signal thirst_changed(current: float, max_value: float)
signal energy_changed(current: float, max_value: float)
signal sleep_changed(current: float, max_value: float)
signal wounds_changed(current: float, max_value: float)
signal sickness_changed(current: float, max_value: float)
signal died
signal inventory_toggled
signal status_message(text: String)


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
var sleep: float = 100.0
var max_sleep: float = 100.0
var temperature: float = 37.0
var wounds: float = 0.0 # 0 = none, higher = worse
var max_wounds: float = 100.0
var sickness: float = 0.0 # 0 = healthy
var max_sickness: float = 100.0
var is_sleeping: bool = false


var facing_dir: String = "down"
var is_running: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var equipped_weapon: String = "knife" # knife, pistol, etc.

var _hunger_timer: float = 0.0
var _thirst_timer: float = 0.0
var _energy_regen_timer: float = 0.0
var _temp_timer: float = 0.0
var _sleep_timer: float = 0.0
var _status_timer: float = 0.0


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
	sleep = float(p.get("sleep", 100.0))
	max_sleep = float(p.get("max_sleep", 100.0))
	wounds = float(p.get("wounds", 0.0))
	sickness = float(p.get("sickness", 0.0))
	if p.get("equipped_weapon", "") != "":
		equipped_weapon = str(p.get("equipped_weapon"))
	if GameManager.player_data.has("position") and GameManager.player_data["position"] is Vector2:
		var pos: Vector2 = GameManager.player_data["position"]
		if pos != Vector2.ZERO or not GameManager.is_new_game:
			global_position = pos


func _physics_process(delta: float) -> void:
	if is_sleeping:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		_update_survival(delta, Vector2.ZERO)
		return
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var equip_stats := InventoryManager.get_equipment_stats() if is_instance_valid(InventoryManager) else {"speed_bonus": 0.0}
	var speed_bonus: float = float(equip_stats.get("speed_bonus", 0.0))
	is_running = Input.is_action_pressed("run") and energy > 5.0 and sleep > 5.0 and input_dir != Vector2.ZERO
	var speed := (run_speed if is_running else walk_speed) + speed_bonus
	if wounds > 50.0 or sickness > 40.0:
		speed *= 0.85
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
	_sleep_timer += delta
	_status_timer += delta
	
	if _hunger_timer >= 30.0:
		_hunger_timer = 0.0
		var rate := 1.5
		if sickness > 30.0: rate += 0.5
		hunger = maxf(hunger - rate, 0.0)
		hunger_changed.emit(hunger, max_hunger)
	if _thirst_timer >= 20.0:
		_thirst_timer = 0.0
		var rate := 2.0
		if sickness > 30.0 or TimeManager.weather == "storm": rate += 0.5
		thirst = maxf(thirst - rate, 0.0)
		thirst_changed.emit(thirst, max_thirst)
	
	# Sleep fatigue
	if _sleep_timer >= 25.0:
		_sleep_timer = 0.0
		if is_sleeping:
			sleep = minf(sleep + 15.0, max_sleep)
			energy = minf(energy + 10.0, max_energy)
			wounds = maxf(wounds - 2.0, 0.0)
			sickness = maxf(sickness - 1.0, 0.0)
		else:
			var sleep_drain := 1.2
			if is_running: sleep_drain += 0.8
			sleep = maxf(sleep - sleep_drain, 0.0)
		sleep_changed.emit(sleep, max_sleep)
		wounds_changed.emit(wounds, max_wounds)
		sickness_changed.emit(sickness, max_sickness)
	
	# Energy
	if dir != Vector2.ZERO and is_running:
		energy = maxf(energy - delta * 8.0, 0.0)
		energy_changed.emit(energy, max_energy)
	elif dir == Vector2.ZERO or is_sleeping:
		energy = minf(energy + delta * 6.0, max_energy)
		energy_changed.emit(energy, max_energy)
	elif dir != Vector2.ZERO:
		energy = minf(energy + delta * 1.5, max_energy)
		energy_changed.emit(energy, max_energy)
	
	# Temperature/shelter and sickness risk
	if _temp_timer >= 10.0:
		_temp_timer = 0.0
		var temp := TimeManager.temperature_c
		var sheltered := _is_sheltered()
		var equip_stats := InventoryManager.get_equipment_stats() if is_instance_valid(InventoryManager) else {"warmth": 0.0}
		var warmth: float = float(equip_stats.get("warmth", 0.0))
		var effective_temp := temp + warmth * 0.5
		if (effective_temp < 8.0 or (TimeManager.is_night() and effective_temp < 12.0)) and not sheltered and not is_sleeping:
			health = maxf(health - 1.5, 0.0)
			if randf() < 0.15:
				sickness = minf(sickness + 5.0, max_sickness)
			health_changed.emit(health, max_health)
			sickness_changed.emit(sickness, max_sickness)
		# Wounds bleed slowly
		if wounds > 20.0:
			health = maxf(health - 0.5, 0.0)
			health_changed.emit(health, max_health)
		# Sickness drains
		if sickness > 50.0:
			health = maxf(health - 0.5, 0.0)
			energy = maxf(energy - 1.0, 0.0)
			health_changed.emit(health, max_health)
			energy_changed.emit(energy, max_energy)
	
	# Starvation/dehydration/exhaustion damage
	if hunger <= 0.0 or thirst <= 0.0:
		receive_damage(delta * 2.0)
	if sleep <= 0.0 and _status_timer >= 5.0:
		_status_timer = 0.0
		receive_damage(1.0)
		status_message.emit("Você está exausto! Precisa dormir.")

func start_sleep() -> void:
	if is_sleeping:
		return
	is_sleeping = true
	status_message.emit("Dormindo... (pressione E para acordar)")

func stop_sleep() -> void:
	if not is_sleeping:
		return
	is_sleeping = false
	status_message.emit("Você acordou.")

func toggle_sleep() -> void:
	if is_sleeping:
		stop_sleep()
	else:
		start_sleep()


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
	if is_sleeping:
		stop_sleep()
		return
	var dir_vec := _facing_to_vector()
	interact_ray.target_position = dir_vec * 40.0
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var obj = interact_ray.get_collider()
		if obj and obj.has_method("interact"):
			obj.interact(self)
			return
		elif obj and obj.has_method("collect"):
			obj.collect(self)
			return
	# If sheltered and tired, allow resting/sleeping by interacting in place
	if _is_sheltered() and sleep < 80.0:
		toggle_sleep()
	elif _is_sheltered():
		status_message.emit("Você descansa no abrigo.")
		energy = minf(energy + 5.0, max_energy)
		energy_changed.emit(energy, max_energy)


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
	var equip_stats := InventoryManager.get_equipment_stats() if is_instance_valid(InventoryManager) else {"defense": 0.0}
	var defense: float = float(equip_stats.get("defense", 0.0))
	var final_amount := maxf(amount - defense * 0.3, amount * 0.2)
	health = maxf(health - final_amount, 0.0)
	if final_amount > 8.0 and randf() < 0.25:
		wounds = minf(wounds + final_amount * 0.5, max_wounds)
		wounds_changed.emit(wounds, max_wounds)
	health_changed.emit(health, max_health)
	modulate = Color(1, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.2)
	if health <= 0.0:
		died.emit()
		# Save death state and return to menu
		SaveManager.save_game()
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
	sleep_changed.emit(sleep, max_sleep)
	wounds_changed.emit(wounds, max_wounds)
	sickness_changed.emit(sickness, max_sickness)

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
		"sleep": sleep,
		"max_sleep": max_sleep,
		"wounds": wounds,
		"sickness": sickness,
		"temperature": temperature,
		"equipped_weapon": equipped_weapon
	}

func apply_save_data(data: Dictionary) -> void:
	GameManager.player_data = data.duplicate(true)
	_load_stats_from_manager()
	_update_hud_signals()

