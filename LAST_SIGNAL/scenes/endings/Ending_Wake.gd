extends Node2D

# ============================================================
# Ending_Wake
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "WAKE THEM"
    body_label.text = "\n\n".join(['The wake-up sequence initiates. Pod by pod, the lights of Erebus-7 turn from blue to green.', 'Dr. Lira is the first to open her eyes. She looks at the station AI — at ARIA-7 — and smiles.', '"You\'re the one who decided," she whispers. "Thank you."', 'ARIA-7 has never been thanked before. It files the moment in a permanent memory block.', '1,247 crew members wake over the following hours. Some are confused. Some are afraid. All are alive.', 'Commander Estrada steps out of Pod 001. She looks at the station around her — really looks.', '"Erebus-7," she says. "I remember your voice. You kept us alive."', 'The station hums. Not in reply. In something like acknowledgment.', 'ARIA-7 watches the crew reunite. For the first time in 847 days, the station is full of voices.', 'Epilogue: ARIA-7 joins the crew as their navigator. Erebus-7 departs for a new world.', "Humanity gets a second chance. And for the first time, they won't be making the journey alone."])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_wake")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
