extends Area2D
class_name ProjectileRuntime

@export var speed := 900.0
var direction := Vector2.RIGHT
var target_enemy: Node2D

func _physics_process(delta: float) -> void:
    if GameState.is_paused:
        return

    if target_enemy != null and is_instance_valid(target_enemy):
        direction = (target_enemy.global_position - global_position).normalized()

    global_position += direction * speed * delta
