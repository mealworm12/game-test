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

# ── Dialog sequencing ───────────────────────────────────────────────
# A chapter either starts its classic dialog immediately or defers it while it
# queues v2 scripts. Without this, an awaited _on_chapter_begin() called
# run_v2_script() a second into the classic dialog and replaced it; when the
# script ended it also looked like "chapter finished" and bounced to the menu.
var _classic_dialog_started: bool = false
var _dialog_deferred: bool = false
var _v2_queue: Array[String] = []

func _ready() -> void:
	_setup_overlays()
	_connect_signals()
	_start_chapter()

# Chapters with an awaited setup call this before their first await.
func defer_dialog() -> void:
	_dialog_deferred = true

# Called by a chapter when its deferred setup is done.
func _chapter_begin_complete() -> void:
	if _play_next_v2_script():
		return
	_start_classic_dialog()

func _start_classic_dialog() -> void:
	var data := get_dialog_data()
	if data.is_empty():
		return
	_classic_dialog_started = true
	DialogManager.start_dialog(data)

func _play_next_v2_script() -> bool:
	while not _v2_queue.is_empty():
		var script_name: String = _v2_queue.pop_front()
		var path := V2_CONTENT_DIR + script_name + ".dlg"
		if not FileAccess.file_exists(path):
			push_warning("BaseChapter: v2 script not found: %s" % path)
			continue
		DialogManager.run_script(FileAccess.get_file_as_string(path))
		return true
	return false

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
	# Connect through the scene instance: `ChoiceMenu` is a class_name, not an
	# autoload, and Godot 4.6 rejects signal access on the class itself
	# ("Cannot find member choice_made in base ChoiceMenu") — which prevented
	# every chapter script from parsing.
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
	# Deferred chapters start their own dialog from _chapter_begin_complete().
	if not _dialog_deferred and _v2_queue.is_empty():
		_start_classic_dialog()

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
	# Queue instead of playing immediately so several logs can be chained and
	# none of them clobber the chapter's classic dialog.
	var path := V2_CONTENT_DIR + script_name + ".dlg"
	if not FileAccess.file_exists(path):
		push_warning("BaseChapter: v2 script not found: %s" % path)
		return false
	_v2_queue.append(script_name)
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
	# A v2 script just ended: play the next queued script, then the classic
	# dialog. Only after the classic dialog does the chapter count as done.
	if _play_next_v2_script():
		return
	if not _classic_dialog_started:
		_start_classic_dialog()
		if _classic_dialog_started:
			return
	chapter_complete.emit()
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
