extends Control

@onready var male_button: Button = %MaleButton
@onready var female_button: Button = %FemaleButton
@onready var preview_sprite: TextureRect = %PreviewSprite
@onready var gender_label: Label = %GenderLabel
@onready var hair_style_option: OptionButton = %HairStyleOption
@onready var hair_color_picker: ColorPickerButton = %HairColorPicker
@onready var skin_color_picker: ColorPickerButton = %SkinColorPicker
@onready var eye_color_picker: ColorPickerButton = %EyeColorPicker
@onready var outfit_option: OptionButton = %OutfitOption
@onready var name_edit: LineEdit = %NameEdit
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton
@onready var randomize_button: Button = %RandomizeButton

var selected_gender: String = "male"
var customization: Dictionary = {}

func _ready() -> void:
	customization = CharacterCustomization.default_customization()
	_setup_options()
	_connect_signals()
	_apply_customization_to_ui()
	_update_preview()

func _setup_options() -> void:
	hair_style_option.clear()
	for i in range(CharacterCustomization.HAIR_STYLES.size()):
		hair_style_option.add_item(CharacterCustomization.HAIR_STYLES[i], i)
	
	outfit_option.clear()
	var outfits := ["Básica", "Aventureiro", "Sobrevivente", "Inverno"]
	for i in range(outfits.size()):
		outfit_option.add_item(outfits[i], i)

func _connect_signals() -> void:
	male_button.pressed.connect(_on_male_pressed)
	female_button.pressed.connect(_on_female_pressed)
	hair_style_option.item_selected.connect(_on_hair_style_selected)
	hair_color_picker.color_changed.connect(_on_hair_color_changed)
	skin_color_picker.color_changed.connect(_on_skin_color_changed)
	eye_color_picker.color_changed.connect(_on_eye_color_changed)
	outfit_option.item_selected.connect(_on_outfit_selected)
	name_edit.text_changed.connect(_on_name_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)

func _apply_customization_to_ui() -> void:
	hair_style_option.select(int(customization.get("hair_style", 0)))
	hair_color_picker.color = customization.get("hair_color", Color(0.35, 0.22, 0.12))
	skin_color_picker.color = customization.get("skin_color", Color(0.93, 0.78, 0.67))
	eye_color_picker.color = customization.get("eye_color", Color(0.2, 0.45, 0.7))
	var outfit_idx := CharacterCustomization.OUTFITS.find(customization.get("outfit", "basic"))
	outfit_option.select(maxi(outfit_idx, 0))
	name_edit.text = str(customization.get("name", "Sobrevivente"))

func _update_preview() -> void:
	gender_label.text = "Masculino" if selected_gender == "male" else "Feminino"
	var tex_path := CharacterCustomization.get_preview_texture_path(selected_gender)
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex:
			# Show first frame of idle_down strip (384x64, 6 frames)
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(0, 0, 64, 64)
			preview_sprite.texture = atlas
			# Apply skin tint as simple customization visualization (modulate blend)
			# Keep readable by mixing with white
			preview_sprite.modulate = skin_color_picker.color.lerp(Color.WHITE, 0.35)
	else:
		preview_sprite.texture = null
		preview_sprite.modulate = Color.WHITE

func _on_male_pressed() -> void:
	selected_gender = "male"
	_update_preview()

func _on_female_pressed() -> void:
	selected_gender = "female"
	_update_preview()

func _on_hair_style_selected(idx: int) -> void:
	customization["hair_style"] = idx

func _on_hair_color_changed(c: Color) -> void:
	customization["hair_color"] = c

func _on_skin_color_changed(c: Color) -> void:
	customization["skin_color"] = c
	_update_preview()

func _on_eye_color_changed(c: Color) -> void:
	customization["eye_color"] = c

func _on_outfit_selected(idx: int) -> void:
	if idx >= 0 and idx < CharacterCustomization.OUTFITS.size():
		customization["outfit"] = CharacterCustomization.OUTFITS[idx]

func _on_name_changed(new_text: String) -> void:
	customization["name"] = new_text.strip_edges() if new_text.strip_edges() != "" else "Sobrevivente"

func _on_randomize_pressed() -> void:
	customization = CharacterCustomization.randomize_customization()
	_apply_customization_to_ui()
	_update_preview()

func _on_confirm_pressed() -> void:
	customization["name"] = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Sobrevivente"
	GameManager.set_character_selection(selected_gender, customization)
	# Save selection immediately for persistence
	SaveManager.save_game()
	GameManager.start_new_game()

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
