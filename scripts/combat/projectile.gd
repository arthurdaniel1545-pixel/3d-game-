extends Area2D

@export var speed: float = 320.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 20.0
var owner_node: Node = null
var _lifetime: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, dmg: float, owner_n: Node) -> void:
	direction = dir.normalized()
	damage = dmg
	owner_node = owner_n
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body.has_method("receive_damage"):
		body.receive_damage(damage, owner_node)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == owner_node:
		return
	if area.has_method("receive_damage"):
		area.receive_damage(damage, owner_node)
		queue_free()
