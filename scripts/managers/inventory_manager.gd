extends Node

signal inventory_changed
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

const MAX_SLOTS := 30

# slot: { "item_id": String, "amount": int } or null
var slots: Array = []

# item definitions loaded/registered at runtime
var item_db: Dictionary = {}

func _ready() -> void:
	_init_slots()
	_register_default_items()

func _init_slots() -> void:
	slots.clear()
	for i in MAX_SLOTS:
		slots.append(null)

func register_item(item_id: String, data: Dictionary) -> void:
	item_db[item_id] = data

func _register_default_items() -> void:
	register_item("wood", {"name": "Madeira", "stack": 99, "type": "resource", "icon": ""})
	register_item("stone", {"name": "Pedra", "stack": 99, "type": "resource", "icon": ""})
	register_item("fiber", {"name": "Fibra", "stack": 99, "type": "resource", "icon": ""})
	register_item("food_raw_meat", {"name": "Carne Crua", "stack": 20, "type": "food", "hunger": 10, "icon": ""})
	register_item("food_cooked_meat", {"name": "Carne Cozida", "stack": 20, "type": "food", "hunger": 25, "icon": ""})
	register_item("food_berry", {"name": "Frutas", "stack": 30, "type": "food", "hunger": 8, "thirst": 5, "icon": ""})
	register_item("water", {"name": "Água", "stack": 10, "type": "drink", "thirst": 30, "icon": ""})
	register_item("axe", {"name": "Machado", "stack": 1, "type": "tool", "damage": 12, "icon": ""})
	register_item("pickaxe", {"name": "Picareta", "stack": 1, "type": "tool", "damage": 10, "icon": ""})
	register_item("knife", {"name": "Faca", "stack": 1, "type": "weapon", "damage": 15, "icon": ""})
	register_item("pistol", {"name": "Pistola", "stack": 1, "type": "weapon", "damage": 25, "icon": ""})
	register_item("bandage", {"name": "Bandagem", "stack": 10, "type": "consumable", "heal": 20, "icon": ""})
	register_item("plank", {"name": "Tábua", "stack": 99, "type": "material", "icon": ""})
	register_item("wall_wood", {"name": "Parede de Madeira", "stack": 50, "type": "building", "icon": ""})
	register_item("door_wood", {"name": "Porta de Madeira", "stack": 20, "type": "building", "icon": ""})
	register_item("floor_wood", {"name": "Piso de Madeira", "stack": 50, "type": "building", "icon": ""})
	register_item("campfire", {"name": "Fogueira", "stack": 10, "type": "building", "icon": ""})
	register_item("chest", {"name": "Baú", "stack": 10, "type": "building", "icon": ""})
	register_item("workbench", {"name": "Bancada", "stack": 5, "type": "building", "icon": ""})

func get_item_data(item_id: String) -> Dictionary:
	return item_db.get(item_id, {"name": item_id, "stack": 1, "type": "misc"})

func add_item(item_id: String, amount: int = 1) -> int:
	if amount <= 0:
		return 0
	if not item_db.has(item_id):
		register_item(item_id, {"name": item_id, "stack": 99, "type": "misc"})
	var remaining := amount
	var stack_size: int = int(get_item_data(item_id).get("stack", 99))
	
	# Fill existing stacks
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot = slots[i]
		if slot != null and slot.item_id == item_id and slot.amount < stack_size:
			var can_add: int = min(remaining, stack_size - slot.amount)
			slot.amount += can_add
			remaining -= can_add
	
	# Fill empty slots
	for i in range(slots.size()):
		if remaining <= 0:
			break
		if slots[i] == null:
			var to_put: int = min(remaining, stack_size)
			slots[i] = {"item_id": item_id, "amount": to_put}
			remaining -= to_put
	
	var added := amount - remaining
	if added > 0:
		item_added.emit(item_id, added)
		inventory_changed.emit()
	return remaining # 0 = all added

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	var remaining := amount
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var slot = slots[i]
		if slot != null and slot.item_id == item_id:
			var take: int = min(remaining, slot.amount)
			slot.amount -= take
			remaining -= take
			if slot.amount <= 0:
				slots[i] = null
	item_removed.emit(item_id, amount)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return count_item(item_id) >= amount

func count_item(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot != null and slot.item_id == item_id:
			total += int(slot.amount)
	return total

func get_save_data() -> Dictionary:
	return {"slots": slots.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	_init_slots()
	var saved_slots = data.get("slots", [])
	for i in range(min(saved_slots.size(), slots.size())):
		slots[i] = saved_slots[i]
	inventory_changed.emit()

func clear() -> void:
	_init_slots()
	inventory_changed.emit()
