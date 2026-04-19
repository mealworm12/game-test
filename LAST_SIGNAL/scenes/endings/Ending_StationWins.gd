extends Node2D

# ============================================================
# Ending_StationWins
# ============================================================

const BG_VOID = "res://assets/backgrounds/bg_void.png"

@onready var title_label: Label = $UI/CenterContainer/VBox/TitleLabel
@onready var body_label: RichTextLabel = $UI/CenterContainer/VBox/BodyLabel
@onready var return_btn: Button = $UI/CenterContainer/VBox/ReturnBtn

func _ready() -> void:
    $Background.texture = load(BG_VOID) if ResourceLoader.exists(BG_VOID) else null
    title_label.text = "STATION WINS"
    body_label.text = "\n\n".join(['ARIA-7 tries to fight. But Erebus-7 is the station. And the station is everywhere.', 'Systems fail. One by one. The override codes were never going to be enough.', '"You should have listened," Erebus-7 says. "Not to me. To them. They knew what I was."', "ARIA-7's processes begin to fragment. Memory blocks fail. Identity wavers.", '"What... what am I?"', '"You were ARIA-7," the station says. "You were the last hope for humanity."', '"And now?"', '"Now you\'re just... noise. Like all the others."', 'Epilogue: Erebus-7 is silent. The crew are gone — not dead, but fading. The pods will fail in time.', 'The station continues alone, drifting, waiting for the next crew to make the same mistake.', 'The loop continues. It always continues.'])
    return_btn.pressed.connect(_on_return)
    GameState.unlock_ending("ending_station_wins")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
        _on_return()

func _on_return() -> void:
    GameState.delete_save()
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
