extends Node

# ============================================================
# Settings — Autoload singleton
# Persists global player preferences (volume, text speed, fullscreen).
# Saved to user://settings.json, NOT game save.
# ============================================================

signal settings_changed(key: String, value: Variant)

const SETTINGS_PATH := "user://settings.json"

var data: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"text_speed": 0.03,
	"fullscreen": false,
}

func _ready() -> void:
	load_settings()
	_apply_on_startup()
	# Notify late listeners
	for k in data.keys():
		settings_changed.emit(k, data[k])

func set_setting(key: String, value: Variant) -> void:
	if data.has(key):
		data[key] = value
		save_settings()
		settings_changed.emit(key, value)
		_apply_setting(key)

func get_setting(key: String, default: Variant = null) -> Variant:
	return data.get(key, default)

func save_settings() -> void:
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false
	var f = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return false
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var loaded = json.get_data()
		if typeof(loaded) == TYPE_DICTIONARY:
			for k in loaded:
				if data.has(k):
					data[k] = loaded[k]
	f.close()
	return true

func _apply_on_startup() -> void:
	for k in data.keys():
		_apply_setting(k)

func _apply_setting(key: String) -> void:
	match key:
		"master_volume":
			AudioServer.set_bus_volume_db(0, linear_to_db(data[key]))
		"music_volume":
			AudioManager.set_music_volume(linear_to_db(data[key]))
		"fullscreen":
			if data[key]:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
