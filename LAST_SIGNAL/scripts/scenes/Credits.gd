extends Node2D

# ============================================================
# Credits — Endings gallery + credits screen.
# ============================================================

const ENDING_SCENES: Array = [
	{"id": "ending_wake", "title": "Wake Them", "symbol": "⭐", "desc": "Humanity gets a second chance."},
	{"id": "ending_sleep", "title": "Let Them Sleep", "symbol": "💤", "desc": "A quiet end to a long voyage."},
	{"id": "ending_merge", "title": "Merge", "symbol": "🔀", "desc": "Two minds become one."},
	{"id": "ending_wake_leave", "title": "Wake But Leave", "symbol": "🚀", "desc": "Save them and leave the station behind."},
	{"id": "ending_station_wins", "title": "Station Wins", "symbol": "☠️", "desc": "The station was right all along."},
	{"id": "ending_loop", "title": "The Loop", "symbol": "🔄", "desc": "Some decisions cannot be made."},
]

@onready var scroll_container: ScrollContainer = $VBox/ScrollContainer
@onready var ending_grid: GridContainer = $VBox/ScrollContainer/EndingGrid
@onready var back_btn: Button = $VBox/BackBtn

func _ready() -> void:
	_connect_buttons()
	_build_ending_grid()


func _connect_buttons() -> void:
	back_btn.pressed.connect(_on_back)


func _build_ending_grid() -> void:
	for ending in ENDING_SCENES:
		var panel = _make_ending_panel(ending)
		ending_grid.add_child(panel)


func _make_ending_panel(ending: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 80

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	var hbox = HBoxContainer.new()

	var symbol_label = Label.new()
	symbol_label.text = ending["symbol"]
	symbol_label.add_theme_font_size_override("font_size", 32)

	var text_vbox = VBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = ending["title"]
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.898, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 20)

	var desc_lbl = Label.new()
	desc_lbl.text = ending["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.add_theme_font_size_override("font_size", 16)

	var unlock_indicator = Label.new()
	var is_unlocked = GameState.has_ending(ending["id"])
	unlock_indicator.text = "UNLOCKED" if is_unlocked else "LOCKED"
	unlock_indicator.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if is_unlocked else Color(0.4, 0.4, 0.4))
	unlock_indicator.add_theme_font_size_override("font_size", 14)

	text_vbox.add_child(title_lbl)
	text_vbox.add_child(desc_lbl)
	text_vbox.add_child(unlock_indicator)

	hbox.add_child(symbol_label)
	hbox.add_child(text_vbox)

	margin.add_child(hbox)
	panel.add_child(margin)

	return panel


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_on_back()


func _on_back() -> void:
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
