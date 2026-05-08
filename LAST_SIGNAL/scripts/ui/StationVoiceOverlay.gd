extends Control

# ============================================================
# StationVoiceOverlay - Real-time Erebus-7 commentary display.
# Appears on the right side of the screen during key moments.
# ============================================================

@onready var panel: PanelContainer = $PanelContainer
@onready var mood_label: Label = $PanelContainer/MarginContainer/VBox/MoodLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBox/TextLabel

var _is_visible: bool = false
var _auto_hide_timer: float = 0.0
var _auto_hide_duration: float = 7.0
var _fade_tween: Tween = null

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	_connect_signals()


func _connect_signals() -> void:
	StationVoice.station_spoke.connect(_on_station_spoke)
	StationVoice.mood_changed.connect(_on_mood_changed)


func _on_station_spoke(text: String, mood: int) -> void:
	_show_comment(text)


func _on_mood_changed(new_mood: int) -> void:
	_update_mood_label()


func _show_comment(text: String) -> void:
	text_label.text = text
	mood_label.text = StationVoice.get_mood_label()
	mood_label.modulate = StationVoice.get_mood_color()

	if not _is_visible:
		visible = true
		_is_visible = true
		_fade_in()

	_auto_hide_timer = _auto_hide_duration


func _update_mood_label() -> void:
	mood_label.text = StationVoice.get_mood_label()
	mood_label.modulate = StationVoice.get_mood_color()


func _process(delta: float) -> void:
	if not _is_visible:
		return
	_auto_hide_timer -= delta
	if _auto_hide_timer <= 0:
		_fade_out()


func _fade_in() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CIRC)


func _fade_out() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CIRC)
	_fade_tween.tween_callback(func(): _is_visible = false)
