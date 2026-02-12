extends RefCounted
class_name DamageInfo

var amount := 0.0
var source_kind: StringName = &"projectile"
var source_weapon_id: StringName = &""

static func from_values(next_amount: float, next_source_kind: StringName = &"projectile", next_source_weapon_id: StringName = &"") -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = maxf(0.0, next_amount)
	info.source_kind = next_source_kind
	info.source_weapon_id = next_source_weapon_id
	return info
