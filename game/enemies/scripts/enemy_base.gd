extends CharacterBody2D
class_name EnemyBase

@export var move_speed := 110.0
var target: Node2D

func _physics_process(_delta: float) -> void:
    if target == null:
        velocity = Vector2.ZERO
    else:
        velocity = (target.global_position - global_position).normalized() * move_speed
    move_and_slide()
