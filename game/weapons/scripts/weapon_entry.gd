extends Resource
class_name WeaponEntry

@export var weapon_id := "pulse"
@export var weapon_name := "脉冲枪"
@export var weapon_kind: StringName = &"projectile"
@export var fire_interval := 0.22
@export var fire_interval_min := 0.06
@export var projectile_count := 1
@export var spread_degrees := 0.0
@export var hit_radius := 18.0
@export var damage := 20.0
@export var projectile_penetration := 0
@export var infinite_penetration := false
@export var explosion_radius := 0.0
@export var explosion_damage_ratio := 0.0
@export var knockback_distance := 0.0
@export var burn_damage := 0.0
@export var burn_ticks := 0
@export var burn_interval := 0.35
@export var stun_duration := 0.0
@export var slow_factor := 1.0
@export var slow_duration := 0.0
@export var vulnerability_multiplier := 1.0
@export var vulnerability_duration := 0.0
@export var field_duration := 0.0
@export var field_tick_interval := 0.25
@export var field_radius := 0.0
@export var extra_attack_spacing := 26.0
@export var laser_width := 3.0
@export var laser_duration := 0.08
@export var summon_duration := 3.0
@export var summon_tick_interval := 0.25
@export var summon_radius := 72.0
