extends CharacterBody2D
class_name EnemyBase

signal attack_tick(damage: float)
signal defeated(enemy: EnemyBase)

const ANIM_IDLE: StringName = &"idle"
const ANIM_MOVE: StringName = &"move"
const ANIM_ATTACK: StringName = &"attack"
const ANIM_HIT: StringName = &"hit"
const ANIM_DEATH: StringName = &"death"

@export var move_speed := 110.0
@export var attack_interval := 0.9
@export var attack_damage := 8.0
@export var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export var fallback_visual_path: NodePath = ^"Visual"
@export var hit_flash_duration := 0.08
@export var death_fade_duration := 0.28

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_layer: Node2D = $DamageLayer
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path)
@onready var fallback_visual: CanvasItem = get_node_or_null(fallback_visual_path)

var attack_line_y := INF
var _is_attacking := false
var _attack_cooldown := 0.0
var _is_dead := false
var _current_anim_state: StringName = &""
var _pending_attack_line_y := INF
var _pending_attack_damage := 0.0
var _pending_max_health := 0.0
var _has_pending_config := false
var _base_modulate := Color.WHITE
var _hit_feedback_tween: Tween
var _death_tween: Tween
var _health_fill_style := StyleBoxFlat.new()
var _knockback_velocity := Vector2.ZERO
var _knockback_damping := 980.0
var _stun_time_left := 0.0
var _slow_time_left := 0.0
var _slow_factor := 1.0

func _ready() -> void:
	_base_modulate = modulate
	_health_fill_style.corner_radius_top_left = 2
	_health_fill_style.corner_radius_top_right = 2
	_health_fill_style.corner_radius_bottom_left = 2
	_health_fill_style.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("fill", _health_fill_style)
	health_component.died.connect(_on_health_died)
	if _has_pending_config:
		_apply_runtime_config(_pending_attack_line_y, _pending_attack_damage, _pending_max_health)
		_has_pending_config = false
	_refresh_health_bar()
	_update_visual_source()
	_set_enemy_animation_state(ANIM_IDLE, true)

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
		_set_enemy_animation_state(ANIM_IDLE)
		return

	if _knockback_velocity.length_squared() > 0.001:
		global_position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _knockback_damping * delta)

	if _stun_time_left > 0.0:
		_stun_time_left -= delta
	if _slow_time_left > 0.0:
		_slow_time_left -= delta
		if _slow_time_left <= 0.0:
			_slow_time_left = 0.0
			_slow_factor = 1.0

	if _stun_time_left > 0.0:
		_is_attacking = false
		velocity = Vector2.ZERO
		_set_enemy_animation_state(ANIM_HIT)
		move_and_slide()
		return

	if _is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		_set_enemy_animation_state(ANIM_ATTACK)
		_tick_attack(delta)
		return

	velocity = Vector2.DOWN * move_speed * _slow_factor
	move_and_slide()
	_set_enemy_animation_state(ANIM_MOVE)

	if global_position.y >= attack_line_y:
		_is_attacking = true
		velocity = Vector2.ZERO
		_attack_cooldown = 0.0
		_set_enemy_animation_state(ANIM_ATTACK, true)

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
	_play_hit_feedback()
	return _is_dead

func is_defeated() -> bool:
	return _is_dead

func _tick_attack(delta: float) -> void:
	_attack_cooldown -= delta * _slow_factor
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = maxf(0.1, attack_interval)
	_set_enemy_animation_state(ANIM_ATTACK, true)
	attack_tick.emit(attack_damage)

func _on_health_died() -> void:
	if _is_dead:
		return
	_is_dead = true
	_is_attacking = false
	velocity = Vector2.ZERO
	_set_enemy_animation_state(ANIM_DEATH, true)
	defeated.emit(self)
	_begin_death_sequence()

func _refresh_health_bar() -> void:
	health_bar.max_value = health_component.max_health
	health_bar.value = health_component.current_health
	var ratio := 0.0
	if health_component.max_health > 0.0:
		ratio = clampf(health_component.current_health / health_component.max_health, 0.0, 1.0)
	_health_fill_style.bg_color = _health_bar_color_for_ratio(ratio)
	health_bar.visible = health_component.current_health < health_component.max_health and not _is_dead

func _health_bar_color_for_ratio(ratio: float) -> Color:
	var t := clampf(ratio, 0.0, 1.0)
	if t >= 0.5:
		return Color(1.0, 1.0, 0.2).lerp(Color(0.2, 0.95, 0.3), (t - 0.5) * 2.0)
	return Color(1.0, 0.2, 0.2).lerp(Color(1.0, 1.0, 0.2), t * 2.0)

func _show_damage_popup(damage: float) -> void:
	var damage_label := Label.new()
	damage_label.text = "%.0f" % damage
	var base_font_size := 16
	var scale_bonus := 0.0
	if damage > 30.0:
		scale_bonus = clampf((damage - 30.0) / 90.0, 0.0, 1.0)
	var popup_scale := 1.0 + scale_bonus * 1.0
	var popup_font_size := int(round(float(base_font_size) * popup_scale))
	damage_label.add_theme_font_size_override("font_size", popup_font_size)
	damage_label.position = Vector2(-10.0 * popup_scale, -42.0 - 6.0 * scale_bonus)
	damage_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	damage_label.z_index = 10
	damage_layer.add_child(damage_label)

	var tween := create_tween()
	tween.tween_property(damage_label, "position", damage_label.position + Vector2(0.0, -14.0 - 8.0 * scale_bonus), 0.35)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.35)
	tween.finished.connect(damage_label.queue_free)

func _set_enemy_animation_state(next_state: StringName, force_restart: bool = false) -> void:
	if not force_restart and _current_anim_state == next_state:
		return
	_current_anim_state = next_state
	_play_enemy_animation(next_state, force_restart)

func _play_enemy_animation(anim_state: StringName, force_restart: bool = false) -> bool:
	if animated_sprite == null:
		return false
	var anim_name := String(anim_state)
	if not _has_sprite_animation(anim_state):
		return false
	if not force_restart and animated_sprite.animation == anim_state and animated_sprite.is_playing():
		return true
	_update_visual_source()
	animated_sprite.play(anim_name)
	return true

func _play_hit_feedback() -> void:
	if _is_dead:
		return
	if _play_enemy_animation(ANIM_HIT, true):
		return
	if _hit_feedback_tween != null:
		_hit_feedback_tween.kill()
	var restore_color := modulate
	modulate = Color(1.0, 1.0, 1.0, restore_color.a)
	_hit_feedback_tween = create_tween()
	_hit_feedback_tween.tween_property(self, "modulate", restore_color, hit_flash_duration)

func _has_sprite_animation(anim_state: StringName) -> bool:
	if animated_sprite == null:
		return false
	if animated_sprite.sprite_frames == null:
		return false
	var anim_name := String(anim_state)
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return false
	return animated_sprite.sprite_frames.get_frame_count(anim_name) > 0

func _has_any_sprite_animation() -> bool:
	if animated_sprite == null:
		return false
	if animated_sprite.sprite_frames == null:
		return false
	for animation_name in animated_sprite.sprite_frames.get_animation_names():
		if animated_sprite.sprite_frames.get_frame_count(animation_name) > 0:
			return true
	return false

func _update_visual_source() -> void:
	if fallback_visual == null:
		return
	fallback_visual.visible = not _has_any_sprite_animation()

func _estimated_sprite_animation_duration(anim_state: StringName) -> float:
	if not _has_sprite_animation(anim_state):
		return 0.0
	var anim_name := String(anim_state)
	var frame_count := animated_sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return 0.0
	var fps := animated_sprite.sprite_frames.get_animation_speed(anim_name)
	if fps <= 0.0:
		return 0.0
	var speed_scale := absf(animated_sprite.speed_scale)
	if speed_scale <= 0.0:
		return 0.0
	return float(frame_count) / (fps * speed_scale)

func _begin_death_sequence() -> void:
	health_bar.visible = false
	if _play_enemy_animation(ANIM_DEATH, true):
		var death_duration := _estimated_sprite_animation_duration(ANIM_DEATH)
		if death_duration <= 0.0:
			death_duration = death_fade_duration
		var timer := get_tree().create_timer(death_duration)
		timer.timeout.connect(func() -> void:
			if _is_dead and is_inside_tree():
				queue_free()
		)
		return

	if _death_tween != null:
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_property(self, "scale", scale * 0.74, death_fade_duration)
	_death_tween.parallel().tween_property(self, "modulate:a", 0.0, death_fade_duration)
	_death_tween.finished.connect(queue_free)

func _apply_runtime_config(next_attack_line_y: float, next_attack_damage: float, next_max_health: float) -> void:
	attack_line_y = next_attack_line_y
	attack_damage = next_attack_damage
	health_component.max_health = maxf(1.0, next_max_health)
	health_component.current_health = health_component.max_health
	_is_dead = false
	_is_attacking = false
	_attack_cooldown = 0.0
	_knockback_velocity = Vector2.ZERO
	_stun_time_left = 0.0
	_slow_time_left = 0.0
	_slow_factor = 1.0
	scale = Vector2.ONE
	modulate = _base_modulate
	_current_anim_state = &""
	_refresh_health_bar()
	_update_visual_source()
	_set_enemy_animation_state(ANIM_IDLE, true)

func apply_knockback(direction: Vector2, distance: float, duration: float = 0.16) -> void:
	if _is_dead:
		return
	var safe_duration := maxf(0.05, duration)
	var safe_distance := maxf(0.0, distance)
	if safe_distance <= 0.0:
		return
	var dir := direction
	if dir.length_squared() <= 0.0001:
		dir = Vector2.UP
	else:
		dir = dir.normalized()
	var speed := safe_distance / safe_duration
	_knockback_velocity += dir * speed
	_knockback_damping = maxf(220.0, speed / safe_duration)
	if global_position.y < attack_line_y:
		_is_attacking = false

func apply_stun(duration: float) -> void:
	if _is_dead:
		return
	var stun_duration := maxf(0.0, duration)
	if stun_duration <= 0.0:
		return
	_stun_time_left = maxf(_stun_time_left, stun_duration)
	_is_attacking = false

func apply_slow(multiplier: float, duration: float) -> void:
	if _is_dead:
		return
	var slow_duration := maxf(0.0, duration)
	if slow_duration <= 0.0:
		return
	var factor := clampf(multiplier, 0.15, 1.0)
	if _slow_time_left <= 0.0:
		_slow_factor = factor
	else:
		_slow_factor = minf(_slow_factor, factor)
	_slow_time_left = maxf(_slow_time_left, slow_duration)
