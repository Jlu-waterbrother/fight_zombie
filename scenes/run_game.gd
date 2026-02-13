extends Node2D

const ENEMY_SCENE := preload("res://game/enemies/scenes/zombie_basic.tscn")
const BULLET_SCENE := preload("res://game/weapons/scenes/bullet.tscn")
const AOE_FIELD_SCENE := preload("res://game/weapons/scenes/aoe_field.tscn")
const DEFAULT_WAVE_TABLE := preload("res://game/waves/data/wave_table_default.tres")
const DEFAULT_WEAPON_RESOURCES: Array[WeaponEntry] = [
	preload("res://game/weapons/data/pulse_weapon.tres"),
	preload("res://game/weapons/data/laser_weapon.tres"),
	preload("res://game/weapons/data/summon_blackhole_weapon.tres"),
	preload("res://game/weapons/data/scatter_weapon.tres"),
	preload("res://game/weapons/data/arc_weapon.tres"),
]
const UPGRADE_OPTION_COUNT := 3
const PREFERRED_WEAPON_COUNT := 3
const OPTION_UNLOCK_WEAPON: StringName = &"unlock_weapon"
const OPTION_WEAPON_UPGRADE: StringName = &"weapon_upgrade"
const UPGRADE_DAMAGE: StringName = &"damage"
const UPGRADE_FIRE_RATE: StringName = &"fire_rate"
const UPGRADE_PROJECTILE_COUNT: StringName = &"projectile_count"
const UPGRADE_HIT_RADIUS: StringName = &"hit_radius"
const UPGRADE_PIERCE: StringName = &"pierce"
const UPGRADE_SPLIT: StringName = &"split"
const UPGRADE_EXPLOSION: StringName = &"explosion"
const UPGRADE_PULSE_OVERLOAD: StringName = &"pulse_overload"
const UPGRADE_SCATTER_BARRAGE: StringName = &"scatter_barrage"
const UPGRADE_ARC_FOCUS: StringName = &"arc_focus"
const UPGRADE_LASER_WIDTH: StringName = &"laser_width"
const UPGRADE_LASER_DURATION: StringName = &"laser_duration"
const UPGRADE_LASER_CHAIN: StringName = &"laser_chain"
const UPGRADE_LASER_CHAIN_RANGE: StringName = &"laser_chain_range"
const UPGRADE_LASER_BURN: StringName = &"laser_burn"
const UPGRADE_SUMMON_RADIUS: StringName = &"summon_radius"
const UPGRADE_SUMMON_DURATION: StringName = &"summon_duration"
const UPGRADE_SUMMON_TICK_RATE: StringName = &"summon_tick_rate"
const UPGRADE_SUMMON_EXTRA_FIELD: StringName = &"summon_extra_field"
const UPGRADE_SUMMON_IMPLOSION: StringName = &"summon_implosion"

@export var enemy_spawn_interval := 1.2
@export var enemy_contact_damage := 20.0
@export var enemy_contact_radius := 28.0
@export var total_waves := 3
@export var enemies_per_wave_base := 8
@export var enemies_per_wave_growth := 4
@export var enemy_base_max_health := 60.0
@export var enemy_health_growth_per_wave := 0.12
@export var inter_wave_delay := 1.8
@export var wave_table: WaveTable = DEFAULT_WAVE_TABLE
@export var max_equipped_weapons := 3
@export var weapon_entries: Array[WeaponEntry] = []
@export var projectile_despawn_margin := 40.0
@export var base_settlement_gold := 20
@export var kill_gold_bonus := 1
@export var exp_per_kill := 12
@export var exp_to_level_base := 40
@export var exp_to_level_growth := 1.32

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var bullet_container: Node2D = $BulletContainer
@onready var summon_container: Node2D = $SummonContainer
@onready var health_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/HealthLabel
@onready var kill_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/KillLabel
@onready var wave_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/WaveLabel
@onready var level_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/LevelLabel
@onready var exp_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/ExpLabel
@onready var weapon_label: Label = $UILayer/StatusPanel/MarginContainer/StatusVBox/WeaponLabel
@onready var upgrade_history_button: Button = $UILayer/UpgradeHistoryButton
@onready var upgrade_history_panel: PanelContainer = $UILayer/UpgradeHistoryPanel
@onready var upgrade_history_tab_row: HBoxContainer = $UILayer/UpgradeHistoryPanel/VBoxContainer/WeaponTabRow
@onready var upgrade_history_record_list: ItemList = $UILayer/UpgradeHistoryPanel/VBoxContainer/RecordList
@onready var fail_panel: PanelContainer = $UILayer/FailPanel
@onready var restart_button: Button = $UILayer/FailPanel/VBoxContainer/RestartButton
@onready var back_to_menu_button: Button = $UILayer/FailPanel/VBoxContainer/BackToMenuButton
@onready var victory_panel: PanelContainer = $UILayer/VictoryPanel
@onready var victory_desc_label: Label = $UILayer/VictoryPanel/VBoxContainer/VictoryDescLabel
@onready var victory_restart_button: Button = $UILayer/VictoryPanel/VBoxContainer/VictoryRestartButton
@onready var victory_back_to_menu_button: Button = $UILayer/VictoryPanel/VBoxContainer/VictoryBackToMenuButton
@onready var upgrade_panel: PanelContainer = $UILayer/UpgradePanel
@onready var upgrade_button_container: HBoxContainer = $UILayer/UpgradePanel/VBoxContainer/OptionRow

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
var _upgrade_options: Array[Dictionary] = []
var _upgrade_buttons: Array[Button] = []
var _upgrade_card_views: Array[Dictionary] = []
var _initial_weapon_id := ""
var _selected_history_weapon_id := ""
var _weapon_upgrade_levels: Dictionary = {}
var _weapon_upgrade_order: Dictionary = {}
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
var _effective_enemy_count_scale := 1.0
var _effective_spawn_interval_scale := 1.0
var _active_wave_batches: Array[Dictionary] = []

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
	upgrade_history_button.pressed.connect(_on_toggle_upgrade_history_pressed)
	_setup_upgrade_buttons()
	_init_weapon_pool()
	_apply_run_modifiers_from_state()
	if not _weapon_order.is_empty():
		_unlock_weapon(_weapon_order[0])

	fail_panel.visible = false
	victory_panel.visible = false
	upgrade_panel.visible = false
	upgrade_history_panel.visible = false
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

func _setup_upgrade_buttons() -> void:
	_upgrade_buttons.clear()
	_upgrade_card_views.clear()
	for child in upgrade_button_container.get_children():
		child.queue_free()

	for index in UPGRADE_OPTION_COUNT:
		var option_button := Button.new()
		option_button.flat = false
		option_button.text = ""
		option_button.focus_mode = Control.FOCUS_NONE
		option_button.custom_minimum_size = Vector2(190.0, 228.0)
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(_on_pick_upgrade.bind(index))
		upgrade_button_container.add_child(option_button)
		_upgrade_buttons.append(option_button)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.offset_left = 10.0
		margin.offset_top = 10.0
		margin.offset_right = -10.0
		margin.offset_bottom = -10.0
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option_button.add_child(margin)

		var card_vbox := VBoxContainer.new()
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(card_vbox)

		var title_label := Label.new()
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(title_label)

		var icon_label := Label.new()
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_label.add_theme_font_size_override("font_size", 30)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(icon_label)

		var effect_label := Label.new()
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(effect_label)

		_upgrade_card_views.append({
			"title": title_label,
			"icon": icon_label,
			"effect": effect_label,
		})

func _start_wave(wave_index: int) -> void:
	_current_wave_index = wave_index
	GameState.current_wave = wave_index
	_setup_wave_spawn_plan(wave_index)
	_is_between_waves = false
	_spawn_cooldown = 0.0

func _tick_wave_spawn(delta: float) -> void:
	if _is_between_waves:
		return
	if _current_wave_index <= 0 or _current_wave_index > _effective_total_waves:
		return
	if _current_wave_spawn_remaining <= 0:
		return

	for i in _active_wave_batches.size():
		var runtime_batch: Dictionary = _active_wave_batches[i]
		var remaining := int(runtime_batch.get("remaining", 0))
		if remaining <= 0:
			continue

		var delay_left := float(runtime_batch.get("delay_left", 0.0))
		if delay_left > 0.0:
			delay_left -= delta
			runtime_batch["delay_left"] = delay_left
			_active_wave_batches[i] = runtime_batch
			if delay_left > 0.0:
				continue

		var cooldown := float(runtime_batch.get("cooldown", 0.0))
		cooldown -= delta
		if cooldown > 0.0:
			runtime_batch["cooldown"] = cooldown
			_active_wave_batches[i] = runtime_batch
			continue

		var burst_size : int = max(1, int(runtime_batch.get("burst_size", 1)))
		var spawn_count : int = min(burst_size, remaining)
		for _idx in spawn_count:
			var batch := runtime_batch.get("batch", null) as WaveSpawnBatch
			_spawn_enemy_from_batch(batch)
			remaining -= 1
			_current_wave_spawn_remaining = max(0, _current_wave_spawn_remaining - 1)

		runtime_batch["remaining"] = remaining
		var spawn_interval := maxf(0.05, float(runtime_batch.get("spawn_interval", _effective_enemy_spawn_interval)))
		runtime_batch["cooldown"] = spawn_interval
		_active_wave_batches[i] = runtime_batch

func _try_complete_wave_or_run(delta: float) -> void:
	if _current_wave_spawn_remaining > 0:
		return
	if _alive_enemy_count() > 0:
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
	var configured_wave_count := _configured_wave_count()

	_effective_total_waves = max(1, int(round(float(configured_wave_count) * wave_multiplier)))
	_effective_enemy_spawn_interval = maxf(0.1, enemy_spawn_interval * spawn_multiplier)
	_effective_enemies_per_wave_base = max(1, int(round(float(enemies_per_wave_base) * enemy_multiplier)))
	_effective_enemies_per_wave_growth = max(1, int(round(float(enemies_per_wave_growth) * enemy_multiplier)))
	_effective_enemy_count_scale = enemy_multiplier
	_effective_spawn_interval_scale = spawn_multiplier

func _configured_wave_count() -> int:
	if wave_table != null and not wave_table.waves.is_empty():
		return wave_table.waves.size()
	return total_waves

func _wave_definition_for_index(wave_index: int) -> WaveDefinition:
	if wave_table == null:
		return null
	if wave_table.waves.is_empty():
		return null
	var clamped_index := clampi(wave_index - 1, 0, wave_table.waves.size() - 1)
	return wave_table.waves[clamped_index]

func _setup_wave_spawn_plan(wave_index: int) -> void:
	_active_wave_batches.clear()
	_current_wave_spawn_remaining = 0
	var definition := _wave_definition_for_index(wave_index)
	if definition == null or definition.batches.is_empty():
		_current_wave_spawn_remaining = _enemy_count_for_wave(wave_index)
		_active_wave_batches.append({
			"batch": null,
			"remaining": _current_wave_spawn_remaining,
			"delay_left": 0.0,
			"cooldown": 0.0,
			"spawn_interval": _effective_enemy_spawn_interval,
			"burst_size": 1,
		})
		return

	for batch in definition.batches:
		if batch == null:
			continue
		var configured_count : int = max(1, int(round(float(max(1, batch.count)) * _effective_enemy_count_scale)))
		var configured_interval := maxf(0.05, batch.spawn_interval * _effective_spawn_interval_scale)
		var configured_delay := maxf(0.0, batch.start_delay * _effective_spawn_interval_scale)
		_active_wave_batches.append({
			"batch": batch,
			"remaining": configured_count,
			"delay_left": configured_delay,
			"cooldown": 0.0,
			"spawn_interval": configured_interval,
			"burst_size": max(1, batch.burst_size),
		})
		_current_wave_spawn_remaining += configured_count

func _spawn_enemy_from_batch(batch: WaveSpawnBatch) -> void:
	var enemy_scene := ENEMY_SCENE
	var health_multiplier := 1.0
	var attack_multiplier := 1.0
	if batch != null:
		if batch.enemy_scene != null:
			enemy_scene = batch.enemy_scene
		health_multiplier = maxf(0.1, batch.hp_multiplier)
		attack_multiplier = maxf(0.1, batch.attack_multiplier)

	var enemy := enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		return

	var wave_health_multiplier := 1.0 + float(max(_current_wave_index - 1, 0)) * enemy_health_growth_per_wave
	var enemy_max_health := enemy_base_max_health * wave_health_multiplier * health_multiplier
	var enemy_attack_damage := enemy_contact_damage * attack_multiplier

	enemy.attack_line_y = player.global_position.y
	enemy.attack_damage = enemy_attack_damage
	enemy.attack_tick.connect(_on_enemy_attack_tick)
	enemy.defeated.connect(_on_enemy_defeated)

	var viewport_size := get_viewport_rect().size
	enemy.global_position = Vector2(randf_range(40.0, viewport_size.x - 40.0), -32.0)
	enemy_container.add_child(enemy)
	enemy.configure_for_run(player.global_position.y, enemy_attack_damage, enemy_max_health)

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
			"projectile_penetration": 0,
			"split_count": 0,
			"split_damage_ratio": 0.52,
			"explosion_radius": 0.0,
			"explosion_damage_ratio": 0.0,
			"laser_width": float(entry.laser_width),
			"laser_duration": float(entry.laser_duration),
			"laser_chain_count": 0,
			"laser_chain_range": 150.0,
			"laser_chain_falloff": 0.72,
			"laser_burn_damage": 0.0,
			"laser_burn_ticks": 0,
			"laser_burn_interval": 0.22,
			"summon_duration": float(entry.summon_duration),
			"summon_tick_interval": float(entry.summon_tick_interval),
			"summon_radius": float(entry.summon_radius),
			"summon_extra_fields": 0,
			"summon_explode_damage_ratio": 0.0,
			"summon_explode_radius_bonus": 0.0,
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
	if _initial_weapon_id == "":
		_initial_weapon_id = weapon_id
	if not _weapon_upgrade_levels.has(weapon_id):
		_weapon_upgrade_levels[weapon_id] = {}
	if not _weapon_upgrade_order.has(weapon_id):
		_weapon_upgrade_order[weapon_id] = []
	_refresh_upgrade_history_tabs()
	if upgrade_history_panel.visible:
		_refresh_upgrade_history_records()

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
		if enemy.is_defeated():
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

	var field_count := 1 + int(weapon.get("summon_extra_fields", 0))
	var orbit_radius := maxf(18.0, float(weapon.summon_radius) * 0.38)
	for index in field_count:
		var field_pos := spawn_position
		if index > 0:
			var angle := TAU * float(index - 1) / float(max(1, field_count - 1))
			field_pos += Vector2.RIGHT.rotated(angle) * orbit_radius
		_spawn_black_hole_field(weapon, field_pos, damage)

func _spawn_black_hole_field(weapon: Dictionary, position: Vector2, damage: float) -> void:
	var source_weapon_id := StringName(String(weapon.id))
	var info := DamageInfo.from_values(damage, &"summon", source_weapon_id)
	var field := AOE_FIELD_SCENE.instantiate() as AOEFieldRuntime
	field.global_position = position
	field.configure(float(weapon.summon_radius), float(weapon.summon_tick_interval), float(weapon.summon_duration), info)
	field.set_meta("burst_damage", damage * float(weapon.get("summon_explode_damage_ratio", 0.0)))
	field.set_meta("burst_radius", float(weapon.summon_radius) + float(weapon.get("summon_explode_radius_bonus", 0.0)))
	field.set_meta("source_weapon_id", String(source_weapon_id))
	field.pulse_damage.connect(_on_summon_pulse_damage)
	field.expired.connect(_on_summon_expired)
	summon_container.add_child(field)

func _on_summon_pulse_damage(position: Vector2, radius: float, info: DamageInfo) -> void:
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.is_defeated():
			continue
		if enemy.global_position.distance_to(position) > radius:
			continue
		_apply_damage_to_enemy(enemy, info)

func _on_summon_expired(field: AOEFieldRuntime) -> void:
	if field == null:
		return
	if not is_instance_valid(field):
		return
	var burst_damage := float(field.get_meta("burst_damage", 0.0))
	if burst_damage > 0.0:
		var burst_radius := maxf(10.0, float(field.get_meta("burst_radius", 0.0)))
		var source_weapon_id := StringName(String(field.get_meta("source_weapon_id", "")))
		_apply_area_damage(field.global_position, burst_radius, burst_damage, &"summon", source_weapon_id)
	field.queue_free()

func _fire_laser_weapon(weapon: Dictionary, target_enemy: EnemyBase, damage: float) -> void:
	if target_enemy == null:
		return
	if not is_instance_valid(target_enemy):
		return

	var source_weapon_id := StringName(String(weapon.id))
	var damage_info := DamageInfo.from_values(damage, &"laser", source_weapon_id)
	_apply_damage_to_enemy(target_enemy, damage_info)
	_try_apply_laser_burn(target_enemy, weapon)
	_try_fire_laser_chains(target_enemy, weapon, damage)

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

func _spawn_projectile(direction: Vector2, hit_radius: float, damage: float, target_enemy: EnemyBase, weapon_id: String, spawn_position: Vector2 = Vector2.INF, can_split: bool = true, penetration_override: int = -1) -> void:
	var bullet := BULLET_SCENE.instantiate() as ProjectileRuntime
	if spawn_position == Vector2.INF:
		bullet.global_position = player.global_position
	else:
		bullet.global_position = spawn_position
	bullet.direction = direction.normalized()
	bullet.target_enemy = target_enemy
	bullet.set_meta("hit_radius", hit_radius)
	bullet.set_meta("damage", damage)
	bullet.set_meta("weapon_id", weapon_id)
	var weapon: Dictionary = _weapon_pool.get(weapon_id, {})
	var penetration := int(weapon.get("projectile_penetration", 0))
	if penetration_override >= 0:
		penetration = penetration_override
	bullet.set_meta("penetrations_left", penetration)
	bullet.set_meta("split_count", int(weapon.get("split_count", 0)))
	bullet.set_meta("split_damage_ratio", float(weapon.get("split_damage_ratio", 0.52)))
	bullet.set_meta("explosion_radius", float(weapon.get("explosion_radius", 0.0)))
	bullet.set_meta("explosion_damage_ratio", float(weapon.get("explosion_damage_ratio", 0.0)))
	bullet.set_meta("can_split", can_split)
	bullet.set_meta("hit_enemy_ids", PackedInt64Array())
	bullet.configure_display_profile(_projectile_display_profile_for_weapon(weapon_id, not can_split))
	bullet_container.add_child(bullet)

func _projectile_display_profile_for_weapon(weapon_id: String, is_split_child: bool = false) -> Dictionary:
	var profile := {
		"rotation_follows_direction": true,
		"rotation_offset_degrees": 90.0,
		"scale": 1.0,
		"trail_enabled": false,
		"trail_color": Color(1.0, 0.95, 0.6, 0.45),
		"trail_amount": 8,
		"trail_lifetime": 0.16,
		"trail_scale": 0.55,
		"color": Color(1.0, 0.9, 0.2, 1.0),
		"impact_color": Color(1.0, 0.92, 0.35, 0.9),
		"despawn_color": Color(0.8, 0.82, 0.9, 0.72),
		"impact_effect_scale": 1.0,
		"despawn_effect_scale": 0.7,
		"impact_effect_shape": PackedVector2Array([Vector2(-4,0),Vector2(0,-4), Vector2(4,0),Vector2(0,4)]),
		"despawn_effect_shape": PackedVector2Array([Vector2(-3,0),Vector2(0,-3), Vector2(3,0),Vector2(0,3)]),
		"shape_points": PackedVector2Array([Vector2(0,-6),Vector2(4,3), Vector2(0,6),Vector2(-4, 3)]),
	}
	match weapon_id:
		"pulse":
			profile["color"] = Color(1.0, 0.95, 0.32, 1.0)
			profile["impact_color"] = Color(1.0, 0.9, 0.3, 0.95)
			profile["shape_points"] = PackedVector2Array([Vector2(0,-6),Vector2(5,0), Vector2(0,6),Vector2(-5, 0)])
			profile["trail_enabled"] = true
			profile["trail_color"] = Color(1.0, 0.9, 0.35, 0.46)
			profile["trail_amount"] = 9
			profile["trail_lifetime"] = 0.14
			profile["trail_scale"] = 0.52
			profile["impact_effect_scale"] = 1.15
			profile["impact_effect_shape"] = PackedVector2Array([Vector2(0,-8),Vector2(3,-3), Vector2(8,0),Vector2(3,3), Vector2(0,8),Vector2(-3,3), Vector2(-8,0),Vector2(-3,-3)])
		"scatter":
			profile["color"] = Color(1.0, 0.66, 0.28, 1.0)
			profile["impact_color"] = Color(1.0, 0.74, 0.32, 0.95)
			profile["shape_points"] = PackedVector2Array([Vector2(-5,-3),Vector2(5,-3), Vector2(5,3),Vector2(-5,3)])
			profile["rotation_follows_direction"] = false
			profile["impact_effect_scale"] = 0.9
			profile["despawn_effect_scale"] = 0.65
			profile["impact_effect_shape"] = PackedVector2Array([Vector2(-8,-1),Vector2(8,-1), Vector2(8,1),Vector2(-8,1)])
			profile["despawn_effect_shape"] = PackedVector2Array([Vector2(-6,-2),Vector2(0,-1), Vector2(6,-2),Vector2(2,0), Vector2(6,2),Vector2(0,1), Vector2(-6,2),Vector2(-2,0)])
		"arc":
			profile["color"] = Color(0.46, 0.95, 1.0, 1.0)
			profile["impact_color"] = Color(0.56, 0.92, 1.0, 0.95)
			profile["despawn_color"] = Color(0.42, 0.8, 1.0, 0.7)
			profile["shape_points"] = PackedVector2Array([Vector2(0,7),Vector2(5,5), Vector2(-5,5)])
			profile["trail_enabled"] = true
			profile["trail_color"] = Color(0.62, 0.98, 1.0, 0.62)
			profile["trail_amount"] = 16
			profile["trail_lifetime"] = 0.2
			profile["trail_scale"] = 0.8
			profile["impact_effect_scale"] = 1.25
			profile["despawn_effect_scale"] = 0.88
			profile["impact_effect_shape"] = PackedVector2Array([Vector2(-2,-8),Vector2(2,-3), Vector2(0,-1),Vector2(5,4), Vector2(1,3),Vector2(-1,8), Vector2(-4,3),Vector2(-1,2)])
			profile["despawn_effect_shape"] = PackedVector2Array([Vector2(0,-6),Vector2(4,-1), Vector2(2,4),Vector2(-2,4), Vector2(-4,-1)])
		_:
			pass

	if is_split_child:
		profile["scale"] = 0.78
		profile["trail_enabled"] = false
		profile["impact_effect_scale"] = float(profile.get("impact_effect_scale", 1.0)) * 0.72
		profile["despawn_effect_scale"] = float(profile.get("despawn_effect_scale", 0.7)) * 0.68
	return profile

func _try_fire_laser_chains(first_target: EnemyBase, weapon: Dictionary, base_damage: float) -> void:
	var chain_count := int(weapon.get("laser_chain_count", 0))
	if chain_count <= 0:
		return
	var chain_range := maxf(30.0, float(weapon.get("laser_chain_range", 150.0)))
	var falloff := clampf(float(weapon.get("laser_chain_falloff", 0.72)), 0.2, 0.95)
	var source_weapon_id := StringName(String(weapon.id))
	var current_enemy := first_target
	var chain_damage := base_damage * falloff
	var ignored_ids: Dictionary = {first_target.get_instance_id(): true}

	for _index in chain_count:
		if chain_damage <= 0.2:
			return
		var next_enemy := _find_nearest_enemy_to_point(current_enemy.global_position, chain_range, ignored_ids)
		if next_enemy == null:
			return
		var chain_info := DamageInfo.from_values(chain_damage, &"laser", source_weapon_id)
		_apply_damage_to_enemy(next_enemy, chain_info)
		_try_apply_laser_burn(next_enemy, weapon)
		_spawn_laser_line(current_enemy.global_position, next_enemy.global_position, maxf(1.0, float(weapon.laser_width) * 0.75), maxf(0.02, float(weapon.laser_duration) * 0.9))
		ignored_ids[next_enemy.get_instance_id()] = true
		current_enemy = next_enemy
		chain_damage *= falloff

func _try_apply_laser_burn(target_enemy: EnemyBase, weapon: Dictionary) -> void:
	var burn_damage := float(weapon.get("laser_burn_damage", 0.0))
	var burn_ticks := int(weapon.get("laser_burn_ticks", 0))
	if burn_damage <= 0.0 or burn_ticks <= 0:
		return
	_apply_laser_burn_tick(target_enemy, burn_damage, burn_ticks, maxf(0.05, float(weapon.get("laser_burn_interval", 0.22))), StringName(String(weapon.id)))

func _apply_laser_burn_tick(target_enemy: EnemyBase, burn_damage: float, ticks_left: int, interval: float, source_weapon_id: StringName) -> void:
	if ticks_left <= 0:
		return
	var timer := get_tree().create_timer(interval)
	timer.timeout.connect(func() -> void:
		if _is_run_over or GameState.is_paused:
			return
		if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.is_defeated():
			return
		var burn_info := DamageInfo.from_values(burn_damage, &"laser", source_weapon_id)
		_apply_damage_to_enemy(target_enemy, burn_info)
		_apply_laser_burn_tick(target_enemy, burn_damage, ticks_left - 1, interval, source_weapon_id)
	)

func _find_nearest_enemy_to_point(origin: Vector2, max_distance: float, ignored_ids: Dictionary = {}) -> EnemyBase:
	var nearest_enemy: EnemyBase = null
	var nearest_distance := max_distance
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.is_defeated():
			continue
		var enemy_id := enemy.get_instance_id()
		if ignored_ids.has(enemy_id):
			continue
		var distance := enemy.global_position.distance_to(origin)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest_enemy = enemy
	return nearest_enemy

func _apply_area_damage(center: Vector2, radius: float, damage: float, source_kind: StringName, source_weapon_id: StringName) -> void:
	if damage <= 0.0:
		return
	if radius <= 0.0:
		return
	var info := DamageInfo.from_values(damage, source_kind, source_weapon_id)
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.is_defeated():
			continue
		if enemy.global_position.distance_to(center) > radius:
			continue
		_apply_damage_to_enemy(enemy, info)

func _update_projectile_state() -> void:
	var viewport_size := get_viewport_rect().size
	for bullet_child in bullet_container.get_children():
		var bullet := bullet_child as ProjectileRuntime
		if bullet == null:
			continue

		if _is_out_of_viewport(bullet.global_position, viewport_size):
			bullet.despawn(&"despawn")
			continue

		var hit_radius := float(bullet.get_meta("hit_radius", 18.0))
		var hit_enemy := _find_hit_enemy_for_bullet(bullet, hit_radius)
		if hit_enemy != null:
			var damage := float(bullet.get_meta("damage", 1.0))
			var source_weapon_id := StringName(String(bullet.get_meta("weapon_id", "")))
			var damage_info := DamageInfo.from_values(damage, &"projectile", source_weapon_id)
			_apply_damage_to_enemy(hit_enemy, damage_info)
			_record_bullet_hit_enemy(bullet, hit_enemy)
			_trigger_projectile_special_effects(bullet, hit_enemy, damage, source_weapon_id)
			var penetrations_left := int(bullet.get_meta("penetrations_left", 0))
			if penetrations_left <= 0:
				bullet.despawn(&"impact")
				continue
			bullet.set_meta("penetrations_left", penetrations_left - 1)

func _on_enemy_defeated(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	_kill_count += 1
	_gain_experience(exp_per_kill)

func _apply_damage_to_enemy(enemy: EnemyBase, info: DamageInfo) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	enemy.apply_damage_info(info)

func _find_hit_enemy_for_bullet(bullet: ProjectileRuntime, hit_radius: float) -> EnemyBase:
	var hit_ids := PackedInt64Array(bullet.get_meta("hit_enemy_ids", PackedInt64Array()))
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.is_defeated():
			continue
		if hit_ids.has(enemy.get_instance_id()):
			continue
		if enemy.global_position.distance_to(bullet.global_position) <= hit_radius:
			return enemy
	return null

func _record_bullet_hit_enemy(bullet: ProjectileRuntime, enemy: EnemyBase) -> void:
	var hit_ids := PackedInt64Array(bullet.get_meta("hit_enemy_ids", PackedInt64Array()))
	hit_ids.append(enemy.get_instance_id())
	bullet.set_meta("hit_enemy_ids", hit_ids)

func _trigger_projectile_special_effects(bullet: ProjectileRuntime, hit_enemy: EnemyBase, damage: float, source_weapon_id: StringName) -> void:
	var explosion_radius := float(bullet.get_meta("explosion_radius", 0.0))
	var explosion_ratio := float(bullet.get_meta("explosion_damage_ratio", 0.0))
	if explosion_radius > 0.0 and explosion_ratio > 0.0:
		var splash_damage := damage * explosion_ratio
		_apply_area_damage(hit_enemy.global_position, explosion_radius, splash_damage, &"projectile", source_weapon_id)

	if not bool(bullet.get_meta("can_split", true)):
		return
	var split_count := int(bullet.get_meta("split_count", 0))
	if split_count <= 0:
		return
	var split_ratio := float(bullet.get_meta("split_damage_ratio", 0.52))
	var split_damage := damage * split_ratio
	if split_damage <= 0.0:
		return
	var hit_radius := float(bullet.get_meta("hit_radius", 18.0))
	var spread := 18.0
	var center_index := float(split_count - 1) * 0.5
	for index in split_count:
		var angle_deg := (float(index) - center_index) * spread
		var split_direction := bullet.direction.rotated(deg_to_rad(angle_deg))
		_spawn_projectile(split_direction, hit_radius, split_damage, null, String(source_weapon_id), hit_enemy.global_position, false, 0)

func _alive_enemy_count() -> int:
	var alive_count := 0
	for child in enemy_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		if enemy.is_defeated():
			continue
		alive_count += 1
	return alive_count

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
	upgrade_history_panel.visible = false

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
	upgrade_history_panel.visible = false
	var best_time_text := "%.1f" % GameState.best_time_seconds
	if GameState.best_time_seconds >= 999998.0:
		best_time_text = "--"
	victory_desc_label.text = "难度: %s\n通关波次: %d\n击杀: %d\n等级: %d\n用时: %.1f 秒\n本局金币: %d\n累计金币: %d\n最佳击杀: %d\n最佳等级: %d\n最佳用时: %s 秒" % [GameState.difficulty_key, _current_wave_index, _kill_count, _current_level, _run_elapsed_seconds, reward_gold, GameState.total_gold, GameState.best_kills, GameState.best_level, best_time_text]

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_toggle_upgrade_history_pressed() -> void:
	upgrade_history_panel.visible = not upgrade_history_panel.visible
	if not upgrade_history_panel.visible:
		return
	if _initial_weapon_id != "" and _equipped_weapon_ids.has(_initial_weapon_id):
		_selected_history_weapon_id = _initial_weapon_id
	elif not _equipped_weapon_ids.is_empty():
		_selected_history_weapon_id = _equipped_weapon_ids[0]
	else:
		_selected_history_weapon_id = ""
	_refresh_upgrade_history_tabs()
	_refresh_upgrade_history_records()

func _on_pick_history_weapon(weapon_id: String) -> void:
	if weapon_id == "":
		return
	_selected_history_weapon_id = weapon_id
	_refresh_upgrade_history_tabs()
	_refresh_upgrade_history_records()

func _refresh_upgrade_history_tabs() -> void:
	if upgrade_history_tab_row == null:
		return
	for child in upgrade_history_tab_row.get_children():
		child.queue_free()
	if _equipped_weapon_ids.is_empty():
		return
	if _selected_history_weapon_id == "" or not _equipped_weapon_ids.has(_selected_history_weapon_id):
		_selected_history_weapon_id = _equipped_weapon_ids[0]

	for weapon_id in _equipped_weapon_ids:
		var weapon: Dictionary = _weapon_pool.get(weapon_id, {})
		var tab_button := Button.new()
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.toggle_mode = true
		tab_button.button_pressed = weapon_id == _selected_history_weapon_id
		tab_button.text = "%s %s" % [_icon_for_weapon(weapon_id), String(weapon.get("name", weapon_id))]
		tab_button.pressed.connect(_on_pick_history_weapon.bind(weapon_id))
		upgrade_history_tab_row.add_child(tab_button)

func _refresh_upgrade_history_records() -> void:
	if upgrade_history_record_list == null:
		return
	upgrade_history_record_list.clear()
	if _selected_history_weapon_id == "":
		upgrade_history_record_list.add_item("暂无武器记录")
		return
	var weapon: Dictionary = _weapon_pool.get(_selected_history_weapon_id, {})
	upgrade_history_record_list.add_item("武器：%s" % String(weapon.get("name", _selected_history_weapon_id)))

	var levels : Dictionary = _weapon_upgrade_levels.get(_selected_history_weapon_id, {})
	var order : Array = _weapon_upgrade_order.get(_selected_history_weapon_id, [])
	if order.is_empty():
		upgrade_history_record_list.add_item("暂无强化记录")
		return

	for upgrade_type_key_value in order:
		var upgrade_type_key := String(upgrade_type_key_value)
		var level := int(levels.get(upgrade_type_key, 0))
		if level <= 0:
			continue
		var upgrade_type := StringName(upgrade_type_key)
		upgrade_history_record_list.add_item("%s %s Lv.%d" % [_icon_for_upgrade_type(upgrade_type), _upgrade_name_for_type(upgrade_type), level])

func _record_weapon_upgrade(weapon_id: String, upgrade_type: StringName) -> void:
	if weapon_id == "":
		return
	var upgrade_type_key := String(upgrade_type)
	if upgrade_type_key == "":
		return
	if not _weapon_upgrade_levels.has(weapon_id):
		_weapon_upgrade_levels[weapon_id] = {}
	if not _weapon_upgrade_order.has(weapon_id):
		_weapon_upgrade_order[weapon_id] = []

	var levels := _weapon_upgrade_levels[weapon_id] as Dictionary
	levels[upgrade_type_key] = int(levels.get(upgrade_type_key, 0)) + 1
	_weapon_upgrade_levels[weapon_id] = levels

	var order := _weapon_upgrade_order[weapon_id] as Array
	if not order.has(upgrade_type_key):
		order.append(upgrade_type_key)
	_weapon_upgrade_order[weapon_id] = order

	if upgrade_history_panel.visible and _selected_history_weapon_id == weapon_id:
		_refresh_upgrade_history_records()

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
	wave_label.text = "Wave: %d/%d  Remaining: %d" % [_current_wave_index, _effective_total_waves, _current_wave_spawn_remaining + _alive_enemy_count()]

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
	var selection_pool := _build_skill_selection_pool()
	_upgrade_options = _pick_upgrade_options(selection_pool, UPGRADE_OPTION_COUNT)

	for index in _upgrade_buttons.size():
		var option_button := _upgrade_buttons[index]
		if index < _upgrade_options.size():
			var option := _upgrade_options[index]
			var display := _build_upgrade_option_display(option)
			var card_view := _upgrade_card_views[index]
			var title_label := card_view.get("title", null) as Label
			var icon_label := card_view.get("icon", null) as Label
			var effect_label := card_view.get("effect", null) as Label
			if title_label != null:
				title_label.text = String(display.get("title", "强化"))
			if icon_label != null:
				icon_label.text = String(display.get("icon", "◆"))
			if effect_label != null:
				effect_label.text = String(display.get("effect", ""))
			option_button.visible = true
			option_button.disabled = false
			option_button.tooltip_text = String(option.get("label", "强化武器"))
		else:
			option_button.visible = false
			option_button.disabled = true

func _build_skill_selection_pool() -> Dictionary:
	var unlock_options := _build_unlock_options()
	var weapon_upgrade_options: Array[Dictionary] = []
	for weapon_id in _equipped_weapon_ids:
		weapon_upgrade_options.append_array(_build_weapon_upgrade_options(weapon_id))

	var must_offer: Array[Dictionary] = []
	var high_priority: Array[Dictionary] = []
	var normal: Array[Dictionary] = []
	var unlocked_count := _equipped_weapon_ids.size()
	var max_unlock_priority_count : int = max(0, PREFERRED_WEAPON_COUNT - unlocked_count)
	var unlock_priority_count := 0
	if unlocked_count < min(PREFERRED_WEAPON_COUNT, max_equipped_weapons):
		unlock_priority_count = min(unlock_options.size(), max(1, min(UPGRADE_OPTION_COUNT - 1, max_unlock_priority_count)))

	for index in unlock_priority_count:
		must_offer.append(unlock_options[index])

	for index in range(unlock_priority_count, unlock_options.size()):
		high_priority.append(unlock_options[index])

	high_priority.append_array(weapon_upgrade_options)
	return {
		"must_offer": must_offer,
		"high_priority": high_priority,
		"normal": normal,
	}

func _pick_upgrade_options(selection_pool: Dictionary, limit: int) -> Array[Dictionary]:
	var picked: Array[Dictionary] = []
	var used_keys: Dictionary = {}
	var must_offer : Array = selection_pool.get("must_offer", [])
	var high_priority : Array = selection_pool.get("high_priority", [])
	var normal : Array = selection_pool.get("normal", [])
	_append_unique_upgrade_options(picked, used_keys, must_offer, limit)
	high_priority.shuffle()
	_append_unique_upgrade_options(picked, used_keys, high_priority, limit)
	normal.shuffle()
	_append_unique_upgrade_options(picked, used_keys, normal, limit)
	return picked

func _append_unique_upgrade_options(picked: Array[Dictionary], used_keys: Dictionary, source_options: Array, limit: int) -> void:
	for option_value in source_options:
		if picked.size() >= limit:
			return
		if typeof(option_value) != TYPE_DICTIONARY:
			continue
		var option := option_value as Dictionary
		var option_key := String(option.get("option_key", ""))
		if option_key == "":
			continue
		if used_keys.has(option_key):
			continue
		used_keys[option_key] = true
		picked.append(option)

func _build_upgrade_option_display(option: Dictionary) -> Dictionary:
	var raw_label := String(option.get("label", "强化武器"))
	var lines := raw_label.split("\n", false)
	var title := raw_label
	var effect := ""
	if not lines.is_empty():
		title = lines[0]
		if lines.size() > 1:
			effect = lines[1]
	return {
		"title": title,
		"icon": _icon_for_upgrade_option(option),
		"effect": effect,
	}

func _icon_for_upgrade_option(option: Dictionary) -> String:
	var option_type := StringName(String(option.get("type", "")))
	if option_type == OPTION_UNLOCK_WEAPON:
		return "✚"
	return _icon_for_upgrade_type(StringName(String(option.get("upgrade_type", ""))))

func _icon_for_upgrade_type(upgrade_type: StringName) -> String:
	match upgrade_type:
		UPGRADE_DAMAGE:
			return "✹"
		UPGRADE_FIRE_RATE:
			return "⚡"
		UPGRADE_PROJECTILE_COUNT:
			return "◉"
		UPGRADE_HIT_RADIUS:
			return "◎"
		UPGRADE_PIERCE:
			return "➤"
		UPGRADE_SPLIT:
			return "✶"
		UPGRADE_EXPLOSION:
			return "✸"
		UPGRADE_PULSE_OVERLOAD:
			return "⬡"
		UPGRADE_SCATTER_BARRAGE:
			return "⬢"
		UPGRADE_ARC_FOCUS:
			return "⬣"
		UPGRADE_LASER_WIDTH:
			return "║"
		UPGRADE_LASER_DURATION:
			return "⏳"
		UPGRADE_LASER_CHAIN:
			return "⌁"
		UPGRADE_LASER_CHAIN_RANGE:
			return "↔"
		UPGRADE_LASER_BURN:
			return "♨"
		UPGRADE_SUMMON_RADIUS:
			return "◌"
		UPGRADE_SUMMON_DURATION:
			return "◍"
		UPGRADE_SUMMON_TICK_RATE:
			return "⟲"
		UPGRADE_SUMMON_EXTRA_FIELD:
			return "☍"
		UPGRADE_SUMMON_IMPLOSION:
			return "✺"
	return "◆"

func _upgrade_name_for_type(upgrade_type: StringName) -> String:
	match upgrade_type:
		UPGRADE_DAMAGE:
			return "伤害提升"
		UPGRADE_FIRE_RATE:
			return "射速提升"
		UPGRADE_PROJECTILE_COUNT:
			return "子弹增加"
		UPGRADE_HIT_RADIUS:
			return "命中范围"
		UPGRADE_PIERCE:
			return "穿透强化"
		UPGRADE_SPLIT:
			return "分裂弹头"
		UPGRADE_EXPLOSION:
			return "爆炸弹头"
		UPGRADE_PULSE_OVERLOAD:
			return "脉冲过载"
		UPGRADE_SCATTER_BARRAGE:
			return "霰弹压制"
		UPGRADE_ARC_FOCUS:
			return "弧光聚焦"
		UPGRADE_LASER_WIDTH:
			return "激光宽度"
		UPGRADE_LASER_DURATION:
			return "激光持续"
		UPGRADE_LASER_CHAIN:
			return "连锁折射"
		UPGRADE_LASER_CHAIN_RANGE:
			return "连锁距离"
		UPGRADE_LASER_BURN:
			return "灼烧回路"
		UPGRADE_SUMMON_RADIUS:
			return "黑洞范围"
		UPGRADE_SUMMON_DURATION:
			return "黑洞持续"
		UPGRADE_SUMMON_TICK_RATE:
			return "脉冲频率"
		UPGRADE_SUMMON_EXTRA_FIELD:
			return "额外黑洞"
		UPGRADE_SUMMON_IMPLOSION:
			return "塌缩爆发"
	return String(upgrade_type)

func _icon_for_weapon(weapon_id: String) -> String:
	match weapon_id:
		"pulse":
			return "◈"
		"laser":
			return "║"
		"blackhole":
			return "◉"
		"scatter":
			return "✸"
		"arc":
			return "⌁"
	return "◆"

func _build_unlock_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if _equipped_weapon_ids.size() >= max_equipped_weapons:
		return options
	for weapon_id in _weapon_order:
		if _equipped_weapon_ids.has(weapon_id):
			continue
		if not _weapon_pool.has(weapon_id):
			continue
		var weapon: Dictionary = _weapon_pool[weapon_id]
		options.append({
			"type": OPTION_UNLOCK_WEAPON,
			"weapon_id": weapon_id,
			"option_key": "unlock:%s" % weapon_id,
			"label": "解锁新武器：%s\n%s" % [String(weapon.name), _build_weapon_unlock_summary(weapon)],
		})
	return options

func _build_weapon_unlock_summary(weapon: Dictionary) -> String:
	var rate := 1.0 / maxf(0.05, float(weapon.fire_interval))
	var weapon_kind := StringName(String(weapon.weapon_kind))
	if weapon_kind == &"laser":
		return "伤害 %.1f | 射速 %.2f/s | 光束宽度 %.1f" % [float(weapon.damage), rate, float(weapon.laser_width)]
	if weapon_kind == &"summon":
		var summon_rate := 1.0 / maxf(0.05, float(weapon.summon_tick_interval))
		return "脉冲 %.1f | 跳频 %.2f/s | 范围 %.0f" % [float(weapon.damage), summon_rate, float(weapon.summon_radius)]
	return "伤害 %.1f | 射速 %.2f/s | 弹丸 %d" % [float(weapon.damage), rate, int(weapon.projectile_count)]

func _build_weapon_upgrade_options(weapon_id: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not _weapon_pool.has(weapon_id):
		return options
	var weapon: Dictionary = _weapon_pool[weapon_id]
	var weapon_kind := StringName(String(weapon.weapon_kind))
	var upgrade_types: Array[StringName] = []
	if weapon_kind == &"laser":
		upgrade_types = [UPGRADE_DAMAGE, UPGRADE_FIRE_RATE, UPGRADE_LASER_WIDTH, UPGRADE_LASER_DURATION, UPGRADE_LASER_CHAIN, UPGRADE_LASER_CHAIN_RANGE, UPGRADE_LASER_BURN]
	elif weapon_kind == &"summon":
		upgrade_types = [UPGRADE_DAMAGE, UPGRADE_FIRE_RATE, UPGRADE_SUMMON_RADIUS, UPGRADE_SUMMON_DURATION, UPGRADE_SUMMON_TICK_RATE, UPGRADE_SUMMON_EXTRA_FIELD, UPGRADE_SUMMON_IMPLOSION]
	else:
		upgrade_types = [UPGRADE_DAMAGE, UPGRADE_FIRE_RATE, UPGRADE_PROJECTILE_COUNT, UPGRADE_HIT_RADIUS, UPGRADE_PIERCE, UPGRADE_SPLIT, UPGRADE_EXPLOSION]
		if weapon_id == "pulse":
			upgrade_types.append(UPGRADE_PULSE_OVERLOAD)
		elif weapon_id == "scatter":
			upgrade_types.append(UPGRADE_SCATTER_BARRAGE)
		elif weapon_id == "arc":
			upgrade_types.append(UPGRADE_ARC_FOCUS)

	for upgrade_type in upgrade_types:
		var option := _build_weapon_upgrade_option(weapon_id, upgrade_type)
		if option.is_empty():
			continue
		options.append(option)
	return options

func _build_weapon_upgrade_option(weapon_id: String, upgrade_type: StringName) -> Dictionary:
	var weapon: Dictionary = _weapon_pool[weapon_id]
	var weapon_name := String(weapon.name)
	match upgrade_type:
		UPGRADE_DAMAGE:
			var before_damage := float(weapon.damage)
			var after_damage := before_damage * 1.2
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_DAMAGE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_DAMAGE)],
				"label": "%s · 高能装药\n伤害 %.1f -> %.1f (+20%%)" % [weapon_name, before_damage, after_damage],
			}
		UPGRADE_FIRE_RATE:
			var before_interval := float(weapon.fire_interval)
			var min_interval := float(weapon.fire_interval_min)
			var after_interval := maxf(min_interval, before_interval * 0.88)
			if is_equal_approx(after_interval, before_interval):
				return {}
			var before_rate := 1.0 / maxf(0.05, before_interval)
			var after_rate := 1.0 / maxf(0.05, after_interval)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_FIRE_RATE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_FIRE_RATE)],
				"label": "%s · 快速循环\n射速 %.2f/s -> %.2f/s" % [weapon_name, before_rate, after_rate],
			}
		UPGRADE_PROJECTILE_COUNT:
			var before_count := int(weapon.projectile_count)
			if before_count >= 8:
				return {}
			var after_count := before_count + 1
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_PROJECTILE_COUNT,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_PROJECTILE_COUNT)],
				"label": "%s · 扩容弹仓\n弹丸数量 %d -> %d" % [weapon_name, before_count, after_count],
			}
		UPGRADE_HIT_RADIUS:
			var before_radius := float(weapon.hit_radius)
			if before_radius >= 54.0:
				return {}
			var after_radius := minf(54.0, before_radius + 3.0)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_HIT_RADIUS,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_HIT_RADIUS)],
				"label": "%s · 稳定弹体\n命中范围 %.0f -> %.0f" % [weapon_name, before_radius, after_radius],
			}
		UPGRADE_PIERCE:
			var before_pierce := int(weapon.get("projectile_penetration", 0))
			if before_pierce >= 4:
				return {}
			var after_pierce := before_pierce + 1
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_PIERCE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_PIERCE)],
				"label": "%s · 穿甲弹芯\n可额外穿透目标 %d -> %d" % [weapon_name, before_pierce, after_pierce],
			}
		UPGRADE_SPLIT:
			var before_split := int(weapon.get("split_count", 0))
			if before_split >= 4:
				return {}
			var after_split := before_split + 1
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SPLIT,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SPLIT)],
				"label": "%s · 裂变弹头\n命中分裂弹数 %d -> %d" % [weapon_name, before_split, after_split],
			}
		UPGRADE_EXPLOSION:
			var before_explosion_radius := float(weapon.get("explosion_radius", 0.0))
			var before_explosion_ratio := float(weapon.get("explosion_damage_ratio", 0.0))
			var after_explosion_radius := minf(72.0, before_explosion_radius + 12.0)
			var after_explosion_ratio := minf(0.9, before_explosion_ratio + 0.12)
			if is_equal_approx(before_explosion_radius, after_explosion_radius) and is_equal_approx(before_explosion_ratio, after_explosion_ratio):
				return {}
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_EXPLOSION,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_EXPLOSION)],
				"label": "%s · 爆轰弹\n半径 %.0f -> %.0f，溅射 %.2f -> %.2f" % [weapon_name, before_explosion_radius, after_explosion_radius, before_explosion_ratio, after_explosion_ratio],
			}
		UPGRADE_PULSE_OVERLOAD:
			var before_pulse_interval := float(weapon.fire_interval)
			var after_pulse_interval := maxf(float(weapon.fire_interval_min), before_pulse_interval * 0.92)
			var before_pulse_radius := float(weapon.hit_radius)
			var after_pulse_radius := minf(60.0, before_pulse_radius + 2.0)
			if is_equal_approx(before_pulse_interval, after_pulse_interval) and is_equal_approx(before_pulse_radius, after_pulse_radius):
				return {}
			var before_pulse_rate := 1.0 / maxf(0.05, before_pulse_interval)
			var after_pulse_rate := 1.0 / maxf(0.05, after_pulse_interval)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_PULSE_OVERLOAD,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_PULSE_OVERLOAD)],
				"label": "%s · 脉冲过载\n射速 %.2f/s -> %.2f/s，命中范围 %.0f -> %.0f" % [weapon_name, before_pulse_rate, after_pulse_rate, before_pulse_radius, after_pulse_radius],
			}
		UPGRADE_SCATTER_BARRAGE:
			var before_scatter_count := int(weapon.projectile_count)
			var before_scatter_spread := float(weapon.spread_degrees)
			var after_scatter_count : int = min(9, before_scatter_count + 1)
			var after_scatter_spread : float = minf(28.0, before_scatter_spread + 2.0)
			if before_scatter_count == after_scatter_count and is_equal_approx(before_scatter_spread, after_scatter_spread):
				return {}
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SCATTER_BARRAGE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SCATTER_BARRAGE)],
				"label": "%s · 霰弹压制\n弹丸 %d -> %d，散射角 %.1f -> %.1f" % [weapon_name, before_scatter_count, after_scatter_count, before_scatter_spread, after_scatter_spread],
			}
		UPGRADE_ARC_FOCUS:
			var before_arc_damage := float(weapon.damage)
			var before_arc_spread := float(weapon.spread_degrees)
			var after_arc_damage := before_arc_damage * 1.12
			var after_arc_spread := maxf(2.0, before_arc_spread - 1.5)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_ARC_FOCUS,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_ARC_FOCUS)],
				"label": "%s · 弧光聚焦\n伤害 %.1f -> %.1f，散射角 %.1f -> %.1f" % [weapon_name, before_arc_damage, after_arc_damage, before_arc_spread, after_arc_spread],
			}
		UPGRADE_LASER_WIDTH:
			var before_width := float(weapon.laser_width)
			if before_width >= 14.0:
				return {}
			var after_width := minf(14.0, before_width + 0.8)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_LASER_WIDTH,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_LASER_WIDTH)],
				"label": "%s · 聚焦棱镜\n激光宽度 %.1f -> %.1f" % [weapon_name, before_width, after_width],
			}
		UPGRADE_LASER_DURATION:
			var before_laser_duration := float(weapon.laser_duration)
			if before_laser_duration >= 0.26:
				return {}
			var after_laser_duration := minf(0.26, before_laser_duration + 0.03)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_LASER_DURATION,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_LASER_DURATION)],
				"label": "%s · 持续灼线\n持续 %.2fs -> %.2fs" % [weapon_name, before_laser_duration, after_laser_duration],
			}
		UPGRADE_LASER_CHAIN:
			var before_chain := int(weapon.get("laser_chain_count", 0))
			if before_chain >= 4:
				return {}
			var after_chain := before_chain + 1
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_LASER_CHAIN,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_LASER_CHAIN)],
				"label": "%s · 连锁折射\n额外连锁目标 %d -> %d" % [weapon_name, before_chain, after_chain],
			}
		UPGRADE_LASER_CHAIN_RANGE:
			var before_chain_range := float(weapon.get("laser_chain_range", 150.0))
			if before_chain_range >= 280.0:
				return {}
			var after_chain_range := minf(280.0, before_chain_range + 24.0)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_LASER_CHAIN_RANGE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_LASER_CHAIN_RANGE)],
				"label": "%s · 导光阵列\n连锁距离 %.0f -> %.0f" % [weapon_name, before_chain_range, after_chain_range],
			}
		UPGRADE_LASER_BURN:
			var before_burn_damage := float(weapon.get("laser_burn_damage", 0.0))
			var before_burn_ticks := int(weapon.get("laser_burn_ticks", 0))
			var after_burn_damage := minf(16.0, before_burn_damage + 2.0)
			var after_burn_ticks : int= min(5, before_burn_ticks + 1)
			if is_equal_approx(before_burn_damage, after_burn_damage) and before_burn_ticks == after_burn_ticks:
				return {}
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_LASER_BURN,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_LASER_BURN)],
				"label": "%s · 灼烧回路\n每跳伤害 %.1f -> %.1f，跳数 %d -> %d" % [weapon_name, before_burn_damage, after_burn_damage, before_burn_ticks, after_burn_ticks],
			}
		UPGRADE_SUMMON_RADIUS:
			var before_summon_radius := float(weapon.summon_radius)
			if before_summon_radius >= 180.0:
				return {}
			var after_summon_radius := minf(180.0, before_summon_radius + 10.0)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SUMMON_RADIUS,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SUMMON_RADIUS)],
				"label": "%s · 奇点扩张\n黑洞范围 %.0f -> %.0f" % [weapon_name, before_summon_radius, after_summon_radius],
			}
		UPGRADE_SUMMON_DURATION:
			var before_summon_duration := float(weapon.summon_duration)
			if before_summon_duration >= 8.0:
				return {}
			var after_summon_duration := minf(8.0, before_summon_duration + 0.5)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SUMMON_DURATION,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SUMMON_DURATION)],
				"label": "%s · 维持稳定\n持续 %.1fs -> %.1fs" % [weapon_name, before_summon_duration, after_summon_duration],
			}
		UPGRADE_SUMMON_TICK_RATE:
			var before_tick_interval := float(weapon.summon_tick_interval)
			var after_tick_interval := maxf(0.08, before_tick_interval * 0.9)
			if is_equal_approx(before_tick_interval, after_tick_interval):
				return {}
			var before_tick_rate := 1.0 / maxf(0.05, before_tick_interval)
			var after_tick_rate := 1.0 / maxf(0.05, after_tick_interval)
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SUMMON_TICK_RATE,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SUMMON_TICK_RATE)],
				"label": "%s · 脉冲加密\n伤害频率 %.2f/s -> %.2f/s" % [weapon_name, before_tick_rate, after_tick_rate],
			}
		UPGRADE_SUMMON_EXTRA_FIELD:
			var before_extra_fields := int(weapon.get("summon_extra_fields", 0))
			if before_extra_fields >= 3:
				return {}
			var after_extra_fields := before_extra_fields + 1
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SUMMON_EXTRA_FIELD,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SUMMON_EXTRA_FIELD)],
				"label": "%s · 双星引力\n额外黑洞数量 %d -> %d" % [weapon_name, before_extra_fields, after_extra_fields],
			}
		UPGRADE_SUMMON_IMPLOSION:
			var before_implosion_ratio := float(weapon.get("summon_explode_damage_ratio", 0.0))
			var before_implosion_radius := float(weapon.get("summon_explode_radius_bonus", 0.0))
			var after_implosion_ratio := minf(1.0, before_implosion_ratio + 0.15)
			var after_implosion_radius := minf(72.0, before_implosion_radius + 8.0)
			if is_equal_approx(before_implosion_ratio, after_implosion_ratio) and is_equal_approx(before_implosion_radius, after_implosion_radius):
				return {}
			return {
				"type": OPTION_WEAPON_UPGRADE,
				"weapon_id": weapon_id,
				"upgrade_type": UPGRADE_SUMMON_IMPLOSION,
				"option_key": "%s:%s" % [weapon_id, String(UPGRADE_SUMMON_IMPLOSION)],
				"label": "%s · 塌缩爆发\n结束爆发 %.2f -> %.2f，额外半径 %.0f -> %.0f" % [weapon_name, before_implosion_ratio, after_implosion_ratio, before_implosion_radius, after_implosion_radius],
			}
	return {}

func _close_upgrade_panel() -> void:
	_pending_level_ups = max(0, _pending_level_ups - 1)
	if _pending_level_ups > 0:
		GameState.is_paused = true
		upgrade_panel.visible = true
		_refresh_upgrade_options()
		return
	_is_upgrade_open = false
	GameState.is_paused = false
	upgrade_panel.visible = false

func _on_pick_upgrade(option_index: int) -> void:
	if option_index < 0 or option_index >= _upgrade_options.size():
		return
	_apply_upgrade(_upgrade_options[option_index])
	_close_upgrade_panel()

func _apply_upgrade(option: Dictionary) -> void:
	if option.is_empty():
		return
	var option_type := StringName(String(option.get("type", "")))
	var weapon_id := String(option.get("weapon_id", ""))

	match option_type:
		OPTION_UNLOCK_WEAPON:
			_unlock_weapon(weapon_id)
		OPTION_WEAPON_UPGRADE:
			var upgrade_type := StringName(String(option.get("upgrade_type", "")))
			_apply_weapon_upgrade(weapon_id, upgrade_type)
			_record_weapon_upgrade(weapon_id, upgrade_type)

func _apply_weapon_upgrade(weapon_id: String, upgrade_type: StringName) -> void:
	if not _weapon_pool.has(weapon_id):
		return
	var weapon: Dictionary = _weapon_pool[weapon_id]
	match upgrade_type:
		UPGRADE_DAMAGE:
			weapon.damage = float(weapon.damage) * 1.2
		UPGRADE_FIRE_RATE:
			weapon.fire_interval = maxf(float(weapon.fire_interval_min), float(weapon.fire_interval) * 0.88)
		UPGRADE_PROJECTILE_COUNT:
			weapon.projectile_count = min(8, int(weapon.projectile_count) + 1)
		UPGRADE_HIT_RADIUS:
			weapon.hit_radius = minf(54.0, float(weapon.hit_radius) + 3.0)
		UPGRADE_PIERCE:
			weapon.projectile_penetration = min(4, int(weapon.get("projectile_penetration", 0)) + 1)
		UPGRADE_SPLIT:
			weapon.split_count = min(4, int(weapon.get("split_count", 0)) + 1)
		UPGRADE_EXPLOSION:
			weapon.explosion_radius = minf(72.0, float(weapon.get("explosion_radius", 0.0)) + 12.0)
			weapon.explosion_damage_ratio = minf(0.9, float(weapon.get("explosion_damage_ratio", 0.0)) + 0.12)
		UPGRADE_PULSE_OVERLOAD:
			weapon.fire_interval = maxf(float(weapon.fire_interval_min), float(weapon.fire_interval) * 0.92)
			weapon.hit_radius = minf(60.0, float(weapon.hit_radius) + 2.0)
		UPGRADE_SCATTER_BARRAGE:
			weapon.projectile_count = min(9, int(weapon.projectile_count) + 1)
			weapon.spread_degrees = minf(28.0, float(weapon.spread_degrees) + 2.0)
		UPGRADE_ARC_FOCUS:
			weapon.damage = float(weapon.damage) * 1.12
			weapon.spread_degrees = maxf(2.0, float(weapon.spread_degrees) - 1.5)
		UPGRADE_LASER_WIDTH:
			weapon.laser_width = minf(14.0, float(weapon.laser_width) + 0.8)
		UPGRADE_LASER_DURATION:
			weapon.laser_duration = minf(0.26, float(weapon.laser_duration) + 0.03)
		UPGRADE_LASER_CHAIN:
			weapon.laser_chain_count = min(4, int(weapon.get("laser_chain_count", 0)) + 1)
		UPGRADE_LASER_CHAIN_RANGE:
			weapon.laser_chain_range = minf(280.0, float(weapon.get("laser_chain_range", 150.0)) + 24.0)
		UPGRADE_LASER_BURN:
			weapon.laser_burn_damage = minf(16.0, float(weapon.get("laser_burn_damage", 0.0)) + 2.0)
			weapon.laser_burn_ticks = min(5, int(weapon.get("laser_burn_ticks", 0)) + 1)
		UPGRADE_SUMMON_RADIUS:
			weapon.summon_radius = minf(180.0, float(weapon.summon_radius) + 10.0)
		UPGRADE_SUMMON_DURATION:
			weapon.summon_duration = minf(8.0, float(weapon.summon_duration) + 0.5)
		UPGRADE_SUMMON_TICK_RATE:
			weapon.summon_tick_interval = maxf(0.08, float(weapon.summon_tick_interval) * 0.9)
		UPGRADE_SUMMON_EXTRA_FIELD:
			weapon.summon_extra_fields = min(3, int(weapon.get("summon_extra_fields", 0)) + 1)
		UPGRADE_SUMMON_IMPLOSION:
			weapon.summon_explode_damage_ratio = minf(1.0, float(weapon.get("summon_explode_damage_ratio", 0.0)) + 0.15)
			weapon.summon_explode_radius_bonus = minf(72.0, float(weapon.get("summon_explode_radius_bonus", 0.0)) + 8.0)

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
