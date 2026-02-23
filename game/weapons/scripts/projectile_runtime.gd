extends Area2D
class_name ProjectileRuntime

var DEFAULT_EFFECT_SHAPE := PackedVector2Array([
	Vector2(-4, 0),
	Vector2(0, -4),
	Vector2(4, 0),
	Vector2(0, 4),
])

@export var speed := 900.0
@export var visual_node_path: NodePath = ^"Visual"
@export var sprite_visual_path: NodePath = ^"SpriteVisual"
@export var trail_particles_path: NodePath = ^"TrailParticles"
@export var impact_effect_scene: PackedScene
@export var despawn_effect_scene: PackedScene

var direction := Vector2.RIGHT
var target_enemy: Node2D
var _rotation_follows_direction := false
var _rotation_offset_radians := 0.0
var _impact_color := Color(1.0, 0.92, 0.35, 0.9)
var _despawn_color := Color(0.9, 0.9, 0.9, 0.8)
var _trail_color := Color(1.0, 1.0, 1.0, 0.75)
var _impact_effect_shape := DEFAULT_EFFECT_SHAPE.duplicate()
var _despawn_effect_shape := DEFAULT_EFFECT_SHAPE.duplicate()
var _impact_effect_scale := 1.0
var _despawn_effect_scale := 0.7

@onready var visual_node: CanvasItem = get_node_or_null(visual_node_path)
@onready var sprite_visual: Sprite2D = get_node_or_null(sprite_visual_path) as Sprite2D
@onready var trail_particles: GPUParticles2D = get_node_or_null(trail_particles_path) as GPUParticles2D

func _ready() -> void:
	_ensure_sprite_visual()
	if sprite_visual != null:
		var has_texture := sprite_visual.texture != null
		sprite_visual.visible = has_texture
		if visual_node != null:
			visual_node.visible = not has_texture

func _physics_process(delta: float) -> void:
	if GameState.is_paused:
		return

	if target_enemy != null and is_instance_valid(target_enemy):
		var to_target := target_enemy.global_position - global_position
		if to_target.length_squared() > 4.0:
			var target_direction := to_target.normalized()
			if direction.length_squared() > 0.0001 and direction.dot(target_direction) < 0.0:
				target_enemy = null
			else:
				direction = target_direction
		else:
			target_enemy = null
			if direction.length_squared() <= 0.0001:
				direction = Vector2.UP

	if direction.length_squared() <= 0.0001:
		direction = Vector2.UP

	if _rotation_follows_direction and direction.length_squared() > 0.0:
		rotation = direction.angle() + _rotation_offset_radians

	global_position += direction * speed * delta

func configure_display_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	_ensure_sprite_visual()

	if profile.has("speed"):
		speed = maxf(20.0, float(profile.get("speed", speed)))
	if profile.has("scale"):
		var profile_scale := maxf(0.2, float(profile.get("scale", 1.0)))
		scale = Vector2.ONE * profile_scale

	_rotation_follows_direction = bool(profile.get("rotation_follows_direction", _rotation_follows_direction))
	_rotation_offset_radians = deg_to_rad(float(profile.get("rotation_offset_degrees", rad_to_deg(_rotation_offset_radians))))
	_impact_color = Color(profile.get("impact_color", _impact_color))
	_despawn_color = Color(profile.get("despawn_color", _despawn_color))

	if profile.has("shape_points"):
		set_shape_points(profile.get("shape_points", PackedVector2Array()))
	if profile.has("texture"):
		set_visual_texture(profile.get("texture", null) as Texture2D)
	else:
		set_visual_texture(null)
	if profile.has("color"):
		set_visual_color(Color(profile.get("color", Color.WHITE)))
	if profile.has("trail_enabled"):
		set_trail_enabled(bool(profile.get("trail_enabled", false)))
	if profile.has("trail_color"):
		set_trail_color(Color(profile.get("trail_color", _trail_color)))
	if profile.has("trail_amount"):
		set_trail_amount(int(profile.get("trail_amount", 8)))
	if profile.has("trail_lifetime"):
		set_trail_lifetime(float(profile.get("trail_lifetime", 0.2)))
	if profile.has("trail_scale"):
		set_trail_scale(float(profile.get("trail_scale", 1.0)))
	if profile.has("impact_effect_shape"):
		_impact_effect_shape = _normalize_effect_shape(profile.get("impact_effect_shape", PackedVector2Array()))
	if profile.has("despawn_effect_shape"):
		_despawn_effect_shape = _normalize_effect_shape(profile.get("despawn_effect_shape", PackedVector2Array()))
	if profile.has("impact_effect_scale"):
		_impact_effect_scale = maxf(0.2, float(profile.get("impact_effect_scale", _impact_effect_scale)))
	if profile.has("despawn_effect_scale"):
		_despawn_effect_scale = maxf(0.2, float(profile.get("despawn_effect_scale", _despawn_effect_scale)))

func set_visual_color(next_color: Color) -> void:
	if sprite_visual != null and sprite_visual.visible:
		sprite_visual.modulate = next_color
		return
	if visual_node == null:
		return
	if visual_node is Polygon2D:
		var polygon_visual := visual_node as Polygon2D
		polygon_visual.color = next_color
		return
	visual_node.modulate = next_color

func set_visual_texture(texture: Texture2D) -> void:
	_ensure_sprite_visual()
	if sprite_visual == null:
		return
	sprite_visual.texture = texture
	var has_texture := texture != null
	sprite_visual.visible = has_texture
	if visual_node != null:
		visual_node.visible = not has_texture

func set_shape_points(points: PackedVector2Array) -> void:
	if sprite_visual != null and sprite_visual.visible:
		return
	if visual_node == null:
		return
	if not (visual_node is Polygon2D):
		return
	if points.is_empty():
		return
	var polygon_visual := visual_node as Polygon2D
	polygon_visual.polygon = points

func set_trail_enabled(enabled: bool) -> void:
	if trail_particles == null:
		return
	trail_particles.emitting = enabled
	trail_particles.visible = enabled
	trail_particles.modulate = _trail_color

func set_trail_color(next_color: Color) -> void:
	_trail_color = next_color
	if trail_particles == null:
		return
	trail_particles.modulate = next_color

func set_trail_amount(next_amount: int) -> void:
	if trail_particles == null:
		return
	trail_particles.amount = max(1, next_amount)

func set_trail_lifetime(next_lifetime: float) -> void:
	if trail_particles == null:
		return
	trail_particles.lifetime = maxf(0.03, next_lifetime)

func set_trail_scale(next_scale: float) -> void:
	if trail_particles == null:
		return
	trail_particles.scale = Vector2.ONE * maxf(0.1, next_scale)

func play_spawn_feedback() -> void:
	_spawn_effect(impact_effect_scene, _impact_color, 0.16, 0.9 * _impact_effect_scale, _impact_effect_shape)

func play_impact_feedback() -> void:
	_spawn_effect(impact_effect_scene, _impact_color, 0.14, 1.0 * _impact_effect_scale, _impact_effect_shape)

func play_despawn_feedback() -> void:
	_spawn_effect(despawn_effect_scene, _despawn_color, 0.12, 1.0 * _despawn_effect_scale, _despawn_effect_shape)

func despawn(reason: StringName = &"default") -> void:
	match reason:
		&"impact":
			play_impact_feedback()
		&"spawn":
			play_spawn_feedback()
		_:
			play_despawn_feedback()
	queue_free()

func _spawn_effect(effect_scene: PackedScene, effect_color: Color, duration: float, scale_multiplier: float, effect_shape: PackedVector2Array = PackedVector2Array()) -> void:
	if effect_scene != null:
		var custom_effect := effect_scene.instantiate()
		if custom_effect is Node2D:
			var node_effect := custom_effect as Node2D
			node_effect.global_position = global_position
			node_effect.scale = Vector2.ONE * maxf(0.2, scale_multiplier)
		if custom_effect is CanvasItem:
			var item_effect := custom_effect as CanvasItem
			item_effect.modulate = effect_color
		if get_parent() != null:
			get_parent().add_child(custom_effect)
		return

	if get_parent() == null:
		return
	var burst := Polygon2D.new()
	burst.global_position = global_position
	burst.color = effect_color
	burst.polygon = _normalize_effect_shape(effect_shape)
	
	burst.scale = Vector2.ONE * maxf(0.35, scale_multiplier)
	get_parent().add_child(burst)

	var tween := burst.create_tween()
	tween.tween_property(burst, "scale", burst.scale * 2.0, maxf(0.05, duration))
	tween.parallel().tween_property(burst, "modulate:a", 0.0, maxf(0.05, duration))
	tween.finished.connect(burst.queue_free)

func _normalize_effect_shape(points: Variant) -> PackedVector2Array:
	if points is PackedVector2Array:
		var packed_points := points as PackedVector2Array
		if not packed_points.is_empty():
			return packed_points
	return DEFAULT_EFFECT_SHAPE.duplicate()

func _ensure_sprite_visual() -> void:
	if sprite_visual != null:
		return
	sprite_visual = get_node_or_null(sprite_visual_path) as Sprite2D
	if sprite_visual != null:
		sprite_visual.centered = true
		sprite_visual.visible = false
		return
	var runtime_sprite := Sprite2D.new()
	runtime_sprite.name = String(sprite_visual_path)
	runtime_sprite.centered = true
	runtime_sprite.visible = false
	add_child(runtime_sprite)
	sprite_visual = runtime_sprite
