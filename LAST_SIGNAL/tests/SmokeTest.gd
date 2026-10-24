extends Node

# ============================================================
# Headless smoke test for the chapter dialog flow.
#
# Run with:
#   godot --headless --path LAST_SIGNAL res://tests/SmokeTest.tscn
#
# It instantiates Chapter 4 with a neutral flag set. The chapter defers its
# classic dialog, queues the "ch4_prechoice" v2 script, then plays the classic
# finale dialog when that script ends. The old code started the classic dialog
# immediately and let the v2 script replace it a second later.
# ============================================================

var _failures: Array[String] = []


func _ready() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	print(("PASS  " if condition else "FAIL  ") + message)
	if not condition:
		_failures.append(message)


func _run() -> void:
	await get_tree().process_frame

	# ---- Pause menu must keep processing while the tree is paused ----
	var pause = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(pause)
	await get_tree().process_frame
	get_tree().paused = true
	_check(pause.process_mode == Node.PROCESS_MODE_ALWAYS, "pause menu uses PROCESS_MODE_ALWAYS")
	_check(pause.can_process(), "pause menu can process while the tree is paused")
	get_tree().paused = false
	pause.queue_free()
	await get_tree().process_frame

	# ---- Save rows must map to the slot they display ----
	var menu = load("res://scenes/ui/SaveLoadMenu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu.mode = "save"
	menu._rebuild()
	var first_slot = menu.slot_list.get_item_metadata(1)
	_check(typeof(first_slot) == TYPE_INT and first_slot == 0,
		"slot row 1 maps to slot 0 even when the autosave row is non-selectable")
	menu.queue_free()
	await get_tree().process_frame

	GameState.flags.clear()
	GameState.chapter_history.clear()
	GameState.endings_unlocked.clear()
	GameState.current_chapter = ""

	var chapter = load("res://scenes/chapters/Chapter4.tscn").instantiate()
	add_child(chapter)
	await get_tree().create_timer(2.0).timeout

	_check(DialogManager._script_running, "v2 pre-choice script is playing after the setup delay")
	_check(not chapter._classic_dialog_started,
		"classic finale dialog is deferred while the v2 script plays")

	var guard := 0
	while DialogManager._script_running and guard < 400:
		DialogManager.advance()
		await get_tree().process_frame
		guard += 1

	_check(guard < 400, "v2 script can be advanced to completion")
	_check(chapter._classic_dialog_started, "classic finale dialog starts after the v2 script ends")
	_check(DialogManager.current_dialog.size() > 0, "classic dialog has content")

	print("FAILURES: %d" % _failures.size())
	get_tree().quit(1 if _failures.size() > 0 else 0)
