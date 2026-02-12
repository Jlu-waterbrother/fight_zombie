extends Node

const SAVE_PATH := "user://save_game.cfg"
const SAVE_VERSION := 1

func save_data(data: Dictionary) -> int:
	var config := ConfigFile.new()
	var merged := _default_data()
	for section_name in data.keys():
		var section_key := String(section_name)
		var section_value : Variant = data[section_name]
		if section_value is Dictionary:
			merged[section_key] = (section_value as Dictionary).duplicate(true)

	merged["meta"]["version"] = SAVE_VERSION
	merged["meta"]["last_saved_unix"] = Time.get_unix_time_from_system()

	for section_name in merged.keys():
		var section_key := String(section_name)
		var section_value : Variant = merged[section_name]
		if section_value is Dictionary:
			var section_dict: Dictionary = section_value
			for key in section_dict.keys():
				config.set_value(section_key, String(key), section_dict[key])

	return config.save(SAVE_PATH)

func load_data() -> Dictionary:
	var merged := _default_data()
	var config := ConfigFile.new()
	var load_result := config.load(SAVE_PATH)
	if load_result != OK:
		return merged

	for section_name in merged.keys():
		var section_key := String(section_name)
		var section_default: Dictionary = merged[section_key]
		for key in section_default.keys():
			section_default[key] = config.get_value(section_key, String(key), section_default[key])

	return merged

func save_profile(profile: Dictionary) -> int:
	var data := load_data()
	data["profile"] = profile.duplicate(true)
	return save_data(data)

func load_profile() -> Dictionary:
	var data := load_data()
	var profile: Dictionary = data.get("profile", {})
	return profile.duplicate(true)

func save_progression(progression: Dictionary) -> int:
	var data := load_data()
	data["progression"] = progression.duplicate(true)
	return save_data(data)

func load_progression() -> Dictionary:
	var data := load_data()
	var progression: Dictionary = data.get("progression", {})
	return progression.duplicate(true)

func _default_data() -> Dictionary:
	return {
		"meta": {
			"version": SAVE_VERSION,
			"last_saved_unix": 0,
		},
		"profile": {
			"total_gold": 0,
		},
		"progression": {
			"last_run_level": 1,
			"last_run_wave": 1,
			"last_run_time_seconds": 0.0,
			"best_kills": 0,
			"best_level": 1,
			"best_wave": 1,
			"best_time_seconds": 999999.0,
		},
	}
