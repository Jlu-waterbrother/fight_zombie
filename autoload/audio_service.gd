extends Node

@onready var _bgm_player := AudioStreamPlayer.new()

func _ready() -> void:
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)

func play_bgm(stream: AudioStream) -> void:
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()
