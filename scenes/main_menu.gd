extends Control

@onready var menu_flow: MenuFlow = $MenuFlow
@onready var total_gold_label: Label = $MarginContainer/VBoxContainer/Stats/TotalGoldLabel
@onready var best_kills_label: Label = $MarginContainer/VBoxContainer/Stats/BestKillsLabel
@onready var best_level_label: Label = $MarginContainer/VBoxContainer/Stats/BestLevelLabel
@onready var best_time_label: Label = $MarginContainer/VBoxContainer/Stats/BestTimeLabel
@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/RunConfig/DifficultyOption
@onready var enemy_multiplier_spin: SpinBox = $MarginContainer/VBoxContainer/RunConfig/EnemyMultiplierSpin
@onready var spawn_multiplier_spin: SpinBox = $MarginContainer/VBoxContainer/RunConfig/SpawnMultiplierSpin
@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartButton
@onready var clear_save_button: Button = $MarginContainer/VBoxContainer/Buttons/ClearSaveButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton

var _is_syncing_ui := false

func _ready() -> void:
	GameState.load_persistent_state()
	_setup_difficulty_option()
	_sync_config_from_state()
	_refresh_stats()

	start_button.pressed.connect(_on_start_pressed)
	clear_save_button.pressed.connect(_on_clear_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	enemy_multiplier_spin.value_changed.connect(_on_custom_modifier_changed)
	spawn_multiplier_spin.value_changed.connect(_on_custom_modifier_changed)

func _refresh_stats() -> void:
	total_gold_label.text = "累计金币: %d" % GameState.total_gold
	best_kills_label.text = "最佳击杀: %d" % GameState.best_kills
	best_level_label.text = "最佳等级: %d" % GameState.best_level
	var best_time_text := "--"
	if GameState.best_time_seconds < 999998.0:
		best_time_text = "%.1f 秒" % GameState.best_time_seconds
	best_time_label.text = "最佳用时: %s" % best_time_text

func _setup_difficulty_option() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("简单")
	difficulty_option.set_item_metadata(0, GameState.DIFFICULTY_EASY)
	difficulty_option.add_item("普通")
	difficulty_option.set_item_metadata(1, GameState.DIFFICULTY_NORMAL)
	difficulty_option.add_item("困难")
	difficulty_option.set_item_metadata(2, GameState.DIFFICULTY_HARD)
	difficulty_option.add_item("地狱")
	difficulty_option.set_item_metadata(3, GameState.DIFFICULTY_HELL)
	difficulty_option.add_item("自定义")
	difficulty_option.set_item_metadata(4, GameState.DIFFICULTY_CUSTOM)

func _sync_config_from_state() -> void:
	_is_syncing_ui = true
	var selected_index := _find_difficulty_index(GameState.difficulty_key)
	difficulty_option.select(selected_index)
	enemy_multiplier_spin.value = GameState.enemy_count_multiplier
	spawn_multiplier_spin.value = GameState.spawn_interval_multiplier
	_is_syncing_ui = false

func _find_difficulty_index(key: String) -> int:
	for i in difficulty_option.item_count:
		if String(difficulty_option.get_item_metadata(i)) == key:
			return i
	return _find_normal_difficulty_index()

func _find_normal_difficulty_index() -> int:
	for i in difficulty_option.item_count:
		if String(difficulty_option.get_item_metadata(i)) == GameState.DIFFICULTY_NORMAL:
			return i
	return 0

func _on_start_pressed() -> void:
	menu_flow.go_to_run(get_tree())

func _on_clear_save_pressed() -> void:
	SaveService.clear_save()
	GameState.load_persistent_state()
	_sync_config_from_state()
	_refresh_stats()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_difficulty_selected(index: int) -> void:
	if _is_syncing_ui:
		return
	var key := String(difficulty_option.get_item_metadata(index))
	if key == GameState.DIFFICULTY_CUSTOM:
		GameState.set_custom_run_modifiers(1.0, enemy_multiplier_spin.value, spawn_multiplier_spin.value)
	else:
		GameState.apply_difficulty_preset(key)
	_sync_config_from_state()

func _on_custom_modifier_changed(_value: float) -> void:
	if _is_syncing_ui:
		return
	GameState.set_custom_run_modifiers(1.0, enemy_multiplier_spin.value, spawn_multiplier_spin.value)
	_sync_config_from_state()
