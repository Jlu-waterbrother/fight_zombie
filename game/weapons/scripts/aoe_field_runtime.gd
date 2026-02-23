extends Node2D
class_name AOEFieldRuntime

signal pulse_damage(position: Vector2, radius: float, damage_info: DamageInfo)
signal pulse(position: Vector2, radius: float)
signal expired(field: AOEFieldRuntime)

@export var radius := 72.0
@export var tick_interval := 0.25
@export var duration := 3.0

@onready var visual: Polygon2D = $Visual

var _tick_cooldown := 0.0
var _duration_left := 0.0
var _damage_info: DamageInfo

func _ready() -> void:
	_duration_left = duration
	_tick_cooldown = 0.0
	_update_visual()

func configure(next_radius: float, next_tick_interval: float, next_duration: float, next_damage_info: DamageInfo) -> void:
	radius = maxf(8.0, next_radius)
	tick_interval = maxf(0.05, next_tick_interval)
	duration = maxf(0.1, next_duration)
	_duration_left = duration
	_tick_cooldown = 0.0
	_damage_info = next_damage_info
	if is_node_ready():
		_update_visual()

func _process(delta: float) -> void:
	if GameState.is_paused:
		return

	_duration_left -= delta
	_tick_cooldown -= delta

	if _tick_cooldown <= 0.0:
		_tick_cooldown = tick_interval
		pulse.emit(global_position, radius)
		if _damage_info != null:
			pulse_damage.emit(global_position, radius, _damage_info)

	if _duration_left <= 0.0:
		expired.emit(self)
		queue_free()

func _update_visual() -> void:
	visual.scale = Vector2.ONE * (radius / 36.0)
