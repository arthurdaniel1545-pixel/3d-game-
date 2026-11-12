extends Node

signal inventory_changed
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal equipment_changed

const MAX_SLOTS := 30

# slot: { "item_id": String, "amount": int } or null
var slots: Array = []

# equipment slots
var equipment: Dictionary = {
	"weapon": null,
	"head": null,
	"body": null,
	"legs": null,
	"feet": null,
	"backpack": null
}

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
	register_item("axe", {"name": "Machado", "stack": 1, "type": "tool", "slot": "weapon", "damage": 12, "icon": ""})
	register_item("pickaxe", {"name": "Picareta", "stack": 1, "type": "tool", "slot": "weapon", "damage": 10, "icon": ""})
	register_item("knife", {"name": "Faca", "stack": 1, "type": "weapon", "slot": "weapon", "damage": 15, "icon": ""})
	register_item("pistol", {"name": "Pistola", "stack": 1, "type": "weapon", "slot": "weapon", "damage": 25, "icon": ""})
	register_item("rifle", {"name": "Rifle", "stack": 1, "type": "weapon", "slot": "weapon", "damage": 35, "icon": ""})
	register_item("bandage", {"name": "Bandagem", "stack": 10, "type": "consumable", "heal": 20, "cures_bleed": true, "icon": ""})
	register_item("medkit", {"name": "Kit Médico", "stack": 5, "type": "consumable", "heal": 50, "cures_sickness": true, "icon": ""})
	register_item("plank", {"name": "Tábua", "stack": 99, "type": "material", "icon": ""})
	register_item("wall_wood", {"name": "Parede de Madeira", "stack": 50, "type": "building", "icon": ""})
	register_item("door_wood", {"name": "Porta de Madeira", "stack": 20, "type": "building", "icon": ""})
	register_item("floor_wood", {"name": "Piso de Madeira", "stack": 50, "type": "building", "icon": ""})
	register_item("roof_wood", {"name": "Telhado de Madeira", "stack": 30, "type": "building", "icon": ""})
	register_item("window_wood", {"name": "Janela de Madeira", "stack": 20, "type": "building", "icon": ""})
	register_item("bunker_wall", {"name": "Parede de Bunker", "stack": 30, "type": "building", "icon": ""})
	register_item("campfire", {"name": "Fogueira", "stack": 10, "type": "building", "icon": ""})
	register_item("chest", {"name": "Baú", "stack": 10, "type": "building", "icon": ""})
	register_item("workbench", {"name": "Bancada", "stack": 5, "type": "building", "icon": ""})
	# Equipment
	register_item("cloth_shirt", {"name": "Camisa Básica", "stack": 1, "type": "equipment", "slot": "body", "defense": 2, "warmth": 2, "icon": ""})
	register_item("jacket", {"name": "Jaqueta", "stack": 1, "type": "equipment", "slot": "body", "defense": 4, "warmth": 6, "icon": ""})
	register_item("pants_basic", {"name": "Calça Básica", "stack": 1, "type": "equipment", "slot": "legs", "defense": 1, "warmth": 2, "icon": ""})
	register_item("boots_basic", {"name": "Botas", "stack": 1, "type": "equipment", "slot": "feet", "defense": 2, "speed_bonus": 5, "icon": ""})
	register_item("helmet_basic", {"name": "Capacete", "stack": 1, "type": "equipment", "slot": "head", "defense": 5, "icon": ""})
	register_item("armor_vest", {"name": "Colete", "stack": 1, "type": "equipment", "slot": "body", "defense": 8, "warmth": 1, "icon": ""})
	register_item("backpack_small", {"name": "Mochila Pequena", "stack": 1, "type": "equipment", "slot": "backpack", "capacity_bonus": 5, "icon": ""})
	register_item("backpack_large", {"name": "Mochila Grande", "stack": 1, "type": "equipment", "slot": "backpack", "capacity_bonus": 10, "icon": ""})
	register_item("herbs", {"name": "Ervas Medicinais", "stack": 20, "type": "consumable", "heal": 10, "cures_sickness": true, "icon": ""})
	register_item("canned_food", {"name": "Comida Enlatada", "stack": 15, "type": "food", "hunger": 30, "icon": ""})
	register_item("ammo_pistol", {"name": "Munição Pistola", "stack": 50, "type": "ammo", "icon": ""})
	register_item("scrap_metal", {"name": "Metal", "stack": 50, "type": "resource", "icon": ""})
	register_item("cloth", {"name": "Tecido", "stack": 50, "type": "resource", "icon": ""})
	register_item("sleeping_bag", {"name": "Saco de Dormir", "stack": 1, "type": "tool", "sleep_bonus": 30, "icon": ""})


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

func equip_item(item_id: String) -> bool:
	var data := get_item_data(item_id)
	var slot_name := str(data.get("slot", ""))
	if slot_name == "" or not equipment.has(slot_name):
		return false
	if not has_item(item_id, 1):
		return false
	# Unequip current if any
	if equipment[slot_name] != null:
		add_item(str(equipment[slot_name]), 1)
	remove_item(item_id, 1)
	equipment[slot_name] = item_id
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func unequip_slot(slot_name: String) -> bool:
	if not equipment.has(slot_name) or equipment[slot_name] == null:
		return false
	var item_id := str(equipment[slot_name])
	add_item(item_id, 1)
	equipment[slot_name] = null
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func get_equipment_stats() -> Dictionary:
	var stats := {"defense": 0.0, "warmth": 0.0, "speed_bonus": 0.0, "capacity_bonus": 0}
	for slot_name in equipment.keys():
		var item_id = equipment[slot_name]
		if item_id == null:
			continue
		var data := get_item_data(str(item_id))
		stats["defense"] += float(data.get("defense", 0))
		stats["warmth"] += float(data.get("warmth", 0))
		stats["speed_bonus"] += float(data.get("speed_bonus", 0))
		stats["capacity_bonus"] += int(data.get("capacity_bonus", 0))
	return stats

func get_save_data() -> Dictionary:
	return {"slots": slots.duplicate(true), "equipment": equipment.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	_init_slots()
	var saved_slots = data.get("slots", [])
	for i in range(min(saved_slots.size(), slots.size())):
		slots[i] = saved_slots[i]
	var eq = data.get("equipment", {})
	for k in equipment.keys():
		equipment[k] = eq.get(k, null)
	inventory_changed.emit()
	equipment_changed.emit()

func clear() -> void:
	_init_slots()
	for k in equipment.keys():
		equipment[k] = null
	inventory_changed.emit()
	equipment_changed.emit()

