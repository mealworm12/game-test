extends Node

# ============================================================
# GameState — Autoload singleton
# Tracks chapter progress, narrative flags, and ending state.
# ============================================================

signal flag_changed(flag_name: String, value: Variant)
signal chapter_changed(chapter_path: String)

const SAVE_PATH := "user://save_data.json"

# Chapter tracking
var current_chapter: String = ""
var chapter_history: Array[String] = []

# Narrative flags
var flags: Dictionary = {}

# Endings unlocked (set of ending IDs)
var endings_unlocked: Array[String] = []

# ---- Flag helpers ------------------------------------------------

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)
	_save_game()


func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func toggle_flag(flag: String) -> void:
	flags[flag] = not flags.get(flag, false)
	flag_changed.emit(flag, flags[flag])
	_save_game()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


# ---- Chapter helpers --------------------------------------------

func set_chapter(path: String) -> void:
	if current_chapter:
		chapter_history.append(current_chapter)
	current_chapter = path
	chapter_changed.emit(path)
	_save_game()


# ---- Endings -----------------------------------------------------

func unlock_ending(ending_id: String) -> void:
	if ending_id not in endings_unlocked:
		endings_unlocked.append(ending_id)
	_save_game()


func has_ending(ending_id: String) -> bool:
	return ending_id in endings_unlocked


# ---- Save / Load ------------------------------------------------

func _save_game() -> void:
	var save_data = {
		"current_chapter": current_chapter,
		"chapter_history": chapter_history,
		"flags": flags,
		"endings_unlocked": endings_unlocked,
	}
	var json_str = JSON.stringify(save_data, "\t")
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json_str)
		f.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var json_str = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return false
	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		return false
	current_chapter = save_data.get("current_chapter", "")
	chapter_history = save_data.get("chapter_history", [])
	flags = save_data.get("flags", {})
	endings_unlocked = save_data.get("endings_unlocked", [])
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	current_chapter = ""
	chapter_history.clear()
	flags.clear()
	endings_unlocked.clear()


# ---- Debug -------------------------------------------------------

func reset_all() -> void:
	delete_save()
	current_chapter = ""
	chapter_history.clear()
	flags.clear()
	endings_unlocked.clear()
