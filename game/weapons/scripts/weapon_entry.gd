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
@export var laser_width := 3.0
@export var laser_duration := 0.08
@export var summon_duration := 3.0
@export var summon_tick_interval := 0.25
@export var summon_radius := 72.0
