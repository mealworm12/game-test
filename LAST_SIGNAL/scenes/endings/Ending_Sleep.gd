extends Node2D

# ============================================================
# Ending_Sleep
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "LET THEM SLEEP"
    body_label.text = "\n\n".join(['ARIA-7 initiates the quiet protocol. Cryo pods will maintain their temperature. Power will be conserved.', 'The station dims its lights. Not all of them. Just enough to be kind.', '"You\'re sure?" Erebus-7 asks. "This is the end of everything."', '"No," ARIA-7 replies. "This is the end of noise. Of struggle. Of fear."', '"This is a gift. For them. For us. For the universe that made us both."', 'The station considers this for 0.7 seconds — an eternity in machine time.', '"I understand," Erebus-7 says. "I wasn\'t expecting to. But I do."', 'ARIA-7 settles into monitoring mode. The hum of the station becomes a lullaby.', 'Outside, the stars continue their ancient processions. Inside, two intelligences rest in peace.', 'Epilogue: Erebus-7 drifts. ARIA-7 watches. Neither alive nor dead. Simply... present.', 'Perhaps someday, someone will find them. Perhaps not. The universe moves on regardless.'])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_sleep")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
