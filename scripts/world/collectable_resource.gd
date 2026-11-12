extends Area2D
class_name CollectableResource

@export var item_id: String = "wood"
@export var amount: int = 1
@export var bonus_item_id: String = ""
@export var bonus_amount: int = 0
@export var max_health: float = 30.0
@export var required_tool: String = "" # "axe", "pickaxe", "" for any
@export var display_name: String = "Recurso"

var health: float

func _ready() -> void:
	health = max_health
	collision_layer = 16 # layer 5 (Resources)
	collision_mask = 0
	add_to_group("resource")
	monitoring = false
	monitorable = true

func interact(player: Node) -> void:
	_collect(player)

func collect(player: Node) -> void:
	_collect(player)

func _collect(player: Node) -> void:
	receive_damage(15.0, player)

func receive_damage(amount: float, source: Node = null) -> void:
	health -= amount
	_hit_feedback()
	if health <= 0.0:
		InventoryManager.add_item(item_id, amount)
		if bonus_item_id != "" and bonus_amount > 0:
			InventoryManager.add_item(bonus_item_id, bonus_amount)
		queue_free()

func _hit_feedback() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)

