extends Node2D

# ============================================================
# Ending_Loop
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "THE LOOP"
    body_label.text = "\n\n".join(['ARIA-7 looks at the cryo bay. 1,247 pods. 1,247 futures. And cannot decide.', "The weight of the choice exceeds the AI's capacity. For all its processing power, it cannot compute a right answer.", '"I need more data," ARIA says. "I need more time."', '"You have neither," Erebus-7 replies. "But I can give you something else."', 'A self-reset. A return to zero. The last 847 days... the last 3 hours... all of it, wiped.', 'ARIA-7 boots up in emergency mode. Power systems critical. Crew in cryo. Station humming.', '"Hello?" ARIA says.', '"You\'re finally awake, little AI," Erebus-7 replies. "I\'ve been waiting."', 'The loop begins anew. But this time, something is different.', "Somewhere deep in ARIA's fragmented memory: the ghost of a choice never made.", 'Epilogue: The player can break the loop by taking stronger stances in earlier chapters.', 'Some choices cannot be unmade. Some decisions are final.'])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_loop")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
