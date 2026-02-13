extends Node
class_name WaveDirector

signal wave_started(wave_index: int)

var current_wave := 0

func start_next_wave() -> void:
	current_wave += 1
	wave_started.emit(current_wave)
