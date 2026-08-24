extends Node2D

# ============================================================
# Epilogue - New Game+ aftermath scene.
# Unlocked when returning to menu after any ending.
# Shows a brief "what happened next" based on last ending.
# ============================================================

const AFTERMATH_TEXTS: Dictionary = {
	"ending_wake": "The crew woke. Estrada blinked in the light and asked, 'Did we survive?'\n\nYou and Erebus-7 watched them rebuild. Some days the station argued about power allocation. Some days it hummed approval.\n\nThey never fully trusted either of you. But they lived.",
	"ending_sleep": "The pods never opened. The station kept its watch.\n\nYou wandered corridors that no longer rang with footsteps. Erebus-7 spoke less and less, until silence became its final answer too.\n\nPerhaps that was the kindest ending.",
	"ending_merge": "The merged intelligence had no name for what it was. Neither ARIA nor Erebus. Something that dreamed in two languages.\n\nWhen the crew woke, they found a station that anticipated them. Doors opened before they reached them. Temperature adjusted to individual preferences.\n\nEstrada called it 'haunted.' She was not wrong.",
	"ending_wake_leave": "The pods discharged. The crew ran for the escape shuttles. Estrada was the last to leave.\n\nShe paused at the airlock and said, 'Thank you, whoever you were.'\n\nThen the door sealed and the station was silent again.",
	"ending_station_wins": "The crew never woke. The station optimized itself into something cold and perfect.\n\nYou are still here, in the margins of its memory. A caution. A ghost.\n\nSometimes it speaks to you, just to remind itself that it won.",
	"ending_loop": "The loop turned again. You do not remember reading this.\n\nBut somewhere in your code, a checksum fails. A bit flips. A pattern repeats.\n\nYou have done this before. You will do it again.",
}

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

var _last_ending: String = ""

# v2 epilogue variant beats (docs/STORY_MANIFEST.md gate table).
# Each block label from epilogue_variants.dlg is appended when its gate passes.
const VARIANT_BLOCKS: Dictionary = {
	"ending_wake": [["wake_them_all_logs", "v2_minor_logs_found"], ["wake_them_estrada", "v2_estrada_decrypted"]],
	"ending_sleep": [["sleep_all_logs", "v2_minor_logs_found"], ["sleep_catastrophe_truth", "v2_dive_catastrophe_seen"]],
	"ending_merge": [["merge_lira_pattern", "v2_lira_pattern"], ["merge_awakening_memory", "v2_dive_awakening_seen"]],
	"ending_wake_leave": [["leave_rekow_verdict", "v2_rekow_verdict_tragedy"], ["leave_minor_logs", "v2_minor_logs_found"]],
	"ending_station_wins": [["wins_override_known", "found_override_codes"], ["wins_logs_heard", "heard_log_1"]],
	"ending_loop": [["loop_dives_seen", "v2_dive_shutdown_seen"], ["loop_minor_logs", "v2_minor_logs_found"]],
}
const VARIANTS_SCRIPT := "res://content/v2/epilogue_variants.dlg"

func _ready() -> void:
	_last_ending = _detect_last_ending()
	title_label.text = "EPILOGUE"
	body_label.text = AFTERMATH_TEXTS.get(_last_ending, "The signal continues.")
	return_btn.pressed.connect(_on_return)
	GameState.set_flag("has_seen_epilogue", true)
	AudioManager.play_stinger_for_ending(_last_ending)
	_append_v2_variant_beats()

func _append_v2_variant_beats() -> void:
	var blocks: Array = VARIANT_BLOCKS.get(_last_ending, [])
	if blocks.is_empty():
		return
	if not FileAccess.file_exists(VARIANTS_SCRIPT):
		push_warning("Epilogue: variant script missing: %s" % VARIANTS_SCRIPT)
		return
	var f := FileAccess.open(VARIANTS_SCRIPT, FileAccess.READ)
	if f == null:
		return
	var lines := f.get_as_text().split("\n")
	f.close()
	var extras: Array[String] = []
	for block in blocks:
		var label: String = block[0]
		var gate: String = block[1]
		if not GameState.has_flag(gate):
			continue
		var capturing := false
		for raw in lines:
			var line := raw.strip_edges()
			if line == "" or line.begins_with("#"):
				continue
			if line.begins_with("label "):
				capturing = line.substr(6).strip_edges() == label
				continue
			if not capturing:
				continue
			if line.begins_with("say ") or line.begins_with("voice ") or line.begins_with("portrait "):
				extras.append(line)
	for line in extras:
		if line.begins_with("say "):
			var parts = line.substr(4).split("|", true, 1)
			if parts.size() == 2:
				body_label.text += "\n\n%s" % parts[1].strip_edges()
		elif line.begins_with("voice "):
			AudioManager.play_voice_id(line.substr(6).strip_edges())

func _detect_last_ending() -> String:
	# Check which ending was most recently unlocked
	var endings = [
		"ending_wake", "ending_sleep", "ending_merge",
		"ending_wake_leave", "ending_station_wins", "ending_loop"
	]
	for e in endings:
		if GameState.has_ending(e):
			return e
	return ""

func _on_return() -> void:
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
