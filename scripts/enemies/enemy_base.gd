extends CharacterBody2D
class_name EnemyBase

@export var max_health: float = 50.0
@export var move_speed: float = 55.0
@export var damage: float = 10.0
@export var detection_range: float = 180.0
@export var hearing_range: float = 260.0
@export var attack_range: float = 28.0
@export var attack_cooldown_time: float = 1.2
@export var loot_item: String = "food_raw_meat"
@export var loot_amount: int = 1
@export var is_hostile: bool = true
@export var loot_extra: String = ""
@export var loot_extra_amount: int = 0

var health: float
var target: Node2D = null
var can_attack: bool = true
var _attack_timer: float = 0.0
var _alert_level: float = 0.0
var _last_known_pos: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	_setup_animations()

func _physics_process(delta: float) -> void:
	_find_target()
	if _attack_timer > 0:
		_attack_timer -= delta
		if _attack_timer <= 0:
			can_attack = true
	
	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range and is_hostile:
			velocity = Vector2.ZERO
			_try_attack()
		elif dist <= maxf(detection_range, hearing_range) or dist <= detection_range * 1.2:
			var dir := (target.global_position - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
			_update_anim(dir, true)
		else:
			velocity = Vector2.ZERO
			_update_anim(Vector2.DOWN, false)
	elif _alert_level > 0.1 and _last_known_pos != Vector2.ZERO:
		var dir := (_last_known_pos - global_position).normalized()
		velocity = dir * move_speed * 0.7
		move_and_slide()
		_update_anim(dir, true)
		if global_position.distance_to(_last_known_pos) < 16.0:
			_alert_level = 0.0
	else:
		# Wander idle
		velocity = Vector2.ZERO
		_update_anim(Vector2.DOWN, false)


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		target = null
		return
	var p := players[0] as Node2D
	var dist := global_position.distance_to(p.global_position)
	var can_see := dist <= detection_range
	# Hearing: detect running or combat noise at larger range
	var can_hear := false
	if dist <= hearing_range:
		if p.has_method("_is_sheltered") and "is_running" in p:
			if p.is_running:
				can_hear = true
		# If player is very close, always detect
		if dist <= detection_range * 0.6:
			can_hear = true
	# Line of sight not fully simulated, but use distance + alertness
	if can_see or (can_hear and is_hostile):
		target = p
		_last_known_pos = p.global_position
		_alert_level = 1.0
	elif _alert_level > 0 and _last_known_pos != Vector2.ZERO and global_position.distance_to(_last_known_pos) > 20.0:
		# Move to last known position briefly
		target = null
		_alert_level = maxf(_alert_level - 0.01, 0.0)
	else:
		target = null
		_alert_level = maxf(_alert_level - 0.02, 0.0)


func _try_attack() -> void:
	if not can_attack or target == null:
		return
	can_attack = false
	_attack_timer = attack_cooldown_time
	if target.has_method("receive_damage"):
		target.receive_damage(damage, self)
	_play_attack_anim()

func receive_damage(amount: float, _source: Node = null) -> void:
	health -= amount
	modulate = Color(1, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	if health <= 0.0:
		_die()

func _die() -> void:
	if loot_item != "":
		InventoryManager.add_item(loot_item, loot_amount)
	if loot_extra != "" and loot_extra_amount > 0:
		InventoryManager.add_item(loot_extra, loot_extra_amount)
	queue_free()


func _setup_animations() -> void:
	# Override in subclasses or load defaults
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	if not animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.sprite_frames.add_animation("idle")
	if not animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.sprite_frames.add_animation("walk")

func _update_anim(dir: Vector2, moving: bool) -> void:
	if moving:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
		if dir.x != 0:
			animated_sprite.flip_h = dir.x < 0
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func _play_attack_anim() -> void:
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
