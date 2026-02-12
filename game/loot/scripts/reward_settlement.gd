extends RefCounted
class_name RewardSettlement

func settle_gold(base_gold: int, wave_index: int) -> int:
    return base_gold + wave_index * 2
