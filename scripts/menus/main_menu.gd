extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	version_label.text = "v0.1.0 - Godot 4 Sandbox Survival"
	
	if not SaveManager.has_save():
		continue_button.disabled = true
		continue_button.modulate.a = 0.5

func _on_new_game_pressed() -> void:
	GameManager.go_to_character_selection()

func _on_continue_pressed() -> void:
	GameManager.continue_game()

func _on_settings_pressed() -> void:
	GameManager.go_to_settings()

func _on_quit_pressed() -> void:
	GameManager.quit_game()
