extends CanvasLayer

# ============================================================
# PauseMenu - Overlay shown when player presses Escape.
# ============================================================

signal resumed
signal restarted
signal returned_to_menu
signal quit_requested

@onready var panel: PanelContainer = $PanelContainer
@onready var resume_btn: Button = $PanelContainer.MarginContainer.VBox.ResumeBtn
@onready var restart_btn: Button = $PanelContainer.MarginContainer.VBox.RestartBtn
@onready var menu_btn: Button = $PanelContainer.MarginContainer.VBox.MenuBtn
@onready var settings_btn: Button = $PanelContainer.MarginContainer.VBox.SettingsBtn
@onready var backlog_btn: Button = $PanelContainer.MarginContainer.VBox.BacklogBtn
@onready var save_btn: Button = $PanelContainer.MarginContainer.VBox.SaveBtn
@onready var load_btn: Button = $PanelContainer.MarginContainer.VBox.LoadBtn
@onready var codex_btn: Button = $PanelContainer.MarginContainer.VBox.CodexBtn
@onready var quit_btn: Button = $PanelContainer.MarginContainer.VBox.QuitBtn

var _settings_menu: CanvasLayer = null
var _backlog_panel: CanvasLayer = null
var _save_load_menu: CanvasLayer = null
var _codex_ui: CanvasLayer = null

func _ready() -> void:
	visible = false
	_connect_buttons()


func _connect_buttons() -> void:
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	settings_btn.pressed.connect(_on_settings)
	backlog_btn.pressed.connect(_on_backlog)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	codex_btn.pressed.connect(_on_codex)
	quit_btn.pressed.connect(_on_quit)


func _on_backlog() -> void:
	if not _backlog_panel:
		_backlog_panel = preload("res://scenes/ui/BacklogPanel.tscn").instantiate()
		add_child(_backlog_panel)
	get_tree().paused = true
	visible = false
	_backlog_panel.open()


func _on_save() -> void:
	if not _save_load_menu:
		_save_load_menu = preload("res://scenes/ui/SaveLoadMenu.tscn").instantiate()
		add_child(_save_load_menu)
		_save_load_menu.closed.connect(func(): get_tree().paused = false)
	get_tree().paused = false
	visible = false
	_save_load_menu.open("save")
	get_tree().paused = true


func _on_load() -> void:
	if not _save_load_menu:
		_save_load_menu = preload("res://scenes/ui/SaveLoadMenu.tscn").instantiate()
		add_child(_save_load_menu)
	get_tree().paused = false
	visible = false
	_save_load_menu.open("load")


func _on_codex() -> void:
	if not _codex_ui:
		_codex_ui = preload("res://scenes/ui/CodexUI.tscn").instantiate()
		add_child(_codex_ui)
		_codex_ui.closed.connect(func(): get_tree().paused = false)
	get_tree().paused = false
	visible = false
	_codex_ui.open()
	get_tree().paused = true

func _on_settings() -> void:
	get_tree().paused = false
	visible = false
	if not _settings_menu:
		_settings_menu = preload("res://scenes/ui/SettingsMenu.tscn").instantiate()
		add_child(_settings_menu)
		_settings_menu.closed.connect(func(): get_tree().paused = false)
	_settings_menu.open()
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
			pause()


func pause() -> void:
	get_tree().paused = true
	visible = true


func resume() -> void:
	get_tree().paused = false
	visible = false
	resumed.emit()


func _on_resume() -> void:
	resume()


func _on_restart() -> void:
	get_tree().paused = false
	visible = false
	restarted.emit()
	GameState.delete_save()
	Transition.fade_to_black("res://scenes/chapters/Chapter1.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	visible = false
	returned_to_menu.emit()
	GameState.delete_save()
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")

func _on_quit() -> void:
	get_tree().paused = false
	visible = false
	quit_requested.emit()
	get_tree().quit()
