extends Node

const DEFAULT_SFX_POOL_SIZE := 12

@onready var _bgm_player := AudioStreamPlayer.new()

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_player_index := 0
var _sfx_cooldowns_ms: Dictionary = {}

func _ready() -> void:
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	_bgm_player.autoplay = false
	add_child(_bgm_player)
	_ensure_sfx_pool(DEFAULT_SFX_POOL_SIZE)

func play_bgm(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _bgm_player.stream != stream:
		_bgm_player.stream = stream
	_bgm_player.volume_db = volume_db
	if _bgm_player.playing:
		return
	_bgm_player.play()

func is_bgm_playing() -> bool:
	return _bgm_player.playing

func set_bgm_volume(volume_db: float) -> void:
	_bgm_player.volume_db = volume_db

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player := _next_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.05, pitch_scale)
	player.play()

func play_sfx_with_cooldown(key: StringName, stream: AudioStream, cooldown_seconds: float, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var cooldown_ms : int = max(0, int(round(cooldown_seconds * 1000.0)))
	if cooldown_ms > 0 and key != StringName():
		var now_ms := Time.get_ticks_msec()
		var next_allowed_ms := int(_sfx_cooldowns_ms.get(key, 0))
		if now_ms < next_allowed_ms:
			return
		_sfx_cooldowns_ms[key] = now_ms + cooldown_ms
	play_sfx(stream, volume_db, pitch_scale)

func clear_sfx_cooldowns() -> void:
	_sfx_cooldowns_ms.clear()

func stop_all_sfx() -> void:
	for player in _sfx_players:
		if player.playing:
			player.stop()

func _ensure_sfx_pool(target_size: int) -> void:
	var size : int = max(1, target_size)
	while _sfx_players.size() < size:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % _sfx_players.size()
		player.bus = "Master"
		player.autoplay = false
		add_child(player)
		_sfx_players.append(player)

func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		_ensure_sfx_pool(DEFAULT_SFX_POOL_SIZE)
	for player in _sfx_players:
		if not player.playing:
			return player
	var player := _sfx_players[_sfx_player_index]
	_sfx_player_index = (_sfx_player_index + 1) % _sfx_players.size()
	return player

func stop_bgm() -> void:
	if not _bgm_player.playing:
		return
	_bgm_player.stop()
