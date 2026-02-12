extends CharacterBody2D
class_name PlayerController

const BOTTOM_MARGIN := 72.0

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
    var viewport_size := get_viewport_rect().size
    global_position = Vector2(viewport_size.x * 0.5, viewport_size.y - BOTTOM_MARGIN)

func _physics_process(_delta: float) -> void:
    velocity = Vector2.ZERO
    move_and_slide()

func apply_contact_damage(amount: float) -> void:
    health_component.apply_damage(amount)

func health_ratio() -> float:
    if health_component.max_health <= 0.0:
        return 0.0
    return health_component.current_health / health_component.max_health
