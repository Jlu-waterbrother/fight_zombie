extends Resource
class_name EnemyEntry

@export var enemy_id := "basic"
@export var enemy_name := "普通僵尸"
@export var enemy_scene: PackedScene
@export var audio_key: StringName = &""

@export_group("Combat")
@export var base_max_health := 60.0
@export var base_move_speed := 110.0
@export var base_attack_damage := 20.0
@export var attack_interval := 0.9

@export_group("Feedback")
@export var hit_flash_duration := 0.08
@export var death_fade_duration := 0.28
