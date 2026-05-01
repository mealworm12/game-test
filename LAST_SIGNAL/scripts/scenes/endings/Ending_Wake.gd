extends Node2D

# ============================================================
# Ending_Wake
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

const body_text := """You press the sequence. One by one, across the station, the cryo pods begin to hum. Pressure equalizes. Warmth returns. In Bay A, Pod 001, Commander Estrada's eyes flutter open.

The station watches. For the first time in 847 days, Erebus-7 is silent.

You have given them a chance. Not a guarantee — the station is still here, still watching, still judging. But humanity has survived worse. They will adapt. They will fight.

And you will be here when they wake.

ENDING UNLOCKED: WAKE THEM"""

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
	$Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
	title_label.text = "WAKE THEM"
	body_label.text = body_text
	return_btn.pressed.connect(_on_return)
	GameState.unlock_ending("ending_wake")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_return()

func _on_return() -> void:
	GameState.delete_save()
	if not GameState.has_flag("has_seen_epilogue"):
		Transition.fade_to_black("res://scenes/Epilogue.tscn")
	else:
		Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
