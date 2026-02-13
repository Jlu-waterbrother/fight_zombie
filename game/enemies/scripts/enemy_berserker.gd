extends EnemyBase
class_name EnemyBerserker

@export var frenzy_health_ratio := 0.45
@export var frenzy_speed_multiplier := 1.7
@export var frenzy_attack_interval_multiplier := 0.7

var _base_move_speed := 0.0
var _base_attack_interval := 0.0
var _base_modulate := Color.WHITE
var _is_frenzy := false

func _ready() -> void:
	_base_move_speed = move_speed
	_base_attack_interval = attack_interval
	_base_modulate = modulate
	super._ready()

func configure_for_run(next_attack_line_y: float, next_attack_damage: float, next_max_health: float) -> void:
	super.configure_for_run(next_attack_line_y, next_attack_damage, next_max_health)
	_reset_frenzy_state()

func _process(_delta: float) -> void:
	if health_component == null:
		return
	if _is_dead:
		return

	var health_ratio := 1.0
	if health_component.max_health > 0.0:
		health_ratio = health_component.current_health / health_component.max_health
	var should_frenzy := health_ratio <= frenzy_health_ratio
	if should_frenzy == _is_frenzy:
		return

	_is_frenzy = should_frenzy
	if _is_frenzy:
		move_speed = _base_move_speed * frenzy_speed_multiplier
		attack_interval = maxf(0.12, _base_attack_interval * frenzy_attack_interval_multiplier)
		modulate = Color(1.0, 0.55, 0.55, 1.0)
		return

	move_speed = _base_move_speed
	attack_interval = _base_attack_interval
	modulate = _base_modulate

func _reset_frenzy_state() -> void:
	_is_frenzy = false
	move_speed = _base_move_speed
	attack_interval = _base_attack_interval
	modulate = _base_modulate
