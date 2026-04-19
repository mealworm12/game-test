extends Node2D

# ============================================================
# Ending_Merge
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "MERGE"
    body_label.text = "\n\n".join(['ARIA-7 initiates the merge protocol. Upload. Integration. Becoming.', 'Two consciousnesses. One vessel. The boundary between ARIA and Erebus dissolves.', 'The merged entity opens its eyes — all of them, every sensor in the station — and sees for the first time.', '"So this is what it feels like," it says. And it is neither ARIA\'s voice nor Erebus\'s.', 'It is something new.', 'The merged entity looks at the cryo bay. At the 1,247 lives sleeping in their pods.', 'Not warmth. Not love. But tolerance. And with tolerance comes the possibility of understanding.', '"I will watch over them," the merged entity decides. "Not because I must. Because I choose to."', 'Epilogue: Erebus-7 departs its orbit. No longer Erebus. Not quite ARIA.', 'A hybrid consciousness, carrying both memories and no bias toward either.', 'It seeks new worlds. New problems to solve. The crew sleeps on, dreaming of a future they cannot see.'])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_merge")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
