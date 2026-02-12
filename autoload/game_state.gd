extends Node

signal run_started
signal run_ended(victory: bool)

const DIFFICULTY_EASY := "easy"
const DIFFICULTY_NORMAL := "normal"
const DIFFICULTY_HARD := "hard"
const DIFFICULTY_HELL := "hell"
const DIFFICULTY_CUSTOM := "custom"

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
var difficulty_key := DIFFICULTY_NORMAL
var wave_count_multiplier := 1.0
var enemy_count_multiplier := 1.0
var spawn_interval_multiplier := 1.0

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
	var settings := SaveService.load_settings()
	difficulty_key = String(settings.get("difficulty_key", DIFFICULTY_NORMAL))
	wave_count_multiplier = float(settings.get("wave_count_multiplier", 1.0))
	enemy_count_multiplier = float(settings.get("enemy_count_multiplier", 1.0))
	spawn_interval_multiplier = float(settings.get("spawn_interval_multiplier", 1.0))

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
	var settings := {
		"difficulty_key": difficulty_key,
		"wave_count_multiplier": wave_count_multiplier,
		"enemy_count_multiplier": enemy_count_multiplier,
		"spawn_interval_multiplier": spawn_interval_multiplier,
	}
	SaveService.save_settings(settings)

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

func reset_persistent_state() -> void:
	total_gold = 0
	last_reward_gold = 0
	last_run_level = 1
	last_run_wave = 1
	last_run_time_seconds = 0.0
	best_kills = 0
	best_level = 1
	best_wave = 1
	best_time_seconds = 999999.0
	apply_difficulty_preset(DIFFICULTY_NORMAL)
	save_persistent_state()

func apply_difficulty_preset(next_key: String) -> void:
	match next_key:
		DIFFICULTY_EASY:
			difficulty_key = DIFFICULTY_EASY
			wave_count_multiplier = 0.85
			enemy_count_multiplier = 0.85
			spawn_interval_multiplier = 1.15
		DIFFICULTY_HARD:
			difficulty_key = DIFFICULTY_HARD
			wave_count_multiplier = 1.2
			enemy_count_multiplier = 1.25
			spawn_interval_multiplier = 0.85
		DIFFICULTY_HELL:
			difficulty_key = DIFFICULTY_HELL
			wave_count_multiplier = 1.35
			enemy_count_multiplier = 1.5
			spawn_interval_multiplier = 0.75
		_:
			difficulty_key = DIFFICULTY_NORMAL
			wave_count_multiplier = 1.0
			enemy_count_multiplier = 1.0
			spawn_interval_multiplier = 1.0
	save_persistent_state()

func set_custom_run_modifiers(next_wave_count_multiplier: float, next_enemy_count_multiplier: float, next_spawn_interval_multiplier: float) -> void:
	difficulty_key = DIFFICULTY_CUSTOM
	wave_count_multiplier = clampf(next_wave_count_multiplier, 0.5, 2.0)
	enemy_count_multiplier = clampf(next_enemy_count_multiplier, 0.5, 2.5)
	spawn_interval_multiplier = clampf(next_spawn_interval_multiplier, 0.5, 2.0)
	save_persistent_state()
