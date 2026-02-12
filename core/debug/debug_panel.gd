extends CanvasLayer
class_name DebugPanel

@export var visible_by_default := false

func _ready() -> void:
    visible = visible_by_default
