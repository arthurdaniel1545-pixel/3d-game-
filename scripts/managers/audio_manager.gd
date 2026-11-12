extends Node

var music_volume: float = 0.8
var sfx_volume: float = 0.8
var muted: bool = false

var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

func _ready() -> void:
	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if muted or stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db + linear_to_db(sfx_volume)
			p.play()
			return
	# fallback: reuse first
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db + linear_to_db(sfx_volume)
	_sfx_players[0].play()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)

func set_muted(m: bool) -> void:
	muted = m
	class="sr-only">[Note: some earlier tool calls still pending; I’ll continue creating core files in parallel.]
