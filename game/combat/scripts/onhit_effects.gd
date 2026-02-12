extends Node
class_name OnHitEffects

signal triggered(effect_id: StringName, source: Node, target: Node)

func trigger(effect_id: StringName, source: Node, target: Node) -> void:
    triggered.emit(effect_id, source, target)
