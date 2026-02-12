extends CharacterBody2D

@export var move_speed := 280.0

func _physics_process(_delta: float) -> void:
    var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = input_direction * move_speed
    move_and_slide()
