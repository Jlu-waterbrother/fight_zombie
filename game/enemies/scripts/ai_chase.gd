extends RefCounted
class_name AIChase

func compute_velocity(owner_position: Vector2, target_position: Vector2, speed: float) -> Vector2:
    return (target_position - owner_position).normalized() * speed
