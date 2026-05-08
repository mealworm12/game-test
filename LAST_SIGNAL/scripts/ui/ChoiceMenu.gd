class_name ChoiceMenu
extends Control

# ============================================================
# ChoiceMenu - Displays branching choices from dialog.
# Receives choice data from DialogManager.choice_requested.
# ============================================================

signal choice_made(choice_data: Dictionary)

@onready var panel: PanelContainer = $PanelContainer
@onready var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBox


var current_choices: Array = []
var is_choice_active: bool = false

func _ready() -> void:
	visible = false
	DialogManager.choice_requested.connect(_on_choice_requested)


func _on_choice_requested(choices: Array) -> void:
	current_choices = choices
	visible = true
	is_choice_active = true
	_build_buttons(choices)


func _build_buttons(choices: Array) -> void:
	# Clear existing buttons
	for child in vbox.get_children():
		child.queue_free()

	# Check prerequisites
	var available = _filter_by_prereqs(choices)

	for choice in available:
		var btn = Button.new()
		btn.text = choice.get("label", "?")
		btn.custom_minimum_size.y = 48
		btn.pressed.connect(_on_choice_button_pressed.bind(choice))
		vbox.add_child(btn)


func _filter_by_prereqs(choices: Array) -> Array:
	var available: Array = []
	for choice in choices:
		var prereqs = choice.get("requires", [])
		var ok = true
		for req_flag in prereqs:
			if not GameState.has_flag(req_flag):
				ok = false
				break
		if ok:
			available.append(choice)
	return available


func _on_choice_button_pressed(choice_data: Dictionary) -> void:
	if not is_choice_active:
		return
	is_choice_active = false
	visible = false
	choice_made.emit(choice_data)
	DialogManager.on_choice_made(choice_data)
