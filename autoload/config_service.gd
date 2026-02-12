extends Node

const DEFAULTS := {
    "starting_hp": 100.0,
    "starting_attack": 10.0,
    "base_move_speed": 280.0,
}

func get_default(key: String, fallback = null):
    return DEFAULTS.get(key, fallback)
