extends Node2D

const ENEMY_SCENE := preload("res://game/enemies/scenes/zombie_basic.tscn")
const BULLET_SCENE := preload("res://game/weapons/scenes/bullet.tscn")
const AOE_FIELD_SCENE := preload("res://game/weapons/scenes/aoe_field.tscn")
const DEFAULT_WEAPON_RESOURCES: Array[WeaponEntry] = [
	preload("res://game/weapons/data/pulse_weapon.tres"),
	preload("res://game/weapons/data/laser_weapon.tres"),
	preload("res://game/weapons/data/summon_blackhole_weapon.tres"),
	preload("res://game/weapons/data/scatter_weapon.tres"),
	preload("res://game/weapons/data/arc_weapon.tres"),
]
const UPGRADE_UNLOCK_WEAPON := 1
const UPGRADE_FIRE_RATE := 2
const UPGRADE_HIT_RADIUS := 3

@export var enemy_spawn_interval := 1.2
@export var enemy_contact_damage := 25.0
@export var enemy_contact_radius := 28.0
@export var total_waves := 3
@export var enemies_per_wave_base := 8
@export var enemies_per_wave_growth := 4
@export var enemy_base_max_health := 60.0
@export var enemy_health_growth_per_wave := 0.15
@export var inter_wave_delay := 1.8
@export var max_equipped_weapons := 3
@export var weapon_entries: Array[WeaponEntry] = []
@export var projectile_despawn_margin := 40.0
@export var base_settlement_gold := 20
@export var kill_gold_bonus := 1
@export var exp_per_kill := 10
@export var exp_to_level_base := 40
@export var exp_to_level_growth := 1.35

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var bullet_container: Node2D = $BulletContainer
@onready var summon_container: Node2D = $SummonContainer
@onready var health_label: Label = $UILayer/HealthLabel
@onready var kill_label: Label = $UILayer/KillLabel
@onready var wave_label: Label = $UILayer/WaveLabel
@onready var level_label: Label = $UILayer/LevelLabel
@onready var exp_label: Label = $UILayer/ExpLabel
@onready var weapon_label: Label = $UILayer/WeaponLabel
@onready var fail_panel: PanelContainer = $UILayer/FailPanel
@onready var restart_button: Button = $UILayer/FailPanel/VBoxContainer/RestartButton
@onready var back_to_menu_button: Button = $UILayer/FailPanel/VBoxContainer/BackToMenuButton
@onready var victory_panel: PanelContainer = $UILayer/VictoryPanel
@onready var victory_desc_label: Label = $UILayer/VictoryPanel/VBoxContainer/VictoryDescLabel
@onready var victory_restart_button: Button = $UILayer/VictoryPanel/VBoxContainer/VictoryRestartButton
@onready var victory_back_to_menu_button: Button = $UILayer/VictoryPanel/VBoxContainer/VictoryBackToMenuButton
@onready var upgrade_panel: PanelContainer = $UILayer/UpgradePanel
@onready var fire_rate_button: Button = $UILayer/UpgradePanel/VBoxContainer/FireRateButton
@onready var hit_radius_button: Button = $UILayer/UpgradePanel/VBoxContainer/HitRadiusButton

var _spawn_cooldown := 0.0
var _inter_wave_cooldown := 0.0
var _is_run_over := false
var _is_failed := false
var _kill_count := 0
var _current_level := 1
var _current_exp := 0
var _next_level_exp := 40
var _pending_level_ups := 0
var _is_upgrade_open := false
var _option_a: Dictionary = {}
var _option_b: Dictionary = {}
var _weapon_pool: Dictionary = {}
var _weapon_order: Array[String] = []
var _equipped_weapon_ids: Array[String] = []
var _current_wave_index := 0
var _current_wave_spawn_remaining := 0
var _is_between_waves := false
var _run_elapsed_seconds := 0.0
var _reward_settlement := RewardSettlement.new()
var _effective_total_waves := 3
var _effective_enemy_spawn_interval := 1.2
var _effective_enemies_per_wave_base := 8
var _effective_enemies_per_wave_growth := 4

func _ready() -> void:
	GameState.load_persistent_state()
	GameState.reset_run_state()
	GameState.start_run()

	var player_controller := player as PlayerController
	player_controller.health_component.died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	victory_restart_button.pressed.connect(_on_restart_pressed)
	victory_back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	fire_rate_button.pressed.connect(_on_pick_option_a_upgrade)
	hit_radius_button.pressed.connect(_on_pick_option_b_upgrade)
	_init_weapon_pool()
	_apply_run_modifiers_from_state()
	if not _weapon_order.is_empty():
		_unlock_weapon(_weapon_order[0])

	fail_panel.visible = false
	victory_panel.visible = false
	upgrade_panel.visible = false
	_next_level_exp = exp_to_level_base
	_start_wave(1)
	_update_health_text()
	_update_kill_text()
	_update_wave_text()
	_update_progression_text()
	_update_weapon_text()

func _process(delta: float) -> void:
	if _is_run_over:
		return

	_run_elapsed_seconds += delta
	if _is_upgrade_open:
		_update_health_text()
		_update_kill_text()
		_update_wave_text()
		_update_progression_text()
		_update_weapon_text()
		return

	_tick_wave_spawn(delta)

	for weapon_id in _equipped_weapon_ids:
		_tick_weapon(delta, weapon_id)

	_update_projectile_state()
	_try_complete_wave_or_run(delta)
	_update_health_text()
	_update_kill_text()
	_update_wave_text()
	_update_progression_text()
	_update_weapon_text()
	_try_open_upgrade_panel()

func _start_wave(wave_index: int) -> void:
	_current_wave_index = wave_index
	GameState.current_wave = wave_index
	_current_wave_spawn_remaining = _enemy_count_for_wave(wave_index)
	_spawn_cooldown = 0.0
	_is_between_waves = false

func _tick_wave_spawn(delta: float) -> void:
	if _is_between_waves:
		return
	if _current_wave_index <= 0 or _current_wave_index > _effective_total_waves:
		return
	if _current_wave_spawn_remaining <= 0:
		return

	_spawn_cooldown -= delta
	if _spawn_cooldown > 0.0:
		return

	_spawn_enemy()
	_current_wave_spawn_remaining -= 1
	_spawn_cooldown = _effective_enemy_spawn_interval

func _try_complete_wave_or_run(delta: float) -> void:
	if _current_wave_spawn_remaining > 0:
		return
	if enemy_container.get_child_count() > 0:
		return

	if _current_wave_index >= _effective_total_waves:
		_finish_victory()
		return

	if not _is_between_waves:
		_is_between_waves = true
		_inter_wave_cooldown = inter_wave_delay

	_inter_wave_cooldown -= delta
	if _inter_wave_cooldown <= 0.0:
		_start_wave(_current_wave_index + 1)

func _enemy_count_for_wave(wave_index: int) -> int:
	return max(1, _effective_enemies_per_wave_base + (wave_index - 1) * _effective_enemies_per_wave_growth)

func _apply_run_modifiers_from_state() -> void:
	var wave_multiplier := maxf(0.5, GameState.wave_count_multiplier)
	var enemy_multiplier := maxf(0.5, GameState.enemy_count_multiplier)
	var spawn_multiplier := maxf(0.5, GameState.spawn_interval_multiplier)

	_effective_total_waves = max(1, int(round(float(total_waves) * wave_multiplier)))
	_effective_enemy_spawn_interval = maxf(0.1, enemy_spawn_interval * spawn_multiplier)
	_effective_enemies_per_wave_base = max(1, int(round(float(enemies_per_wave_base) * enemy_multiplier)))
	_effective_enemies_per_wave_growth = max(1, int(round(float(enemies_per_wave_growth) * enemy_multiplier)))

func _init_weapon_pool() -> void:
	_weapon_pool.clear()
	_weapon_order.clear()
	var entries: Array[WeaponEntry] = weapon_entries
	if entries.is_empty():
		entries = DEFAULT_WEAPON_RESOURCES

	for entry in entries:
		if entry == null:
			continue
		var entry_id := String(entry.weapon_id).strip_edges()
		if entry_id == "":
			continue
		if _weapon_pool.has(entry_id):
			continue
		var weapon := {
			"id": entry_id,
			"name": String(entry.weapon_name),
			"weapon_kind": entry.weapon_kind,
			"cooldown": 0.0,
			"fire_interval": float(entry.fire_interval),
			"fire_interval_min": float(entry.fire_interval_min),
			"projectile_count": max(1, int(entry.projectile_count)),
			"spread_degrees": float(entry.spread_degrees),
			"hit_radius": float(entry.hit_radius),
			"damage": float(entry.damage),
			"laser_width": float(entry.laser_width),
			"laser_duration": float(entry.laser_duration),
			"summon_duration": float(entry.summon_duration),
			"summon_tick_interval": float(entry.summon_tick_interval),
			"summon_radius": float(entry.summon_radius),
		}
		_weapon_pool[weapon.id] = weapon
		_weapon_order.append(weapon.id)

func _unlock_weapon(weapon_id: String) -> void:
	if _equipped_weapon_ids.has(weapon_id):
		return
	if _equipped_weapon_ids.size() >= max_equipped_weapons:
		return
	if not _weapon_pool.has(weapon_id):
		return
	_equipped_weapon_ids.append(weapon_id)

func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate() as EnemyBase
	var wave_health_multiplier := 1.0 + float(max(_current_wave_index - 1, 0)) * enemy_health_growth_per_wave
	var enemy_max_health := enemy_base_max_health * wave_health_multiplier

	enemy.attack_line_y = player.global_position.y
	enemy.attack_damage = enemy_contact_damage
	enemy.attack_tick.connect(_on_enemy_attack_tick)
	enemy.defeated.connect(_on_enemy_defeated)

	var viewport_size := get_viewport_rect().size
	enemy.global_position = Vector2(randf_range(40.0, viewport_size.x - 40.0), -32.0)
	enemy_container.add_child(enemy)
	enemy.configure_for_run(player.global_position.y, enemy_contact_damage, enemy_max_health)

func _tick_weapon(delta: float, weapon_id: String) -> void:
	if not _weapon_pool.has(weapon_id):
		return
	var weapon: Dictionary = _weapon_pool[weapon_id]
	weapon.cooldown = float(weapon.cooldown) - delta
	if float(weapon.cooldown) > 0.0:
		return
	_fire_weapon(weapon)
	weapon.cooldown = float(weapon.fire_interval)

func _fire_weapon(weapon: Dictionary) -> void:
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
	var base_direction := (nearest_enemy.global_position - player.global_position).normalized()
	var projectile_count := int(weapon.projectile_count)
	var spread_degrees := float(weapon.spread_degrees)
	var hit_radius := float(weapon.hit_radius)
	var damage := float(weapon.damage)
	var weapon_kind := StringName(String(weapon.weapon_kind))
	var weapon_id := String(weapon.id)

	if weapon_kind == &"summon":
		_spawn_black_hole(weapon, nearest_enemy, damage)
		return

	if weapon_kind == &"laser":
		_fire_laser_weapon(weapon, nearest_enemy, damage)
		return

	if projectile_count <= 1:
		_spawn_projectile(base_direction, hit_radius, damage, nearest_enemy, weapon_id)
		return

	var center_index := float(projectile_count - 1) * 0.5
	for i in projectile_count:
		var angle_deg := (float(i) - center_index) * spread_degrees
		var direction := base_direction.rotated(deg_to_rad(angle_deg))
		_spawn_projectile(direction, hit_radius, damage, nearest_enemy, weapon_id)

func _spawn_black_hole(weapon: Dictionary, target_enemy: EnemyBase, damage: float) -> void:
	var spawn_position := player.global_position + Vector2(0.0, -120.0)
	if target_enemy != null and is_instance_valid(target_enemy):
		spawn_position = target_enemy.global_position

	var source_weapon_id := StringName(String(weapon.id))
	var info := DamageInfo.from_values(damage, &"summon", source_weapon_id)

	var field := AOE_FIELD_SCENE.instantiate() as AOEFieldRuntime
	field.global_position = spawn_position
	field.configure(float(weapon.summon_radius), float(weapon.summon_tick_interval), float(weapon.summon_duration), info)
	field.pulse_damage.connect(_on_summon_pulse_damage)
	field.expired.connect(_on_summon_expired)
	summon_container.add_child(field)

func _on_summon_pulse_damage(position: Vector2, radius: float, info: DamageInfo) -> void:
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.global_position.distance_to(position) > radius:
			continue
		_apply_damage_to_enemy(enemy, info)

func _on_summon_expired(field: AOEFieldRuntime) -> void:
	if field == null:
		return
	if not is_instance_valid(field):
		return
	field.queue_free()

func _fire_laser_weapon(weapon: Dictionary, target_enemy: EnemyBase, damage: float) -> void:
	if target_enemy == null:
		return
	if not is_instance_valid(target_enemy):
		return

	var source_weapon_id := StringName(String(weapon.id))
	var damage_info := DamageInfo.from_values(damage, &"laser", source_weapon_id)
	_apply_damage_to_enemy(target_enemy, damage_info)

	var laser_width := maxf(1.0, float(weapon.laser_width))
	var laser_duration := maxf(0.03, float(weapon.laser_duration))
	_spawn_laser_line(player.global_position, target_enemy.global_position, laser_width, laser_duration)

func _spawn_laser_line(start_pos: Vector2, end_pos: Vector2, width: float, duration: float) -> void:
	var line := Line2D.new()
	line.z_index = 6
	line.width = width
	line.default_color = Color(1.0, 0.25, 0.25, 0.95)
	line.position = start_pos
	line.add_point(Vector2.ZERO)
	line.add_point(end_pos - start_pos)
	bullet_container.add_child(line)

	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.finished.connect(line.queue_free)

func _spawn_projectile(direction: Vector2, hit_radius: float, damage: float, target_enemy: EnemyBase, weapon_id: String) -> void:
	var bullet := BULLET_SCENE.instantiate() as ProjectileRuntime
	bullet.global_position = player.global_position
	bullet.direction = direction.normalized()
	bullet.target_enemy = target_enemy
	bullet.set_meta("hit_radius", hit_radius)
	bullet.set_meta("damage", damage)
	bullet.set_meta("weapon_id", weapon_id)
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

		var hit_radius := float(bullet.get_meta("hit_radius", 18.0))
		var hit_enemy := _find_hit_enemy(bullet.global_position, hit_radius)
		if hit_enemy != null:
			var damage := float(bullet.get_meta("damage", 1.0))
			var source_weapon_id := StringName(String(bullet.get_meta("weapon_id", "")))
			var damage_info := DamageInfo.from_values(damage, &"projectile", source_weapon_id)
			_apply_damage_to_enemy(hit_enemy, damage_info)
			bullet.queue_free()

func _on_enemy_defeated(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	_kill_count += 1
	_gain_experience(exp_per_kill)
	enemy.queue_free()

func _apply_damage_to_enemy(enemy: EnemyBase, info: DamageInfo) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	enemy.apply_damage_info(info)

func _find_hit_enemy(point: Vector2, hit_radius: float) -> EnemyBase:
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.global_position.distance_to(point) <= hit_radius:
			return enemy
	return null

func _is_out_of_viewport(point: Vector2, viewport_size: Vector2) -> bool:
	return point.x < -projectile_despawn_margin \
		or point.y < -projectile_despawn_margin \
		or point.x > viewport_size.x + projectile_despawn_margin \
		or point.y > viewport_size.y + projectile_despawn_margin

func _on_enemy_attack_tick(damage: float) -> void:
	if _is_run_over:
		return
	if _is_upgrade_open:
		return
	var player_controller := player as PlayerController
	player_controller.apply_contact_damage(damage)

func _on_player_died() -> void:
	if _is_run_over:
		return

	_is_run_over = true
	_is_failed = true
	GameState.record_run_result(_kill_count, _current_level, _current_wave_index, _run_elapsed_seconds)
	GameState.finish_run(false)
	for child in enemy_container.get_children():
		child.queue_free()
	for child in bullet_container.get_children():
		child.queue_free()
	for child in summon_container.get_children():
		child.queue_free()
	fail_panel.visible = true
	victory_panel.visible = false
	_is_upgrade_open = false
	GameState.is_paused = false
	upgrade_panel.visible = false

func _finish_victory() -> void:
	if _is_run_over:
		return

	_is_run_over = true
	GameState.record_run_result(_kill_count, _current_level, _current_wave_index, _run_elapsed_seconds)
	GameState.finish_run(true)
	var reward_gold := _reward_settlement.settle_gold(base_settlement_gold + _kill_count * kill_gold_bonus, _current_wave_index)
	GameState.add_gold(reward_gold)
	for child in bullet_container.get_children():
		child.queue_free()
	for child in summon_container.get_children():
		child.queue_free()
	victory_panel.visible = true
	fail_panel.visible = false
	_is_upgrade_open = false
	GameState.is_paused = false
	upgrade_panel.visible = false
	var best_time_text := "%.1f" % GameState.best_time_seconds
	if GameState.best_time_seconds >= 999998.0:
		best_time_text = "--"
	victory_desc_label.text = "难度: %s\n通关波次: %d\n击杀: %d\n等级: %d\n用时: %.1f 秒\n本局金币: %d\n累计金币: %d\n最佳击杀: %d\n最佳等级: %d\n最佳用时: %s 秒" % [GameState.difficulty_key, _current_wave_index, _kill_count, _current_level, _run_elapsed_seconds, reward_gold, GameState.total_gold, GameState.best_kills, GameState.best_level, best_time_text]

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _update_health_text() -> void:
	var player_controller := player as PlayerController
	var current_health := player_controller.health_component.current_health
	var max_health := player_controller.health_component.max_health
	health_label.text = "HP: %.0f / %.0f" % [current_health, max_health]

func _update_kill_text() -> void:
	kill_label.text = "Kills: %d" % _kill_count

func _update_wave_text() -> void:
	if _is_run_over and not _is_failed:
		wave_label.text = "Wave: %d/%d (胜利)" % [_current_wave_index, _effective_total_waves]
		return
	wave_label.text = "Wave: %d/%d  Remaining: %d" % [_current_wave_index, _effective_total_waves, _current_wave_spawn_remaining + enemy_container.get_child_count()]

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
	GameState.is_paused = true
	upgrade_panel.visible = true
	_refresh_upgrade_options()

func _refresh_upgrade_options() -> void:
	_option_a = _build_unlock_option()
	if _option_a.is_empty():
		_option_a = _build_strengthen_option(UPGRADE_FIRE_RATE)

	_option_b = _build_strengthen_option(UPGRADE_HIT_RADIUS)
	if _option_b.is_empty():
		_option_b = _build_strengthen_option(UPGRADE_FIRE_RATE)

	fire_rate_button.text = String(_option_a.get("label", "强化武器"))
	hit_radius_button.text = String(_option_b.get("label", "强化武器"))

func _build_unlock_option() -> Dictionary:
	if _equipped_weapon_ids.size() >= max_equipped_weapons:
		return {}
	var locked_ids: Array[String] = []
	for weapon_id in _weapon_order:
		if _equipped_weapon_ids.has(weapon_id):
			continue
		locked_ids.append(weapon_id)
	if locked_ids.is_empty():
		return {}
	var weapon_id := locked_ids[0]
	var weapon: Dictionary = _weapon_pool[weapon_id]
	return {
		"type": UPGRADE_UNLOCK_WEAPON,
		"weapon_id": weapon_id,
		"label": "解锁新武器：%s" % String(weapon.name),
	}

func _build_strengthen_option(upgrade_type: int) -> Dictionary:
	if _equipped_weapon_ids.is_empty():
		return {}
	var weapon_id := _select_weapon_for_upgrade(upgrade_type)
	if weapon_id == "":
		return {}
	var weapon: Dictionary = _weapon_pool[weapon_id]
	if upgrade_type == UPGRADE_FIRE_RATE:
		return {
			"type": UPGRADE_FIRE_RATE,
			"weapon_id": weapon_id,
			"label": "强化已有武器：%s 射速" % String(weapon.name),
		}
	return {
		"type": UPGRADE_HIT_RADIUS,
		"weapon_id": weapon_id,
		"label": "强化已有武器：%s 命中范围" % String(weapon.name),
	}

func _select_weapon_for_upgrade(upgrade_type: int) -> String:
	var selected_id := ""
	if upgrade_type == UPGRADE_FIRE_RATE:
		var slowest_interval := -1.0
		for weapon_id in _equipped_weapon_ids:
			var weapon: Dictionary = _weapon_pool[weapon_id]
			var interval := float(weapon.fire_interval)
			if interval > slowest_interval:
				slowest_interval = interval
				selected_id = weapon_id
		return selected_id

	var smallest_radius := INF
	for weapon_id in _equipped_weapon_ids:
		var weapon: Dictionary = _weapon_pool[weapon_id]
		var radius := float(weapon.hit_radius)
		if radius < smallest_radius:
			smallest_radius = radius
			selected_id = weapon_id
	return selected_id

func _close_upgrade_panel() -> void:
	_pending_level_ups = max(0, _pending_level_ups - 1)
	if _pending_level_ups > 0:
		GameState.is_paused = true
		upgrade_panel.visible = true
		return
	_is_upgrade_open = false
	GameState.is_paused = false
	upgrade_panel.visible = false

func _on_pick_option_a_upgrade() -> void:
	_apply_upgrade(_option_a)
	_close_upgrade_panel()

func _on_pick_option_b_upgrade() -> void:
	_apply_upgrade(_option_b)
	_close_upgrade_panel()

func _apply_upgrade(option: Dictionary) -> void:
	if option.is_empty():
		return
	var upgrade_type := int(option.get("type", 0))
	var weapon_id := String(option.get("weapon_id", ""))

	match upgrade_type:
		UPGRADE_UNLOCK_WEAPON:
			_unlock_weapon(weapon_id)
		UPGRADE_FIRE_RATE:
			if _weapon_pool.has(weapon_id):
				var weapon: Dictionary = _weapon_pool[weapon_id]
				var min_interval := float(weapon.fire_interval_min)
				weapon.fire_interval = maxf(min_interval, float(weapon.fire_interval) * 0.88)
		UPGRADE_HIT_RADIUS:
			if _weapon_pool.has(weapon_id):
				var weapon: Dictionary = _weapon_pool[weapon_id]
				weapon.hit_radius = float(weapon.hit_radius) + 3.0

func _update_progression_text() -> void:
	level_label.text = "Level: %d" % _current_level
	exp_label.text = "EXP: %d / %d" % [_current_exp, _next_level_exp]

func _update_weapon_text() -> void:
	if _equipped_weapon_ids.is_empty():
		weapon_label.text = "Weapons (0/%d): 无" % max_equipped_weapons
		return

	var names: Array[String] = []
	for weapon_id in _equipped_weapon_ids:
		var weapon: Dictionary = _weapon_pool[weapon_id]
		names.append(String(weapon.name))

	weapon_label.text = "Weapons (%d/%d): %s" % [_equipped_weapon_ids.size(), max_equipped_weapons, "、".join(names)]
