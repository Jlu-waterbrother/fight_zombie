extends Node2D

var aim_direction := Vector2.RIGHT

func update_aim(target_position: Vector2) -> void:
    aim_direction = (target_position - global_position).normalized()
