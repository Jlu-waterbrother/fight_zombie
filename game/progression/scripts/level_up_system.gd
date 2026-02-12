extends Node
class_name LevelUpSystem

signal leveled_up(new_level: int)

var level := 1

func gain_level() -> void:
    level += 1
    leveled_up.emit(level)
