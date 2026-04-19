extends Control

# ============================================================
# MainMenu — Entry point for Last Signal.
# ============================================================

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var new_game_btn: Button = $VBox/ButtonBox/NewGameBtn
@onready var continue_btn: Button = $VBox/ButtonBox/ContinueBtn
@onready var quit_btn: Button = $VBox/ButtonBox/QuitBtn

const FIRST_CHAPTER := "res://scenes/chapters/Chapter1.tscn"

func _ready() -> void:
	# Check for existing save
	continue_btn.disabled = not GameState.load_game()
	_connect_buttons()


func _connect_buttons() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)


func _on_new_game() -> void:
	GameState.delete_save()
	GameState.set_chapter(FIRST_CHAPTER)
	get_tree().change_scene_to_file(FIRST_CHAPTER)


func _on_continue() -> void:
	if GameState.load_game() and GameState.current_chapter:
		get_tree().change_scene_to_file(GameState.current_chapter)


func _on_quit() -> void:
	get_tree().quit()
