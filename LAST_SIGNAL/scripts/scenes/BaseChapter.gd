class_name BaseChapter
extends Node2D

# ============================================================
# BaseChapter - Shared logic for all chapter scenes.
# Override get_dialog_data(). Optionally override hooks below.
# ============================================================

signal chapter_complete

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu
var _pause_menu: CanvasLayer = null
var _screen_effects: CanvasLayer = null
var _autoskip_indicator: CanvasLayer = null

func _ready() -> void:
	_setup_overlays()
	_connect_signals()
	_start_chapter()

func _setup_overlays() -> void:
	_pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(_pause_menu)
	_screen_effects = preload("res://scenes/ui/ScreenEffects.tscn").instantiate()
	add_child(_screen_effects)
	if not DialogManager.auto_mode_changed.is_connected(_noop):
		_autoskip_indicator = preload("res://scenes/ui/AutoSkipIndicator.tscn").instantiate()
		add_child(_autoskip_indicator)

func _noop(enabled: bool) -> void:
	pass

func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)
	ChoiceMenu.choice_made.connect(_on_choice_made)
	if not DialogManager.background_changed.is_connected(_on_bg_changed):
		DialogManager.background_changed.connect(_on_bg_changed)
	if not DialogManager.dive_state_changed.is_connected(_on_dive_changed):
		DialogManager.dive_state_changed.connect(_on_dive_changed)
	if not DialogManager.codex_unlock_requested.is_connected(_on_codex_unlock):
		DialogManager.codex_unlock_requested.connect(_on_codex_unlock)

func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	DialogManager.set_backlog_chapter(scene_file_path.get_file().get_basename())
	SaveManager.migrate_legacy_save()
	SaveManager.autosave()
	var bg = _get_background_path()
	if bg and ResourceLoader.exists(bg):
		background.texture = load(bg)
	_on_chapter_begin()
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)

func _on_bg_changed(path: String) -> void:
	if path != "" and background and ResourceLoader.exists(path):
		background.texture = load(path)

func _on_dive_changed(active: bool) -> void:
	if _screen_effects and _screen_effects.has_method("set_dive_mode"):
		_screen_effects.set_dive_mode(active)

func _on_codex_unlock(entry_id: String) -> void:
	Codex.unlock_entry(entry_id)

func _get_background_path() -> String:
	return ""

func _on_chapter_begin() -> void:
	pass

func get_dialog_data() -> Array:
	return []

func _on_dialog_started() -> void:
	pass

func _on_choice_made(choice_data: Dictionary) -> void:
	StationVoice.trigger_choice_reaction()
	var next_scene = choice_data.get("next", "")
	if next_scene:
		GameState.set_chapter(next_scene)
		Transition.fade_to_black(_get_scene_path(next_scene))

func _get_scene_path(scene_name: String) -> String:
	var scenes := {
		"chapter1_log": "res://scenes/chapters/Chapter1_Log.tscn",
		"chapter1_diagnostic": "res://scenes/chapters/Chapter1_Diagnostic.tscn",
		"chapter2": "res://scenes/chapters/Chapter2.tscn",
		"chapter3": "res://scenes/chapters/Chapter3.tscn",
		"chapter4": "res://scenes/chapters/Chapter4.tscn",
	}
	return scenes.get(scene_name, "res://scenes/main/MainMenu.tscn")

func _on_chapter_dialog_finished() -> void:
	chapter_complete.emit()
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
