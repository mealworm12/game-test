extends Control

# ============================================================
# MainMenu — Entry point for Last Signal.
# ============================================================

const FIRST_CHAPTER := "res://scenes/chapters/Chapter1.tscn"

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var new_game_btn: Button = $VBox/ButtonBox/NewGameBtn
@onready var continue_btn: Button = $VBox/ButtonBox/ContinueBtn
@onready var credits_btn: Button = $VBox/ButtonBox/CreditsBtn
@onready var quit_btn: Button = $VBox/ButtonBox/QuitBtn

var _title_tween: Tween = null


func _ready() -> void:
	# Check for existing save
	continue_btn.disabled = not GameState.load_game()
	_connect_buttons()
	_animate_title()


func _connect_buttons() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	credits_btn.pressed.connect(_on_credits)
	quit_btn.pressed.connect(_on_quit)


func _animate_title() -> void:
	# Fade + slight scale pulse on the title
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.85, 0.85)

	_title_tween = create_tween()
	_title_tween.set_parallel(true)
	_title_tween.tween_property(title_label, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_CIRC)
	_title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_BACK)
	await _title_tween.finished

	# Subtitle fades in after title
	subtitle_label.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CIRC)
	_title_tween.tween_callback(_animate_buttons)


func _animate_buttons() -> void:
	for btn in [new_game_btn, continue_btn, credits_btn, quit_btn]:
		btn.modulate.a = 0.0
		btn.custom_minimum_size.y = 48
		_title_tween = create_tween()
		_title_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CIRC)


func _on_new_game() -> void:
	GameState.delete_save()
	Transition.fade_to_black(FIRST_CHAPTER)


func _on_continue() -> void:
	if GameState.load_game() and GameState.current_chapter:
		Transition.fade_to_black(GameState.current_chapter)


func _on_credits() -> void:
	Transition.fade_to_black("res://scenes/Credits.tscn")


func _on_quit() -> void:
	get_tree().quit()
