extends RefCounted
class_name DifficultyScaler

static func enemy_hp_multiplier(wave_index: int) -> float:
	return 1.0 + float(max(wave_index - 1, 0)) * 0.1
