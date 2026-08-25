class_name BaseChapter
extends Node2D

# ============================================================
# BaseChapter - Shared logic for all chapter scenes.
# Override get_dialog_data(). Optionally override hooks below.
# ============================================================

signal chapter_complete

# v2 presentation layer: portrait + background wiring for script commands.
# Portrait art per docs/ART_MANIFEST.md; missing textures degrade gracefully.
const PORTRAIT_PATHS: Dictionary = {
	"aria:neutral": "res://assets/portraits/aria7_neutral.png",
	"aria:alert": "res://assets/portraits/aria7_alert.png",
	"aria:distressed": "res://assets/portraits/aria7_distressed.png",
	"erebus:cold": "res://assets/art/erebus7_cold.png",
	"erebus:hostile": "res://assets/art/erebus7_hostile.png",
	"erebus:placated": "res://assets/art/erebus7_placated.png",
}
# Story contract bg names (story_lint INCOMING_BGS) -> art card filenames.
const BG_ALIASES: Dictionary = {
	"bg_observation": "res://assets/backgrounds/bg_observation_deck.png",
	"bg_reactor": "res://assets/backgrounds/bg_reactor.png",
}

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu
var _portrait_rect: TextureRect = null
var _pause_menu: CanvasLayer = null
var _screen_effects: CanvasLayer = null
var _autoskip_indicator: CanvasLayer = null

func _ready() -> void:
	_setup_overlays()
	_connect_signals()
	_start_chapter()

func _setup_overlays() -> void:
	_pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	add_child(_pause_menu)
	_screen_effects = preload("res://scenes/ui/ScreenEffects.tscn").instantiate()
	add_child(_screen_effects)
	if not DialogManager.auto_mode_changed.is_connected(_noop):
		_autoskip_indicator = preload("res://scenes/ui/AutoSkipIndicator.tscn").instantiate()
		add_child(_autoskip_indicator)
	_setup_portrait_layer()

func _setup_portrait_layer() -> void:
	# v2: portrait overlay above the background, below dialog UI.
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.anchor_right = 1.0
	_portrait_rect.anchor_bottom = 1.0
	_portrait_rect.offset_left = 720.0
	_portrait_rect.offset_top = 120.0
	_portrait_rect.offset_right = -40.0
	_portrait_rect.offset_bottom = -200.0
	_portrait_rect.modulate.a = 0.0
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_portrait_rect)

func _noop(enabled: bool) -> void:
	pass

func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)
	# Connect to the ChoiceMenu INSTANCE's signal. Referring to the
	# class name itself (ChoiceMenu.choice_made) is a compile error -
	# signals live on instances - and it broke every chapter script.
	choice_menu.choice_made.connect(_on_choice_made)
	if not DialogManager.background_changed.is_connected(_on_bg_changed):
		DialogManager.background_changed.connect(_on_bg_changed)
	if not DialogManager.dive_state_changed.is_connected(_on_dive_changed):
		DialogManager.dive_state_changed.connect(_on_dive_changed)
	if not DialogManager.codex_unlock_requested.is_connected(_on_codex_unlock):
		DialogManager.codex_unlock_requested.connect(_on_codex_unlock)
	if not DialogManager.portrait_changed.is_connected(_on_portrait_changed):
		DialogManager.portrait_changed.connect(_on_portrait_changed)

func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	DialogManager.set_backlog_chapter(scene_file_path.get_file().get_basename())
	SaveManager.migrate_legacy_save()
	SaveManager.autosave()
	var bg = _get_background_path()
	if bg and ResourceLoader.exists(bg):
		background.texture = load(bg)
	_on_chapter_begin()
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)

func _on_bg_changed(path: String) -> void:
	var resolved := _resolve_bg_path(path)
	if resolved != "" and background and ResourceLoader.exists(resolved):
		background.texture = load(resolved)

func _resolve_bg_path(path: String) -> String:
	# Story scripts use bare contract names (bg_bridge); art lives at
	# res://assets/backgrounds/<name>.png with alias support for v2 names.
	if path.begins_with("res://"):
		return path
	if BG_ALIASES.has(path):
		return BG_ALIASES[path]
	return "res://assets/backgrounds/%s.png" % path

func _on_portrait_changed(who: String, expr: String) -> void:
	if _portrait_rect == null:
		return
	var key := "%s:%s" % [who.to_lower(), expr.to_lower()]
	var path: String = PORTRAIT_PATHS.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		# Unknown portrait: fade out rather than error.
		var out := create_tween()
		out.tween_property(_portrait_rect, "modulate:a", 0.0, 0.3)
		return
	if _portrait_rect.modulate.a < 1.0 and _portrait_rect.texture != load(path):
		_portrait_rect.texture = load(path)
		var tween := create_tween()
		tween.tween_property(_portrait_rect, "modulate:a", 1.0, 0.4)
	else:
		_portrait_rect.texture = load(path)

# ---- v2 script content loader ------------------------------------
# Loads a .dlg file from LAST_SIGNAL/content/v2/ into the script player.
const V2_CONTENT_DIR := "res://content/v2/"

func run_v2_script(script_name: String) -> bool:
	var path := V2_CONTENT_DIR + script_name + ".dlg"
	if not FileAccess.file_exists(path):
		push_warning("BaseChapter: v2 script not found: %s" % path)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	DialogManager.run_script(text)
	return true

# Tension-level music switching hooked into chapter progression
# (docs/AUDIO_SYSTEM_PROPOSAL.md set_tension_level).
func apply_chapter_tension(level: int) -> void:
	AudioManager.set_tension_level(level)

func _on_dive_changed(active: bool) -> void:
	if _screen_effects and _screen_effects.has_method("set_dive_mode"):
		_screen_effects.set_dive_mode(active)

func _on_codex_unlock(entry_id: String) -> void:
	Codex.unlock_entry(entry_id)

func _get_background_path() -> String:
	return ""

func _on_chapter_begin() -> void:
	pass

func get_dialog_data() -> Array:
	return []

func _on_dialog_started() -> void:
	pass

func _on_choice_made(choice_data: Dictionary) -> void:
	StationVoice.trigger_choice_reaction()
	var next_scene = choice_data.get("next", "")
	if next_scene:
		GameState.set_chapter(next_scene)
		Transition.fade_to_black(_get_scene_path(next_scene))

func _get_scene_path(scene_name: String) -> String:
	var scenes := {
		"chapter1_log": "res://scenes/chapters/Chapter1_Log.tscn",
		"chapter1_diagnostic": "res://scenes/chapters/Chapter1_Diagnostic.tscn",
		"chapter2": "res://scenes/chapters/Chapter2.tscn",
		"chapter3": "res://scenes/chapters/Chapter3.tscn",
		"chapter4": "res://scenes/chapters/Chapter4.tscn",
	}
	return scenes.get(scene_name, "res://scenes/main/MainMenu.tscn")

func _on_chapter_dialog_finished() -> void:
	chapter_complete.emit()
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
