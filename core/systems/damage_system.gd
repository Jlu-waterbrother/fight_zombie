extends Node
class_name DamageSystem

func apply_hit(health: HealthComponent, amount: float) -> void:
    if health != null:
        health.apply_damage(amount)
