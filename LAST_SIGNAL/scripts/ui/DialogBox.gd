class_name DialogBox
extends Control

# ============================================================
# DialogBox — Displays dialog with typewriter effect.
# Connect to DialogManager signals for automatic updates.
# ============================================================

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBox/SpeakerLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBox/TextLabel
@onready var continue_indicator: Label = $ContinueIndicator

var is_active: bool = false

func _ready() -> void:
	visible = false
	continue_indicator.visible = false
	_connect_signals()


func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_dialog_finished)
	DialogManager.line_displayed.connect(_on_line_displayed)
	DialogManager.typewriter_tick.connect(_on_typewriter_tick)
	DialogManager.choice_requested.connect(_on_choice_requested)


func _on_dialog_started() -> void:
	visible = true
	is_active = true
	continue_indicator.visible = false


func _on_dialog_finished() -> void:
	visible = false
	is_active = false


func _on_line_displayed(line_index: int) -> void:
	_update_display()


func _on_typewriter_tick(visible_chars: int, total_chars: int) -> void:
	text_label.text = DialogManager.get_current_text()
	# Show continue indicator only when fully typed
	if visible_chars >= total_chars:
		continue_indicator.visible = true
	else:
		continue_indicator.visible = false


func _on_choice_requested(choices: Array) -> void:
	# Let ChoiceMenu handle this; we just hide during choices
	continue_indicator.visible = false


func _update_display() -> void:
	speaker_label.text = DialogManager.get_speaker_name()
	speaker_label.modulate = DialogManager.get_speaker_color()
	text_label.text = DialogManager.get_current_text()


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			DialogManager.skip_or_advance()
		elif event is InputEventKey and event.pressed:
			DialogManager.skip_or_advance()
