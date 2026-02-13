extends EnemyBase
class_name EnemyWeaver

@export var weave_amplitude := 90.0
@export var weave_frequency := 2.2
@export var horizontal_adjust_speed := 4.0

var _spawn_x := 0.0
var _weave_elapsed := 0.0

func _ready() -> void:
	_spawn_x = global_position.x
	super._ready()

func configure_for_run(next_attack_line_y: float, next_attack_damage: float, next_max_health: float) -> void:
	super.configure_for_run(next_attack_line_y, next_attack_damage, next_max_health)
	_spawn_x = global_position.x
	_weave_elapsed = 0.0

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	if GameState.is_paused:
		velocity = Vector2.ZERO
		return

	if _is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		_tick_attack(delta)
		return

	_weave_elapsed += delta
	var target_x := _spawn_x + sin(_weave_elapsed * weave_frequency) * weave_amplitude
	var horizontal_velocity := (target_x - global_position.x) * horizontal_adjust_speed
	velocity = Vector2(horizontal_velocity, move_speed)
	move_and_slide()

	if global_position.y >= attack_line_y:
		_is_attacking = true
		velocity = Vector2.ZERO
		_attack_cooldown = 0.0
