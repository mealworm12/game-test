extends Node2D

# ============================================================
# BaseChapter — Shared logic for all chapter scenes.
# Extend this for each chapter. Override `get_dialog_data()`.
# ============================================================

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu
@onready var station_voice: Label = $UILayer/StationVoiceOverlay/StationLabel

signal chapter_complete

func _ready() -> void:
	_connect_signals()
	_start_chapter()


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
	# Default: return to main menu. Override to chain chapters.
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
