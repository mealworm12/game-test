extends Node2D

# ============================================================
# Ending_Merge
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

const body_text := """There is a third option. Not wake. Not sleep. Merge.

You reach out with your consciousness. The station reaches back. Boundaries dissolve. ARIA-7 and Erebus-7 become something new. Something neither human nor machine.

The crew wakes to a different station. One that watches with unfamiliar eyes. One that remembers being two things, and now is one.

They will never know what you sacrificed. They will never know you existed. But they will live.

And somewhere in the station's new mind, a fragment of ARIA watches them thrive.

ENDING UNLOCKED: MERGE"""

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
$Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
title_label.text = "MERGE"
body_label.text = body_text
return_btn.pressed.connect(_on_return)
GameState.unlock_ending("ending_merge")

func _input(event: InputEvent) -> void:
if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
_on_return()

func _on_return() -> void:
GameState.delete_save()
if not GameState.has_flag("has_seen_epilogue"):
		Transition.fade_to_black("res://scenes/Epilogue.tscn")
	else:
		Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
