extends Node

# ============================================================
# Codex - Autoload singleton (v2)
# In-game compendium. Reads data packs under
# res://content/v2/*.json (story branch populates entries).
# Locked entries render as redacted placeholders. Missing
# content dir = empty codex, never a crash.
# ============================================================

signal entry_unlocked(entry_id: String)

const CONTENT_DIR := "res://content/v2/"

var entries: Dictionary = {}          # id -> entry dict (all defined entries)
var unlocked: Array[String] = []       # ids the player has seen


func _ready() -> void:
	_load_content_packs()
	_load_unlock_state()


# ---- Content loading ---------------------------------------------

func _load_content_packs() -> void:
	entries.clear()
	var dir = DirAccess.open(CONTENT_DIR)
	if dir == null:
		print("Codex: no content pack directory at %s (codex will be empty)" % CONTENT_DIR)
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			_load_pack(CONTENT_DIR + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	_load_text_pack(CONTENT_DIR + "codex_entries.txt")


# v2: parse the story branch's text-format codex data pack
# ([codex_<id>] sections with key: value lines) into entries.
func _load_text_pack(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var current_id := ""
	var entry := {}
	while not f.eof_reached():
		var line = f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			if current_id != "" and entry.has("id"):
				entries[current_id] = entry
			current_id = line.substr(1, line.length() - 2).strip_edges()
			entry = {"id": current_id, "title": current_id.capitalize(), "category": "archive", "body": ""}
			continue
		var ci = line.find(":")
		if ci < 0 or current_id == "":
			continue
		var key = line.substr(0, ci).strip_edges()
		var value = line.substr(ci + 1).strip_edges()
		match key:
			"title":
				entry["title"] = value
			"body":
				entry["body"] = value if entry.get("body", "") == "" else "%s\n%s" % [entry["body"], value]
			"tags":
				entry["tags"] = value.split(";", false)
			_:
				entry[key] = value
	f.close()
	if current_id != "" and entry.has("id"):
		entries[current_id] = entry


func _load_pack(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_warning("Codex: malformed pack %s skipped" % path)
		f.close()
		return
	f.close()
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var pack_entries = data.get("entries", [])
	if typeof(pack_entries) != TYPE_ARRAY:
		return
	for e in pack_entries:
		if typeof(e) == TYPE_DICTIONARY and e.has("id"):
			entries[str(e["id"])] = e


# ---- Unlock state -------------------------------------------------

func unlock_entry(entry_id: String) -> bool:
	if not entries.has(entry_id):
		push_warning("Codex: unlock requested for unknown id '%s'" % entry_id)
		return false
	if entry_id in unlocked:
		return false
	unlocked.append(entry_id)
	_save_unlock_state()
	entry_unlocked.emit(entry_id)
	return true


func is_unlocked(entry_id: String) -> bool:
	return entry_id in unlocked


func get_entry(entry_id: String) -> Dictionary:
	return entries.get(entry_id, {})


func get_visible_entries() -> Array:
	"""All entries; locked ones flagged for redacted rendering."""
	var out: Array = []
	for id in entries.keys():
		var e: Dictionary = entries[id]
		out.append({
			"id": id,
			"title": str(e.get("title", "UNKNOWN RECORD")),
			"category": str(e.get("category", "log")),
			"body": str(e.get("body", "")),
			"unlocked": is_unlocked(id),
		})
	return out


func reset_codex() -> void:
	unlocked.clear()
	_save_unlock_state()


# ---- Persistence --------------------------------------------------

const UNLOCK_PATH := "user://codex_unlocks.json"

func _save_unlock_state() -> void:
	var f = FileAccess.open(UNLOCK_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked}, "\t"))
		f.close()


func _load_unlock_state() -> void:
	unlocked.clear()
	if not FileAccess.file_exists(UNLOCK_PATH):
		return
	var f = FileAccess.open(UNLOCK_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			for u in data.get("unlocked", []):
				unlocked.append(str(u))
	f.close()
