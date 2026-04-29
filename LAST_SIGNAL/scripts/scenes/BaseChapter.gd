extends Node2D

# ============================================================
# BaseChapter — Shared logic for all chapter scenes.
# Each chapter scene needs a Background TextureRect, UILayer CanvasLayer,
# DialogBox and ChoiceMenu instances inside UILayer.
# Override get_dialog_data() and optionally _on_choice_made().
# ============================================================

signal chapter_complete

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu
var _pause_menu: CanvasLayer = null
var _screen_effects: CanvasLayer = null

func _ready() -> void:
	_setup_overlays()
	_connect_signals()
	_start_chapter()

func _setup_overlays() -> void:
	_pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(_pause_menu)
	_screen_effects = preload("res://scenes/ui/ScreenEffects.tscn").instantiate()
	add_child(_screen_effects)

func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)
	ChoiceMenu.choice_made.connect(_on_choice_made)

func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)

func _background_load(path: String) -> void:
	if ResourceLoader.exists(path):
		background.texture = load(path)

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
