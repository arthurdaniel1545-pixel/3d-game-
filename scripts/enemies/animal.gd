extends CharacterBody2D
class_name Animal

@export var max_health: float = 30.0
@export var move_speed: float = 60.0
@export var flee_range: float = 120.0
@export var loot_item: String = "food_raw_meat"
@export var loot_amount: int = 2

var health: float
var _flee_target: Node2D = null
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	health = max_health
	add_to_group("animal")
	# Use a bush/plant sprite as simple animal placeholder if no dedicated animal sprite
	if sprite.texture == null and ResourceLoader.exists("res://assets/environment/plants/bush_2.png"):
		sprite.texture = load("res://assets/environment/plants/bush_2.png")

func _physics_process(delta: float) -> void:
	_find_threat()
	if _flee_target and is_instance_valid(_flee_target):
		var dir := (global_position - _flee_target.global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
	else:
		_wander_timer -= delta
		if _wander_timer <= 0:
			_wander_timer = randf_range(1.5, 3.5)
			_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() if randf() > 0.3 else Vector2.ZERO
		velocity = _wander_dir * (move_speed * 0.4)
		move_and_slide()

func _find_threat() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p := players[0] as Node2D
		if global_position.distance_to(p.global_position) <= flee_range:
			_flee_target = p
			return
	_flee_target = null

func receive_damage(amount: float, _source: Node = null) -> void:
	health -= amount
	modulate = Color(1, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	if health <= 0.0:
		InventoryManager.add_item(loot_item, loot_amount)
		queue_free()
