extends RefCounted
class_name DamageCalc

static func compute(base_damage: float, bonus_percent: float) -> float:
    return base_damage * (1.0 + bonus_percent)
