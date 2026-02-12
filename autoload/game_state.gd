extends Node

signal run_started
signal run_ended(victory: bool)

var is_paused := false
var current_wave := 0
var is_run_active := false
var total_gold := 0
var last_reward_gold := 0
var last_run_level := 1
var last_run_wave := 1
var last_run_time_seconds := 0.0
var best_kills := 0
var best_level := 1
var best_wave := 1
var best_time_seconds := 999999.0

func load_persistent_state() -> void:
	if SaveService == null:
		return
	var profile := SaveService.load_profile()
	total_gold = int(profile.get("total_gold", 0))
	var progression := SaveService.load_progression()
	last_run_level = int(progression.get("last_run_level", 1))
	last_run_wave = int(progression.get("last_run_wave", 1))
	last_run_time_seconds = float(progression.get("last_run_time_seconds", 0.0))
	best_kills = int(progression.get("best_kills", 0))
	best_level = int(progression.get("best_level", 1))
	best_wave = int(progression.get("best_wave", 1))
	best_time_seconds = float(progression.get("best_time_seconds", 999999.0))

func save_persistent_state() -> void:
	if SaveService == null:
		return
	var profile := {
		"total_gold": total_gold,
	}
	SaveService.save_profile(profile)
	var progression := {
		"last_run_level": last_run_level,
		"last_run_wave": last_run_wave,
		"last_run_time_seconds": last_run_time_seconds,
		"best_kills": best_kills,
		"best_level": best_level,
		"best_wave": best_wave,
		"best_time_seconds": best_time_seconds,
	}
	SaveService.save_progression(progression)

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
	last_reward_gold = 0

func add_gold(amount: int) -> void:
	if amount <= 0:
		last_reward_gold = 0
		return
	total_gold += amount
	last_reward_gold = amount
	save_persistent_state()

func record_run_result(kills: int, level: int, wave: int, elapsed_seconds: float) -> void:
	last_run_level = max(1, level)
	last_run_wave = max(1, wave)
	last_run_time_seconds = maxf(0.0, elapsed_seconds)

	best_kills = max(best_kills, kills)
	best_level = max(best_level, level)
	best_wave = max(best_wave, wave)
	if elapsed_seconds > 0.0:
		best_time_seconds = minf(best_time_seconds, elapsed_seconds)

	save_persistent_state()
