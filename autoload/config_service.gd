extends Node

const DEFAULTS := {
	"starting_hp": 100.0,
	"starting_attack": 10.0,
	"base_move_speed": 280.0,
}
const BASE_WINDOW_SIZE := Vector2i(720, 1280)
const MIN_WINDOW_SIZE := Vector2i(360, 640)
const WINDOW_ASPECT := float(BASE_WINDOW_SIZE.x) / float(BASE_WINDOW_SIZE.y)

var _is_adjusting_window := false
var _last_window_size := Vector2i.ZERO

func _ready() -> void:
	_setup_window_aspect_constraint()

func _setup_window_aspect_constraint() -> void:
	var window := get_window()
	if window == null:
		return
	window.min_size = MIN_WINDOW_SIZE
	_last_window_size = window.size
	if not window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.connect(_on_window_size_changed)
	_enforce_window_aspect(true)

func _on_window_size_changed() -> void:
	if _is_adjusting_window:
		return
	_enforce_window_aspect(false)

func _enforce_window_aspect(prefer_height: bool) -> void:
	var window := get_window()
	if window == null:
		return
	var size := window.size
	if size.x <= 0 or size.y <= 0:
		return

	var target_size := size
	if prefer_height:
		target_size.x = int(round(float(size.y) * WINDOW_ASPECT))
	else:
		var width_delta: int = absi(size.x - _last_window_size.x)
		var height_delta: int = absi(size.y - _last_window_size.y)
		if width_delta >= height_delta:
			target_size.y = int(round(float(size.x) / WINDOW_ASPECT))
		else:
			target_size.x = int(round(float(size.y) * WINDOW_ASPECT))

	if target_size.x < MIN_WINDOW_SIZE.x:
		target_size.x = MIN_WINDOW_SIZE.x
		target_size.y = int(round(float(target_size.x) / WINDOW_ASPECT))
	if target_size.y < MIN_WINDOW_SIZE.y:
		target_size.y = MIN_WINDOW_SIZE.y
		target_size.x = int(round(float(target_size.y) * WINDOW_ASPECT))

	if target_size == size:
		_last_window_size = target_size
		return

	_is_adjusting_window = true
	DisplayServer.window_set_size(target_size, window.get_window_id())
	_is_adjusting_window = false
	_last_window_size = target_size

func get_default(key: String, fallback = null):
	return DEFAULTS.get(key, fallback)
