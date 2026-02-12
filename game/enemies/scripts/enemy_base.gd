extends CharacterBody2D
class_name EnemyBase

signal attack_tick(damage: float)
signal defeated(enemy: EnemyBase)

@export var move_speed := 110.0
@export var attack_interval := 0.9
@export var attack_damage := 8.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_layer: Node2D = $DamageLayer

var attack_line_y := INF
var _is_attacking := false
var _attack_cooldown := 0.0
var _is_dead := false
var _pending_attack_line_y := INF
var _pending_attack_damage := 0.0
var _pending_max_health := 0.0
var _has_pending_config := false

func _ready() -> void:
	health_component.died.connect(_on_health_died)
	if _has_pending_config:
		_apply_runtime_config(_pending_attack_line_y, _pending_attack_damage, _pending_max_health)
		_has_pending_config = false
	_refresh_health_bar()

func configure_for_run(next_attack_line_y: float, next_attack_damage: float, next_max_health: float) -> void:
	if not is_node_ready() or health_component == null:
		_pending_attack_line_y = next_attack_line_y
		_pending_attack_damage = next_attack_damage
		_pending_max_health = next_max_health
		_has_pending_config = true
		return

	_apply_runtime_config(next_attack_line_y, next_attack_damage, next_max_health)

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return

	if GameState.is_paused:
		velocity = Vector2.ZERO
		return

	if _is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		_tick_attack(delta)
		return

	velocity = Vector2.DOWN * move_speed
	move_and_slide()

	if global_position.y >= attack_line_y:
		_is_attacking = true
		velocity = Vector2.ZERO
		_attack_cooldown = 0.0

func apply_weapon_hit(damage: float, source_kind: StringName = &"projectile", source_weapon_id: StringName = &"") -> bool:
	var info := DamageInfo.from_values(damage, source_kind, source_weapon_id)
	return apply_damage_info(info)

func apply_damage_info(info: DamageInfo) -> bool:
	if _is_dead:
		return true
	if info == null:
		return false

	var final_damage := maxf(0.0, info.amount)
	if final_damage <= 0.0:
		return false

	if info.source_kind == &"projectile" and info.source_weapon_id != &"":
		pass

	health_component.apply_damage(final_damage)
	_show_damage_popup(final_damage)
	_refresh_health_bar()
	return _is_dead

func is_defeated() -> bool:
	return _is_dead

func _tick_attack(delta: float) -> void:
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = maxf(0.1, attack_interval)
	attack_tick.emit(attack_damage)

func _on_health_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	defeated.emit(self)

func _refresh_health_bar() -> void:
	health_bar.max_value = health_component.max_health
	health_bar.value = health_component.current_health
	health_bar.visible = health_component.current_health < health_component.max_health and not _is_dead

func _show_damage_popup(damage: float) -> void:
	var damage_label := Label.new()
	damage_label.text = "%.0f" % damage
	damage_label.position = Vector2(-10.0, -42.0)
	damage_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	damage_label.z_index = 10
	damage_layer.add_child(damage_label)

	var tween := create_tween()
	tween.tween_property(damage_label, "position", damage_label.position + Vector2(0.0, -14.0), 0.35)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.35)
	tween.finished.connect(damage_label.queue_free)

func _apply_runtime_config(next_attack_line_y: float, next_attack_damage: float, next_max_health: float) -> void:
	attack_line_y = next_attack_line_y
	attack_damage = next_attack_damage
	health_component.max_health = maxf(1.0, next_max_health)
	health_component.current_health = health_component.max_health
	_is_dead = false
	_is_attacking = false
	_attack_cooldown = 0.0
	_refresh_health_bar()
