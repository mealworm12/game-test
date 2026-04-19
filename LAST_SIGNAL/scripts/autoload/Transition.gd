extends CanvasLayer

# ============================================================
# Transition — Autoload singleton
# Handles fade-to-black scene transitions.
# ============================================================

signal transition_complete

const COLOR := Color(0.0, 0.0, 0.0, 1.0)
const FADE_DURATION := 0.6

var _tween: Tween = null
var _is_transitioning: bool = false

var _fade_rect: ColorRect


func _ready() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.visible = false
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)


func fade_to_black(scene_path: String, skip_fade_out: bool = false) -> void:
	"""
	Fade to black, change scene, fade back in.
	"""
	if _is_transitioning:
		return
	_is_transitioning = true

	if not skip_fade_out:
		await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await _fade_in()
	_is_transitioning = false
	transition_complete.emit()


func _fade_out() -> void:
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.visible = true

	_tween = create_tween()
	_tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_CIRC)
	await _tween.finished


func _fade_in() -> void:
	_fade_rect.color = Color(0, 0, 0, 1.0)

	_tween = create_tween()
	_tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_CIRC)
	await _tween.finished
	_fade_rect.visible = false


func quick_fade(callback: Callable) -> void:
	"""
	Do a quick fade-out → callback → fade-in.
	Use for in-scene transitions.
	"""
	if _is_transitioning:
		return
	_is_transitioning = true

	await _fade_out()
	callback.call()
	await _fade_in()
	_is_transitioning = false
