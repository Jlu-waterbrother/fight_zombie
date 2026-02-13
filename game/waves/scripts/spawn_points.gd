extends Node2D
class_name SpawnPoints

@export var points: PackedVector2Array = []

func get_random_global_point() -> Vector2:
	if points.is_empty():
		return global_position
	return global_position + points[randi() % points.size()]
