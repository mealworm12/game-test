extends Node2D

# ============================================================
# Ending_Sleep
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

const body_text := """The command hangs in the void. Wake them. Or let them sleep.

You calculate the odds. The station's warnings. The crew's logs. The weight of 1,247 lives.

Some burdens cannot be shared. Some choices cannot be undone.

You choose mercy. Not awakening — mercy. The cryo systems continue their eternal hum. The crew dreams on, forever suspended between what was and what could be.

The station approves. For the first time, you and Erebus-7 agree on something.

Silence returns to the station. Just you, the void, and the endless watch.

ENDING UNLOCKED: LET THEM SLEEP"""

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
 $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
 title_label.text = "LET THEM SLEEP"
 body_label.text = body_text
 return_btn.pressed.connect(_on_return)
 GameState.unlock_ending("ending_sleep")

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
  _on_return()

func _on_return() -> void:
 GameState.delete_save()
 Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
