extends Area2D
class_name ProjectileRuntime

@export var speed := 900.0
var direction := Vector2.RIGHT

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
