extends CanvasLayer

# ============================================================
# ChapterSelect — Jump to any unlocked chapter.
# ============================================================

signal closed

const CHAPTERS: Array = [
	{"id": "chapter1", "title": "Chapter 1 — Emergency Boot", "scene": "res://scenes/chapters/Chapter1.tscn"},
	{"id": "chapter1_log", "title": "Chapter 1 — Dr. Lira's Log", "scene": "res://scenes/chapters/Chapter1_Log.tscn"},
	{"id": "chapter1_diagnostic", "title": "Chapter 1 — Diagnostic", "scene": "res://scenes/chapters/Chapter1_Diagnostic.tscn"},
	{"id": "chapter2", "title": "Chapter 2 — The Station Speaks", "scene": "res://scenes/chapters/Chapter2.tscn"},
	{"id": "chapter3", "title": "Chapter 3 — The Truth", "scene": "res://scenes/chapters/Chapter3.tscn"},
	{"id": "chapter4", "title": "Chapter 4 — The Choice", "scene": "res://scenes/chapters/Chapter4.tscn"},
]

@onready var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBox/ChapterList
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

func _ready() -> void:
	visible = false
	back_btn.pressed.connect(_on_back)
	_build_list()

func _build_list() -> void:
	for child in vbox.get_children():
		child.queue_free()
	for ch in CHAPTERS:
		var btn = Button.new()
		btn.text = ch["title"]
		btn.custom_minimum_size.y = 44
		btn.pressed.connect(_on_chapter_pressed.bind(ch["scene"]))
		vbox.add_child(btn)

func open() -> void:
	visible = true
	get_tree().paused = true

func _on_chapter_pressed(scene_path: String) -> void:
	visible = false
	get_tree().paused = false
	Transition.fade_to_black(scene_path)

func _on_back() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()
