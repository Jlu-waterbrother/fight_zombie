extends Node2D

const ENEMY_SCENE := preload("res://game/enemies/scenes/zombie_basic.tscn")
const BULLET_SCENE := preload("res://game/weapons/scenes/bullet.tscn")

@export var enemy_spawn_interval := 1.2
@export var enemy_contact_damage := 25.0
@export var enemy_contact_radius := 28.0
@export var auto_attack_interval := 0.22
@export var projectile_hit_radius := 18.0
@export var projectile_despawn_margin := 40.0
@export var exp_per_kill := 10
@export var exp_to_level_base := 40
@export var exp_to_level_growth := 1.35

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var bullet_container: Node2D = $BulletContainer
@onready var health_label: Label = $UILayer/HealthLabel
@onready var kill_label: Label = $UILayer/KillLabel
@onready var level_label: Label = $UILayer/LevelLabel
@onready var exp_label: Label = $UILayer/ExpLabel
@onready var fail_panel: PanelContainer = $UILayer/FailPanel
@onready var restart_button: Button = $UILayer/FailPanel/VBoxContainer/RestartButton
@onready var upgrade_panel: PanelContainer = $UILayer/UpgradePanel
@onready var fire_rate_button: Button = $UILayer/UpgradePanel/VBoxContainer/FireRateButton
@onready var hit_radius_button: Button = $UILayer/UpgradePanel/VBoxContainer/HitRadiusButton

var _spawn_cooldown := 0.0
var _attack_cooldown := 0.0
var _is_failed := false
var _kill_count := 0
var _current_level := 1
var _current_exp := 0
var _next_level_exp := 40
var _pending_level_ups := 0
var _is_upgrade_open := false

func _ready() -> void:
	GameState.reset_run_state()
	GameState.start_run()

	var player_controller := player as PlayerController
	player_controller.health_component.died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart_pressed)
	fire_rate_button.pressed.connect(_on_pick_fire_rate_upgrade)
	hit_radius_button.pressed.connect(_on_pick_hit_radius_upgrade)

	fail_panel.visible = false
	upgrade_panel.visible = false
	_next_level_exp = exp_to_level_base
	_spawn_enemy()
	_update_health_text()
	_update_kill_text()
	_update_progression_text()

func _process(delta: float) -> void:
	if _is_failed:
		return
	if _is_upgrade_open:
		_update_health_text()
		_update_kill_text()
		_update_progression_text()
		return

	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_enemy()
		_spawn_cooldown = enemy_spawn_interval

	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_attack_cooldown = auto_attack_interval
		_fire_projectile_at_nearest_enemy()

	_check_enemy_contact()
	_update_projectile_state()
	_update_health_text()
	_update_kill_text()
	_update_progression_text()
	_try_open_upgrade_panel()

func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate() as EnemyBase
	enemy.target = player

	var viewport_size := get_viewport_rect().size
	enemy.global_position = Vector2(randf_range(40.0, viewport_size.x - 40.0), -32.0)
	enemy_container.add_child(enemy)

func _fire_projectile_at_nearest_enemy() -> void:
	var nearest_enemy: EnemyBase = null
	var nearest_distance := INF
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		var distance := enemy.global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	if nearest_enemy == null:
		return

	if nearest_distance <= 0.0:
		return

	var bullet := BULLET_SCENE.instantiate() as ProjectileRuntime
	bullet.global_position = player.global_position
	bullet.direction = (nearest_enemy.global_position - player.global_position).normalized()
	bullet_container.add_child(bullet)

func _update_projectile_state() -> void:
	var viewport_size := get_viewport_rect().size
	for bullet_child in bullet_container.get_children():
		var bullet := bullet_child as ProjectileRuntime
		if bullet == null:
			continue

		if _is_out_of_viewport(bullet.global_position, viewport_size):
			bullet.queue_free()
			continue

		var hit_enemy := _find_hit_enemy(bullet.global_position)
		if hit_enemy != null:
			hit_enemy.queue_free()
			bullet.queue_free()
			_kill_count += 1
			_gain_experience(exp_per_kill)

func _find_hit_enemy(point: Vector2) -> EnemyBase:
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.global_position.distance_to(point) <= projectile_hit_radius:
			return enemy
	return null

func _is_out_of_viewport(point: Vector2, viewport_size: Vector2) -> bool:
	return point.x < -projectile_despawn_margin \
		or point.y < -projectile_despawn_margin \
		or point.x > viewport_size.x + projectile_despawn_margin \
		or point.y > viewport_size.y + projectile_despawn_margin

func _check_enemy_contact() -> void:
	var player_controller := player as PlayerController
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.global_position.distance_to(player.global_position) <= enemy_contact_radius:
			player_controller.apply_contact_damage(enemy_contact_damage)
			enemy.queue_free()

func _on_player_died() -> void:
	_is_failed = true
	GameState.finish_run(false)
	for child in enemy_container.get_children():
		child.queue_free()
	for child in bullet_container.get_children():
		child.queue_free()
	fail_panel.visible = true
	upgrade_panel.visible = false

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _update_health_text() -> void:
	var player_controller := player as PlayerController
	var current_health := player_controller.health_component.current_health
	var max_health := player_controller.health_component.max_health
	health_label.text = "HP: %.0f / %.0f" % [current_health, max_health]

func _update_kill_text() -> void:
	kill_label.text = "Kills: %d" % _kill_count

func _gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	_current_exp += amount
	while _current_exp >= _next_level_exp:
		_current_exp -= _next_level_exp
		_current_level += 1
		_pending_level_ups += 1
		_next_level_exp = int(round(float(exp_to_level_base) * pow(exp_to_level_growth, _current_level - 1)))

func _try_open_upgrade_panel() -> void:
	if _pending_level_ups <= 0:
		return
	_is_upgrade_open = true
	upgrade_panel.visible = true

func _close_upgrade_panel() -> void:
	_pending_level_ups = max(0, _pending_level_ups - 1)
	if _pending_level_ups > 0:
		upgrade_panel.visible = true
		return
	_is_upgrade_open = false
	upgrade_panel.visible = false

func _on_pick_fire_rate_upgrade() -> void:
	auto_attack_interval = maxf(0.06, auto_attack_interval * 0.88)
	_close_upgrade_panel()

func _on_pick_hit_radius_upgrade() -> void:
	projectile_hit_radius += 3.0
	_close_upgrade_panel()

func _update_progression_text() -> void:
	level_label.text = "Level: %d" % _current_level
	exp_label.text = "EXP: %d / %d" % [_current_exp, _next_level_exp]
