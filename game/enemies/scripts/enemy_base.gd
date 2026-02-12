extends CharacterBody2D
class_name EnemyBase

signal attack_tick(damage: float)

@export var move_speed := 110.0
@export var attack_interval := 0.9
@export var attack_damage := 8.0

var attack_line_y := INF
var target: Node2D
var _is_attacking := false
var _attack_cooldown := 0.0

func _physics_process(delta: float) -> void:
    if _is_attacking:
        velocity = Vector2.ZERO
        move_and_slide()
        _tick_attack(delta)
        return

    velocity = Vector2.DOWN * move_speed
    move_and_slide()

    if global_position.y >= attack_line_y:
        _is_attacking = true
        velocity = Vector2.ZERO
        _attack_cooldown = 0.0

func _tick_attack(delta: float) -> void:
    _attack_cooldown -= delta
    if _attack_cooldown > 0.0:
        return
    _attack_cooldown = maxf(0.1, attack_interval)
    attack_tick.emit(attack_damage)
