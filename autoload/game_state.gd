extends Node

signal run_started
signal run_ended(victory: bool)

var is_paused := false
var current_wave := 0

func start_run() -> void:
    is_paused = false
    current_wave = 1
    run_started.emit()

func finish_run(victory: bool) -> void:
    run_ended.emit(victory)
