extends Node

# ============================================================
# SaveManager - Autoload singleton (v2)
# 6 named save slots + autosave slot, with timestamps/chapter/
# ending-progress metadata. Backward compatible: a legacy v1
# save file (user://save_data.json written by GameState) is
# migrated into the slot format on first load, never crashes.
# ============================================================

signal save_written(slot: int)
signal save_loaded(slot: int)

const SLOT_COUNT := 6
const AUTOSAVE_SLOT := -1
const SAVE_DIR := "user://saves/"
const SLOT_FILE_FMT := "user://saves/slot_%d.json"
const LEGACY_SAVE_PATH := "user://save_data.json"
const FORMAT_VERSION := 2

var _slot_cache: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ---- Public API -------------------------------------------------

func write_slot(slot: int, chapter_path: String, ending_progress: Array = []) -> bool:
	var payload := {
		"format_version": FORMAT_VERSION,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"unix_time": Time.get_unix_time_from_system(),
		"chapter": chapter_path,
		"flags": GameState.flags,
		"chapter_history": GameState.chapter_history,
		"current_chapter": chapter_path,
		"endings_unlocked": GameState.endings_unlocked,
		"ending_progress": ending_progress,
		# v2: codex unlocks round-trip with the save (Settings prefs live
		# separately in user://settings.json and are NOT part of slots).
		"codex_unlocked": Codex.unlocked.duplicate(),
	}
	return _write_json(_slot_path(slot), payload)


func load_slot(slot: int) -> Dictionary:
	var data = _read_json(_slot_path(slot))
	if data.is_empty():
		return {}
	if not apply_to_game_state(data):
		return {}
	save_loaded.emit(slot)
	return data


func get_slot_metadata(slot: int) -> Dictionary:
	var data = _read_json(_slot_path(slot))
	if data.is_empty():
		return {"exists": false}
	return {
		"exists": true,
		"timestamp": str(data.get("timestamp", "")),
		"chapter": str(data.get("chapter", data.get("current_chapter", ""))),
		"ending_progress": data.get("ending_progress", []),
		"format_version": int(data.get("format_version", 1)),
	}


func delete_slot(slot: int) -> void:
	var path = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_slot_cache.erase(slot)


func autosave() -> bool:
	return write_slot(AUTOSAVE_SLOT, GameState.current_chapter, GameState.endings_unlocked)


func list_slots() -> Array:
	var out: Array = []
	for i in range(SLOT_COUNT):
		out.append(get_slot_metadata(i))
	return out


# ---- Migration ---------------------------------------------------

func migrate_legacy_save() -> bool:
	"""Import a v1 save_data.json into the autosave slot. Idempotent."""
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return false
	var data = _read_json(LEGACY_SAVE_PATH)
	if data.is_empty():
		return false
	if FileAccess.file_exists(_slot_path(AUTOSAVE_SLOT)):
		return false  # already migrated; never overwrite
	data["format_version"] = FORMAT_VERSION
	if not data.has("timestamp"):
		data["timestamp"] = Time.get_datetime_string_from_system(false, true)
	var ok = _write_json(_slot_path(AUTOSAVE_SLOT), data)
	if ok:
		print("SaveManager: migrated v1 save into slot format")
	return ok


# ---- Apply to GameState ------------------------------------------

func apply_to_game_state(data: Dictionary) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.is_empty():
		return false
	GameState.flags = data.get("flags", {})
	var hist = data.get("chapter_history", [])
	GameState.chapter_history.clear()
	for h in hist:
		GameState.chapter_history.append(str(h))
	GameState.current_chapter = str(data.get("chapter", data.get("current_chapter", "")))
	var ends = data.get("endings_unlocked", [])
	GameState.endings_unlocked.clear()
	for e in ends:
		GameState.endings_unlocked.append(str(e))
	# v2: restore codex unlocks saved with the slot (union, never lose entries).
	var codex_unlocked = data.get("codex_unlocked", [])
	for c in codex_unlocked:
		if not Codex.is_unlocked(str(c)):
			Codex.unlocked.append(str(c))
	Codex._save_unlock_state()
	GameState.save_game_state()
	return true


# ---- IO helpers --------------------------------------------------

func _slot_path(slot: int) -> String:
	return SLOT_FILE_FMT % slot


func _write_json(path: String, payload: Dictionary) -> bool:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_warning("SaveManager: cannot open %s for writing" % path)
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		push_warning("SaveManager: corrupt save at %s (ignoring)" % path)
		return {}
	f.close()
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
