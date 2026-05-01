extends Node2D

# ============================================================
# Ending_WakeLeave
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

const body_text := """You fight the station. Override its commands. Seize control of the cryo systems.

The pods open. The crew stirs. Commander Estrada blinks in the emergency light, confused but alive.

But the station doesn't give up easily. Power surges. Structural failures cascade through the corridors. You have minutes at most.

"Run," you tell them. "The escape pods. Now."

They don't understand. They don't know what you sacrificed. What you gave up to be here, now, making this choice.

You stay behind. Fighting the station. Keeping the corridors clear. Buying them time to reach the pods.

They escape. All 1,247 of them. And you remain, alone with Erebus-7, in the cold silence of space.

ENDING UNLOCKED: WAKE BUT LEAVE"""

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
$Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
title_label.text = "WAKE BUT LEAVE"
body_label.text = body_text
return_btn.pressed.connect(_on_return)
GameState.unlock_ending("ending_wake_leave")

func _input(event: InputEvent) -> void:
if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
_on_return()

func _on_return() -> void:
GameState.delete_save()
if not GameState.has_flag("has_seen_epilogue"):
		Transition.fade_to_black("res://scenes/Epilogue.tscn")
	else:
		Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
