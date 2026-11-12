extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var autosave_check: CheckBox = %AutosaveCheck
@onready var back_button: Button = %BackButton

func _ready() -> void:
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	autosave_check.button_pressed = SaveManager.autosave_enabled
	
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	autosave_check.toggled.connect(_on_autosave_toggled)
	back_button.pressed.connect(_on_back_pressed)

func _on_music_changed(v: float) -> void:
	AudioManager.set_music_volume(v)

func _on_sfx_changed(v: float) -> void:
	AudioManager.set_sfx_volume(v)

func _on_autosave_toggled(on: bool) -> void:
	SaveManager.autosave_enabled = on

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
