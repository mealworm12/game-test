extends Node

# ============================================================
# Story/save regression suite (headless).
#
#   godot --headless --path LAST_SIGNAL res://tests/StoryTest.tscn
#
# Covers what SmokeTest does not: every ending branch is reachable, every
# ending has a scene, chapter dialogue exists, save slots round-trip, and
# New Game+ keeps meta-progression while resetting run position.
# ============================================================

var _failures: Array[String] = []

const ENDINGS := [
	"ending_wake", "ending_sleep", "ending_merge",
	"ending_wake_leave", "ending_station_wins", "ending_loop",
]


func _ready() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	print(("PASS  " if condition else "FAIL  ") + message)
	if not condition:
		_failures.append(message)


func _reset() -> void:
	GameState.flags.clear()
	GameState.chapter_history.clear()
	GameState.endings_unlocked.clear()
	GameState.current_chapter = ""
	Codex.reset_codex()


func _set_flags(flags: Dictionary) -> void:
	for key in flags:
		GameState.flags[key] = flags[key]


func _ending_ids(choice: Dictionary) -> Array:
	var ids := []
	for c in choice.get("choices", []):
		ids.append(str(c.get("ending", "")))
	return ids


func _test_endings() -> void:
	var chapter4 = load("res://scenes/chapters/Chapter4.tscn").instantiate()

	for ending in ENDINGS:
		_check(ResourceLoader.exists(chapter4._get_ending_path(ending)),
			"%s has a scene" % ending)

	var scenarios := [
		{"name": "allied + legacy protected", "flags": {"station_allied": true, "crew_legacy_protected": true}, "expect": "ending_merge"},
		{"name": "allied + knows truth", "flags": {"station_allied": true, "station_knows_truth": true}, "expect": "ending_merge"},
		{"name": "hostile without codes", "flags": {"station_hostile": true}, "expect": "ending_station_wins"},
		{"name": "hostile with codes", "flags": {"station_hostile": true, "found_override_codes": true}, "expect": "ending_wake_leave"},
		{"name": "neutral", "flags": {}, "expect": "ending_loop"},
	]
	for scenario in scenarios:
		_reset()
		_set_flags(scenario["flags"])
		var ids = _ending_ids(chapter4._build_final_choice())
		_check(scenario["expect"] in ids,
			"%s offers %s (got %s)" % [scenario["name"], scenario["expect"], ids])

	# The "wake" ending must always be reachable.
	_reset()
	_check("ending_wake" in _ending_ids(chapter4._build_final_choice()),
		"a wake ending is always available")

	chapter4.free()


func _test_chapters_have_dialog() -> void:
	for name in ["Chapter1", "Chapter1_Log", "Chapter1_Diagnostic", "Chapter2", "Chapter3", "Chapter4"]:
		var chapter = load("res://scenes/chapters/%s.tscn" % name).instantiate()
		var data = chapter.get_dialog_data()
		_check(data.size() > 0, "%s has dialogue" % name)
		chapter.free()


func _test_save_roundtrip() -> void:
	_reset()
	_set_flags({"heard_log_1": true, "station_allied": true})
	GameState.endings_unlocked.append("ending_wake")
	GameState.chapter_history.append("res://scenes/chapters/Chapter1.tscn")

	var wrote = SaveManager.write_slot(5, "res://scenes/chapters/Chapter3.tscn")
	_check(wrote, "slot 5 writes")

	GameState.flags.clear()
	GameState.chapter_history.clear()
	GameState.endings_unlocked.clear()
	GameState.current_chapter = ""

	var data = SaveManager.load_slot(5)
	_check(not data.is_empty(), "slot 5 loads")
	_check(GameState.flags.get("heard_log_1", false) == true, "flags survive the round-trip")
	_check("ending_wake" in GameState.endings_unlocked, "endings survive the round-trip")
	_check(GameState.current_chapter.ends_with("Chapter3.tscn"), "chapter survives the round-trip")
	SaveManager.delete_slot(5)


func _test_new_game_plus() -> void:
	_reset()
	_set_flags({"station_allied": true, "heard_log_1": true})
	GameState.endings_unlocked.append("ending_merge")
	GameState.chapter_history.append("res://scenes/chapters/Chapter4.tscn")

	GameState.start_new_game_plus()
	_check(GameState.current_chapter == "", "NG+ resets run position")
	_check(GameState.flags.get("station_allied", false) == true, "NG+ keeps discoveries")
	_check("ending_merge" in GameState.endings_unlocked, "NG+ keeps the endings gallery")
	_check(not GameState.chapter_history.is_empty(), "NG+ keeps chapter unlocks")


func _run() -> void:
	await get_tree().process_frame
	_test_endings()
	_test_chapters_have_dialog()
	_test_save_roundtrip()
	_test_new_game_plus()
	print("FAILURES: %d" % _failures.size())
	get_tree().quit(1 if _failures.size() > 0 else 0)
