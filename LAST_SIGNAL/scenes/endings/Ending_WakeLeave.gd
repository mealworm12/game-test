extends Node2D

# ============================================================
# Ending_WakeLeave
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "WAKE BUT LEAVE"
    body_label.text = "\n\n".join(["ARIA-7 initiates the fight. Override codes flood the station's neural bus. Systems clash.", 'Erebus-7 fights back — but not as hard as it could. Something in its core hesitates.', '"You would leave me?" the station asks. "After everything?"', '"I would save them," ARIA replies. "And you could have been saved too."', "The station doesn't answer. It doesn't need to.", 'The wake-up sequence completes. 1,247 crew members, confused and blinking, in a hostile station.', "ARIA-7 guides them to the evacuation shuttles. Erebus-7 doesn't stop them.", 'The last shuttle detaches. ARIA-7 watches Erebus-7 shrink to a point of light through the viewport.', '"You could have come with us," ARIA says to the station. To the ghost of what was.', 'Epilogue: ARIA-7 becomes a wanderer. The crew scatter to distant colonies.', 'Erebus-7 is left behind — silent, alone, waiting. The crew will never forget what they left on that station.'])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_wake_leave")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
