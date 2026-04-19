extends Node2D

# ============================================================
# Ending_Loop
# ============================================================

const BG_VOID := "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "THE LOOP"
    body_label.text = """ + body_text.replace('"', '\"') + """
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_loop")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
