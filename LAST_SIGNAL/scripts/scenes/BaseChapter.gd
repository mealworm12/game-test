extends Node2D

# ============================================================
# BaseChapter — Shared logic for all chapter scenes.
# Extend this for each chapter. Override `get_dialog_data()`.
# ============================================================

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
	# Pause menu
	_pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(_pause_menu)

	# Screen effects
	_screen_effects = preload("res://scenes/ui/ScreenEffects.tscn").instantiate()
	add_child(_screen_effects)


func _connect_signals() -> void:
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)


func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)


func get_dialog_data() -> Array:
	"""Override in subclass to return the chapter's dialog array."""
	return []


func _on_chapter_dialog_finished() -> void:
	chapter_complete.emit()
	# Default: return to main menu via transition
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
