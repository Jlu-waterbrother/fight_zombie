extends Node
class_name HealthComponent

signal died

@export var max_health := 2000.0
var current_health := 2000.0

func _ready() -> void:
    current_health = max_health

func apply_damage(amount: float) -> void:
    current_health = maxf(0.0, current_health - amount)
    if current_health <= 0.0:
        died.emit()

func heal(amount: float) -> void:
    current_health = minf(max_health, current_health + amount)
