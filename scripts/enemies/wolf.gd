extends EnemyBase

func _ready() -> void:
	super._ready()
	max_health = 45.0
	health = max_health
	move_speed = 75.0
	damage = 12.0
	detection_range = 160.0
	hearing_range = 240.0
	attack_range = 28.0
	attack_cooldown_time = 1.0
	loot_item = "food_raw_meat"
	loot_amount = 2
	loot_extra = "cloth"
	loot_extra_amount = 1
	is_hostile = true
	add_to_group("animal") # also counts as wildlife

func _setup_animations() -> void:
	# Reuse zombie sprites as placeholder if no wolf sprites; use bush/animal visual
	var frames := SpriteFrames.new()
	# Try to use simple colored representation via no texture - use existing zombie as fallback
	if ResourceLoader.exists("res://assets/enemies/zombie/walk_down.png"):
		_add_strip(frames, "idle", "res://assets/enemies/zombie/idle_down.png", 6, 64, 64, 8.0, true)
		_add_strip(frames, "walk", "res://assets/enemies/zombie/walk_down.png", 8, 64, 64, 10.0, true)
		_add_strip(frames, "attack", "res://assets/enemies/zombie/attack_down.png", 7, 64, 64, 12.0, false)
	animated_sprite.sprite_frames = frames
	animated_sprite.modulate = Color(0.6, 0.6, 0.7, 1.0)
	animated_sprite.play("idle")

func _add_strip(frames: SpriteFrames, name: String, path: String, count: int, w: int, h: int, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * w, 0, w, h)
		frames.add_frame(name, atlas)

func _update_anim(dir: Vector2, moving: bool) -> void:
	if animated_sprite.animation == "attack" and animated_sprite.is_playing():
		return
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
		animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	if animated_sprite.animation == "attack":
		animated_sprite.play("idle")
