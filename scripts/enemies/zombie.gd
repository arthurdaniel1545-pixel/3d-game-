extends EnemyBase

func _ready() -> void:
	super._ready()
	max_health = 60.0
	health = max_health
	move_speed = 45.0
	damage = 8.0
	detection_range = 200.0
	attack_range = 30.0
	loot_item = "food_raw_meat"
	loot_amount = 1
	is_hostile = true

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	_add_strip(frames, "idle", "res://assets/enemies/zombie/idle_down.png", 6, 64, 64, 6.0, true)
	_add_strip(frames, "walk", "res://assets/enemies/zombie/walk_down.png", 8, 64, 64, 8.0, true)
	_add_strip(frames, "attack", "res://assets/enemies/zombie/attack_down.png", 7, 64, 64, 10.0, false)
	animated_sprite.sprite_frames = frames
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
		# Choose direction-based walk if available
		var anim := "walk"
		if abs(dir.y) > abs(dir.x):
			if dir.y < 0 and ResourceLoader.exists("res://assets/enemies/zombie/walk_up.png"):
				# use walk_up if loaded; simplified: keep walk
				pass
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)
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
