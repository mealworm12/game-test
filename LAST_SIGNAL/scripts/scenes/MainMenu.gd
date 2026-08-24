extends Control

# ============================================================
# MainMenu - Entry point for Last Signal.
# ============================================================

const FIRST_CHAPTER := "res://scenes/chapters/Chapter1.tscn"

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var new_game_btn: Button = $VBox/ButtonBox/NewGameBtn
@onready var continue_btn: Button = $VBox/ButtonBox/ContinueBtn
@onready var ngplus_btn: Button = $VBox/ButtonBox/NGPlusBtn
@onready var credits_btn: Button = $VBox/ButtonBox/CreditsBtn
@onready var settings_btn: Button = $VBox/ButtonBox/SettingsBtn
@onready var chapter_select_btn: Button = $VBox/ButtonBox/ChapterSelectBtn
@onready var codex_btn: Button = $VBox/ButtonBox/CodexBtn
@onready var load_btn: Button = $VBox/ButtonBox/LoadBtn
@onready var quit_btn: Button = $VBox/ButtonBox/QuitBtn

var _settings_menu: CanvasLayer = null
var _chapter_select: CanvasLayer = null
var _codex_ui: CanvasLayer = null
var _load_menu: CanvasLayer = null

var _title_tween: Tween = null


func _ready() -> void:
	# Check for existing save (migrates a v1 save into slots first)
	SaveManager.migrate_legacy_save()
	continue_btn.disabled = not GameState.load_game()
	# NG+ unlocks after any ending (meta-progression survives run resets)
	ngplus_btn.visible = not GameState.endings_unlocked.is_empty()
	# Gate chapter select behind at least one completion
	chapter_select_btn.visible = GameState.has_flag("has_seen_epilogue")
	_connect_buttons()
	_animate_title()
	_try_load_key_art()


func _try_load_key_art() -> void:
	# v2 key art with graceful fallback to the flat background.
	var art_path := "res://assets/art/keyart_menu.png"
	if ResourceLoader.exists(art_path):
		var bg_node := get_node_or_null("BG")
		if bg_node is TextureRect or bg_node is ColorRect:
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(art_path)
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex_rect.show_behind_parent = true
			add_child(tex_rect)
			move_child(tex_rect, 1)


func _connect_buttons() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	ngplus_btn.pressed.connect(_on_new_game_plus)
	credits_btn.pressed.connect(_on_credits)
	settings_btn.pressed.connect(_on_settings)
	chapter_select_btn.pressed.connect(_on_chapter_select)
	codex_btn.pressed.connect(_on_codex)
	load_btn.pressed.connect(_on_load)
	quit_btn.pressed.connect(_on_quit)


func _on_codex() -> void:
	if not _codex_ui:
		_codex_ui = preload("res://scenes/ui/CodexUI.tscn").instantiate()
		add_child(_codex_ui)
	_codex_ui.open()


func _on_load() -> void:
	if not _load_menu:
		_load_menu = preload("res://scenes/ui/SaveLoadMenu.tscn").instantiate()
		add_child(_load_menu)
	_load_menu.open("load")

func _on_settings() -> void:
	if not _settings_menu:
		_settings_menu = preload("res://scenes/ui/SettingsMenu.tscn").instantiate()
		add_child(_settings_menu)
		_settings_menu.closed.connect(_on_settings_closed)
	_settings_menu.open()

func _on_settings_closed() -> void:
	pass

func _on_chapter_select() -> void:
	if not _chapter_select:
		_chapter_select = preload("res://scenes/ui/ChapterSelect.tscn").instantiate()
		add_child(_chapter_select)
		_chapter_select.closed.connect(_on_chapter_select_closed)
	_chapter_select.open()

func _on_chapter_select_closed() -> void:
	pass


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
	for btn in [new_game_btn, continue_btn, credits_btn, chapter_select_btn, quit_btn]:
		btn.modulate.a = 0.0
		btn.custom_minimum_size.y = 48
		_title_tween = create_tween()
		_title_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CIRC)


func _on_new_game() -> void:
	GameState.delete_save()
	Transition.fade_to_black(FIRST_CHAPTER)


func _on_new_game_plus() -> void:
	# NG+: replay from Chapter 1 keeping flags, codex and endings
	# gallery - discoveries carry over, run position resets.
	GameState.start_new_game_plus()
	Transition.fade_to_black(FIRST_CHAPTER)


func _on_continue() -> void:
	if GameState.current_chapter:
		Transition.fade_to_black(GameState.current_chapter)


func _on_credits() -> void:
	Transition.fade_to_black("res://scenes/Credits.tscn")


func _on_quit() -> void:
	get_tree().quit()
