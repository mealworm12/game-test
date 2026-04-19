extends CanvasLayer

# ============================================================
# PauseMenu — Overlay shown when player presses Escape.
# ============================================================

signal resumed
signal restarted
signal returned_to_menu

@onready var panel: PanelContainer = $PanelContainer
@onready var resume_btn: Button = $PanelContainer.MarginContainer.VBox.ResumeBtn
@onready var restart_btn: Button = $PanelContainer.MarginContainer.VBox.RestartBtn
@onready var menu_btn: Button = $PanelContainer.MarginContainer.VBox.MenuBtn

func _ready() -> void:
	visible = false
	_connect_buttons()


func _connect_buttons() -> void:
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)


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
