extends Node
class_name DropSystem

func should_drop(drop_chance: float) -> bool:
    return randf() <= drop_chance
