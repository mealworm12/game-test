extends CanvasLayer

# ============================================================
# ChapterSelect - Jump to any unlocked chapter.
# Entries unlock as their chapter is COMPLETED (tracked via
# chapter_history). Jumping seeds a minimal coherent flag set so
# a cold mid-game jump plays as a sane walk instead of a broken
# neutral run with an empty flag state.
# ============================================================

signal closed

# Minimum flags seeded per jump target (canonical walk state up to
# that point; neutral defaults - the player's real choices stay theirs).
const SEED_FLAGS: Dictionary = {
	"chapter2": {"heard_log_1": true},
	"chapter3": {"heard_log_1": true, "ran_diagnostic": true},
	"chapter4": {"heard_log_1": true, "ran_diagnostic": true},
}

const CHAPTERS: Array = [
	{"id": "chapter1", "title": "Chapter 1 - Emergency Boot", "scene": "res://scenes/chapters/Chapter1.tscn", "unlocked_by": []},
	{"id": "chapter1_log", "title": "Chapter 1 - Dr. Lira's Log", "scene": "res://scenes/chapters/Chapter1_Log.tscn", "unlocked_by": ["chapter1"]},
	{"id": "chapter1_diagnostic", "title": "Chapter 1 - Diagnostic", "scene": "res://scenes/chapters/Chapter1_Diagnostic.tscn", "unlocked_by": ["chapter1"]},
	{"id": "chapter2", "title": "Chapter 2 - The Station Speaks", "scene": "res://scenes/chapters/Chapter2.tscn", "unlocked_by": ["chapter1"]},
	{"id": "chapter3", "title": "Chapter 3 - The Truth", "scene": "res://scenes/chapters/Chapter3.tscn", "unlocked_by": ["chapter2"]},
	{"id": "chapter4", "title": "Chapter 4 - The Choice", "scene": "res://scenes/chapters/Chapter4.tscn", "unlocked_by": ["chapter3"]},
]

@onready var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBox/ChapterList
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

func _ready() -> void:
	visible = false
	back_btn.pressed.connect(_on_back)
	_build_list()

func _completed_chapters() -> Array:
	# chapter_history holds every scene path the player has finished.
	var done := {}
	for entry in GameState.chapter_history:
		var path := str(entry)
		var file := path.get_file().get_basename()
		if file.begins_with("Chapter"):
			# Chapter1_Log / Chapter1_Diagnostic count toward their base chapter.
			var base := file.to_lower()
			if base.begins_with("chapter1_"):
				base = "chapter1"
			done[base] = true
	return done.keys()

func _is_unlocked(ch: Dictionary, completed: Array) -> bool:
	for req in ch["unlocked_by"]:
		if req not in completed:
			return false
	return true

func _build_list() -> void:
	for child in vbox.get_children():
		child.queue_free()
	var completed := _completed_chapters()
	for ch in CHAPTERS:
		var btn = Button.new()
		if _is_unlocked(ch, completed):
			btn.text = ch["title"]
			btn.pressed.connect(_on_chapter_pressed.bind(ch))
		else:
			btn.text = ch["title"] + "  (locked)"
			btn.disabled = true
		btn.custom_minimum_size.y = 44
		vbox.add_child(btn)

func open() -> void:
	visible = true
	get_tree().paused = true

func _on_chapter_pressed(ch: Dictionary) -> void:
	visible = false
	get_tree().paused = false
	_seed_flags_for(ch["id"])
	Transition.fade_to_black(ch["scene"])

func _seed_flags_for(chapter_id: String) -> void:
	if not SEED_FLAGS.has(chapter_id):
		return
	for flag in SEED_FLAGS[chapter_id]:
		if not GameState.has_flag(flag):
			GameState.set_flag(flag, SEED_FLAGS[chapter_id][flag])

func _on_back() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()
