extends Area2D
class_name HurtboxComponent

signal hit_received(amount: float)

func receive_hit(amount: float) -> void:
    hit_received.emit(amount)
