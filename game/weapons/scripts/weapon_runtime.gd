extends Node2D
class_name WeaponRuntime

@export var fire_interval := 0.25
var _cooldown := 0.0

func _process(delta: float) -> void:
    _cooldown = maxf(0.0, _cooldown - delta)

func can_fire() -> bool:
    return _cooldown <= 0.0

func mark_fired() -> void:
    _cooldown = fire_interval
