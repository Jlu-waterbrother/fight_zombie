extends Node

signal run_started
signal run_ended(victory: bool)

var is_paused := false
var current_wave := 0
var is_run_active := false

func start_run() -> void:
	is_paused = false
	current_wave = 1
	is_run_active = true
	run_started.emit()

func finish_run(victory: bool) -> void:
	is_run_active = false
	is_paused = true
	run_ended.emit(victory)

func reset_run_state() -> void:
	is_paused = false
	current_wave = 0
	is_run_active = false
