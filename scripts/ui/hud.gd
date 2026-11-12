extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var thirst_bar: ProgressBar = %ThirstBar
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var time_label: Label = %TimeLabel
@onready var day_label: Label = %DayLabel
@onready var weather_label: Label = %WeatherLabel
@onready var inventory_button: Button = %InventoryButton
@onready var build_button: Button = %BuildButton
@onready var pause_button: Button = %PauseButton
@onready var inventory_panel: Control = %InventoryPanel
@onready var build_panel: Control = %BuildPanel
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var craft_list: VBoxContainer = %CraftList
@onready var mobile_controls: Control = %MobileControls

var player: Player
var inventory_open := false
var build_open := false

func _ready() -> void:
	inventory_button.pressed.connect(_on_inventory_pressed)
	build_button.pressed.connect(_on_build_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	InventoryManager.inventory_changed.connect(_refresh_inventory)
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.weather_changed.connect(_on_weather_changed)
	call_deferred("_find_player")
	_setup_crafting()
	_refresh_inventory()
	_update_mobile_visibility()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()
	if Input.is_action_just_pressed("build_mode"):
		_toggle_build()
	if Input.is_action_just_pressed("pause"):
		_on_pause_pressed()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.health_changed.connect(_on_health_changed)
		player.hunger_changed.connect(_on_hunger_changed)
		player.thirst_changed.connect(_on_thirst_changed)
		player.energy_changed.connect(_on_energy_changed)
		_on_health_changed(player.health, player.max_health)
		_on_hunger_changed(player.hunger, player.max_hunger)
		_on_thirst_changed(player.thirst, player.max_thirst)
		_on_energy_changed(player.energy, player.max_energy)

func _on_health_changed(current: float, max_v: float) -> void:
	health_bar.max_value = max_v
	health_bar.value = current

func _on_hunger_changed(current: float, max_v: float) -> void:
	hunger_bar.max_value = max_v
	hunger_bar.value = current

func _on_thirst_changed(current: float, max_v: float) -> void:
	thirst_bar.max_value = max_v
	thirst_bar.value = current

func _on_energy_changed(current: float, max_v: float) -> void:
	energy_bar.max_value = max_v
	energy_bar.value = current

func _on_time_changed(_minutes: float, day: int) -> void:
	time_label.text = TimeManager.get_time_string()
	day_label.text = "Dia %d" % day

func _on_weather_changed(weather: String) -> void:
	var names := {"clear": "Limpo", "cloudy": "Nublado", "rain": "Chuva", "storm": "Tempestade"}
	weather_label.text = names.get(weather, weather)

func _on_inventory_pressed() -> void:
	_toggle_inventory()

func _on_build_pressed() -> void:
	_toggle_build()

func _toggle_inventory() -> void:
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	if inventory_open:
		build_open = false
		build_panel.visible = false
		_refresh_inventory()

func _toggle_build() -> void:
	build_open = not build_open
	build_panel.visible = build_open
	if build_open:
		inventory_open = false
		inventory_panel.visible = false

func _on_pause_pressed() -> void:
	# Simple pause: save and return to menu
	SaveManager.save_game()
	GameManager.go_to_main_menu()

func _refresh_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	for i in range(InventoryManager.slots.size()):
		var slot = InventoryManager.slots[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.text = ""
		btn.tooltip_text = "Vazio"
		if slot != null:
			var item_data := InventoryManager.get_item_data(slot.item_id)
			btn.text = "%s\nx%d" % [item_data.get("name", slot.item_id), slot.amount]
			btn.tooltip_text = "%s (%s)" % [item_data.get("name", slot.item_id), item_data.get("type", "item")]
			btn.pressed.connect(_on_slot_pressed.bind(i))
		inventory_grid.add_child(btn)

func _on_slot_pressed(index: int) -> void:
	var slot = InventoryManager.slots[index]
	if slot == null or player == null:
		return
	var item_data := InventoryManager.get_item_data(slot.item_id)
	var item_type := str(item_data.get("type", ""))
	# Equip weapons/tools
	if item_type == "weapon" or item_type == "tool":
		if player.has_method("equip_weapon"):
			player.equip_weapon(slot.item_id)
		return
	# Use consumables
	if item_type == "food":
		InventoryManager.remove_item(slot.item_id, 1)
		player.eat(float(item_data.get("hunger", 10)), float(item_data.get("thirst", 0)))
	elif item_type == "drink":
		InventoryManager.remove_item(slot.item_id, 1)
		player.eat(0, float(item_data.get("thirst", 20)))
	elif item_type == "consumable" and item_data.has("heal"):
		InventoryManager.remove_item(slot.item_id, 1)
		player.heal(float(item_data.get("heal", 20)))
	_refresh_inventory()


func _setup_crafting() -> void:
	for child in craft_list.get_children():
		child.queue_free()
	var recipes := [
		{"name": "Tábua (2 Madeira)", "needs": {"wood": 2}, "gives": {"plank": 2}},
		{"name": "Machado (3 Madeira, 2 Pedra)", "needs": {"wood": 3, "stone": 2}, "gives": {"axe": 1}},
		{"name": "Picareta (3 Madeira, 3 Pedra)", "needs": {"wood": 3, "stone": 3}, "gives": {"pickaxe": 1}},
		{"name": "Faca (2 Madeira, 1 Pedra)", "needs": {"wood": 2, "stone": 1}, "gives": {"knife": 1}},
		{"name": "Parede de Madeira (4 Tábuas)", "needs": {"plank": 4}, "gives": {"wall_wood": 1}},
		{"name": "Piso de Madeira (3 Tábuas)", "needs": {"plank": 3}, "gives": {"floor_wood": 1}},
		{"name": "Porta de Madeira (4 Tábuas)", "needs": {"plank": 4}, "gives": {"door_wood": 1}},
		{"name": "Fogueira (5 Madeira, 3 Pedra)", "needs": {"wood": 5, "stone": 3}, "gives": {"campfire": 1}},
		{"name": "Baú (8 Tábuas)", "needs": {"plank": 8}, "gives": {"chest": 1}},
		{"name": "Bancada (6 Tábuas, 2 Pedra)", "needs": {"plank": 6, "stone": 2}, "gives": {"workbench": 1}},
		{"name": "Bandagem (2 Fibra)", "needs": {"fiber": 2}, "gives": {"bandage": 1}},
		{"name": "Carne Cozida (1 Crua, 1 Madeira)", "needs": {"food_raw_meat": 1, "wood": 1}, "gives": {"food_cooked_meat": 1}},
	]
	for r in recipes:
		var btn := Button.new()
		btn.text = r["name"]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_craft.bind(r))
		craft_list.add_child(btn)

func _craft(recipe: Dictionary) -> void:
	var needs: Dictionary = recipe["needs"]
	for item_id in needs.keys():
		if not InventoryManager.has_item(item_id, int(needs[item_id])):
			return
	for item_id in needs.keys():
		InventoryManager.remove_item(item_id, int(needs[item_id]))
	var gives: Dictionary = recipe["gives"]
	for item_id in gives.keys():
		InventoryManager.add_item(item_id, int(gives[item_id]))
	_refresh_inventory()

func _update_mobile_visibility() -> void:
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	mobile_controls.visible = is_mobile

# Mobile control handlers (connected from scene buttons)
func _on_move_up_pressed(): Input.action_press("move_up")
func _on_move_up_released(): Input.action_release("move_up")
func _on_move_down_pressed(): Input.action_press("move_down")
func _on_move_down_released(): Input.action_release("move_down")
func _on_move_left_pressed(): Input.action_press("move_left")
func _on_move_left_released(): Input.action_release("move_left")
func _on_move_right_pressed(): Input.action_press("move_right")
func _on_move_right_released(): Input.action_release("move_right")
func _on_attack_pressed(): Input.action_press("attack")
func _on_attack_released(): Input.action_release("attack")
func _on_interact_pressed(): Input.action_press("interact")
func _on_interact_released(): Input.action_release("interact")
func _on_run_toggled(on: bool): 
	if on: Input.action_press("run") 
	else: Input.action_release("run")
