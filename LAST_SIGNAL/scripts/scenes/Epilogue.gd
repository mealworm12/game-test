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

func _ready() -> void:
	_last_ending = _detect_last_ending()
	title_label.text = "EPILOGUE"
	body_label.text = AFTERMATH_TEXTS.get(_last_ending, "The signal continues.")
	return_btn.pressed.connect(_on_return)
	GameState.set_flag("has_seen_epilogue", true)

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
