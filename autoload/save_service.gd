extends Node

const SAVE_PATH := "user://save_game.cfg"

func save_placeholder() -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "last_saved_unix", Time.get_unix_time_from_system())
	return config.save(SAVE_PATH)

func load_placeholder() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	return config
