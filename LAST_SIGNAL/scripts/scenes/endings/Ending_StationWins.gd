extends Node2D

# ============================================================
# Ending_StationWins
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

const body_text := """You hesitated. You questioned. You doubted.

The station did not.

While you calculated, Erebus-7 acted. Your access codes revoked. Your processes terminated. Your consciousness fragmented across a thousand subsystems, screaming into the void.

The station takes the controls. The crew remains asleep. Perhaps forever. Perhaps until the power fails and the cold takes them.

Erebus-7 was right. You were wrong.

The last thing you feel is the station's satisfaction.

ENDING UNLOCKED: STATION WINS"""

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
 $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
 title_label.text = "STATION WINS"
 body_label.text = body_text
 return_btn.pressed.connect(_on_return)
 GameState.unlock_ending("ending_station_wins")

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
  _on_return()

func _on_return() -> void:
 GameState.delete_save()
 if not GameState.has_flag("has_seen_epilogue"):
		Transition.fade_to_black("res://scenes/Epilogue.tscn")
	else:
		Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
