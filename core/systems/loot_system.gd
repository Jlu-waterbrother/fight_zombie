extends Node
class_name LootSystem

func roll_drop(chance: float) -> bool:
    return randf() <= chance
