extends RefCounted
class_name UpgradePicker

func pick_candidates(pool: Array, count: int = 3) -> Array:
    var copy := pool.duplicate()
    copy.shuffle()
    return copy.slice(0, min(count, copy.size()))
