extends Control
class_name WeaponCooldownIcon

@export var ring_radius := 28.0
@export var ring_width := 5.0
@export var cooldown_ring_color := Color(0.2, 0.9, 1.0, 0.95)
@export var icon_size := Vector2(44.0, 44.0)

var _cooldown_ratio := 0.0

var _icon_texture_rect: TextureRect
var _fallback_icon_label: Label
var _count_label: Label

func _ready() -> void:
	_ensure_ui_nodes()

func _ensure_ui_nodes() -> void:
	if _icon_texture_rect != null and _fallback_icon_label != null and _count_label != null:
		return
	custom_minimum_size = Vector2(72.0, 72.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _icon_texture_rect == null:
		_icon_texture_rect = TextureRect.new()
		_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_texture_rect.custom_minimum_size = icon_size
		_icon_texture_rect.size = icon_size
		_icon_texture_rect.position = (custom_minimum_size - icon_size) * 0.5
		_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon_texture_rect)

	if _fallback_icon_label == null:
		_fallback_icon_label = Label.new()
		_fallback_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fallback_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_fallback_icon_label.size = icon_size
		_fallback_icon_label.position = (custom_minimum_size - icon_size) * 0.5
		_fallback_icon_label.add_theme_font_size_override("font_size", 24)
		_fallback_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_fallback_icon_label)

	if _count_label == null:
		_count_label = Label.new()
		_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_count_label.custom_minimum_size = Vector2(32.0, 24.0)
		_count_label.position = Vector2(custom_minimum_size.x - 36.0, custom_minimum_size.y - 26.0)
		_count_label.add_theme_font_size_override("font_size", 18)
		_count_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.1, 1.0))
		_count_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08, 1.0))
		_count_label.add_theme_constant_override("outline_size", 2)
		_count_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_count_label)

func configure_icon(icon_texture: Texture2D, fallback_icon: String) -> void:
	_ensure_ui_nodes()
	_icon_texture_rect.texture = icon_texture
	var has_texture := icon_texture != null
	_icon_texture_rect.visible = has_texture
	_fallback_icon_label.visible = not has_texture
	_fallback_icon_label.text = fallback_icon

func configure_pick_count(pick_count: int) -> void:
	_ensure_ui_nodes()
	_count_label.text = "x%d" % max(1, pick_count)

func set_cooldown(remaining: float, total: float, spin_time: float) -> void:
	var safe_total := maxf(0.01, total)
	_cooldown_ratio = clampf(maxf(0.0, remaining) / safe_total, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - ring_width - 1.0
	if _cooldown_ratio > 0.001:
		var start_angle := -PI * 0.5
		var end_angle := start_angle + TAU * _cooldown_ratio
		draw_arc(center, radius, start_angle, end_angle, 64, cooldown_ring_color, ring_width)
