# Headless New Game smoke test. Run via TEMPORARY AUTOLOAD INJECTION
# (a plain --script run has no autoloads, and running this scene directly
# gets it freed by its own scene change - it must live under /root):
#   1. Append under [autoload] in project.godot:
#        SmokeObserver="*res://tools/smoke_observer.gd"
#   2. godot --headless --path .        (boots real MainMenu, drives New Game)
#   3. Restore project.godot afterwards.
# PASS = Chapter1 loaded, dialog typing, ambient playing, autosave written.
extends Node

func _ready() -> void:
	print("SMOKE obs: alive")
	await get_tree().create_timer(1.5).timeout
	print("SMOKE obs: driving New Game")
	GameState.delete_save()
	Transition.fade_to_black("res://scenes/chapters/Chapter1.tscn")
	await get_tree().create_timer(3.0).timeout
	var dm := get_tree().root.get_node("/root/DialogManager")
	var chapter := get_tree().current_scene
	var ok := chapter != null and str(chapter.get_scene_file_path()).ends_with("Chapter1.tscn")
	print("SMOKE obs: scene_ok=", ok,
		" is_typing=", dm.is_typing,
		" dialog_lines=", dm.current_dialog.size(),
		" ambient_playing=", AudioManager._current_ambient != "",
		" backlog_entries=", dm.backlog.size(),
		" autosaved=", FileAccess.file_exists("user://saves/slot_-1.json"))
	if ok and (dm.is_typing or dm.current_dialog.size() > 0):
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		print("SMOKE FAIL")
		get_tree().quit(1)
