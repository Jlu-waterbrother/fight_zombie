extends Node
class_name MetaProgress

var unlocked_nodes: Dictionary = {}

func unlock(node_id: StringName) -> void:
    unlocked_nodes[node_id] = true
