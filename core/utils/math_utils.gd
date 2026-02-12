extends RefCounted
class_name MathUtils

static func scale_by_wave(base_value: float, wave_index: int, growth_per_wave: float = 0.08) -> float:
    return base_value * (1.0 + float(max(wave_index - 1, 0)) * growth_per_wave)
