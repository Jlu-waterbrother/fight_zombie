extends Node
class_name SpawnSystem

func spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node2D:
    var instance := scene.instantiate() as Node2D
    parent.add_child(instance)
    instance.global_position = position
    return instance
