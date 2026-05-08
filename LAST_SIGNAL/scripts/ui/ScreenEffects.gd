extends CanvasLayer

# ============================================================
# ScreenEffects - Post-processing overlay for atmosphere.
# CRT scanlines + vignette + occasional flicker.
# Add as child of root scene to enable.
# ============================================================

@onready var scanlines: ColorRect = $Effects/Scanlines
@onready var vignette: ColorRect = $Effects/Vignette

var _flicker_timer: float = 0.0
var _flicker_duration: float = 0.0
var _is_flickering: bool = false


func _ready() -> void:
	_scanlines_setup()
	_vignette_setup()


func _scanlines_setup() -> void:
	scanlines.visible = true


func _vignette_setup() -> void:
	vignette.visible = true


func _process(delta: float) -> void:
	_do_flicker(delta)


func _do_flicker(delta: float) -> void:
	if not _is_flickering:
		# Random chance to start a flicker
		if randf() < 0.002:  # ~0.2% chance per frame
			_start_flicker()
		return

	_flicker_timer += delta
	var t = _flicker_timer / _flicker_duration
	if t >= 1.0:
		_is_flickering = false
		scanlines.modulate.a = 1.0
		return

	# Flicker: oscillate opacity rapidly
	var flicker = (sin(_flicker_timer * 30.0) * 0.5 + 0.5)
	scanlines.modulate.a = lerp(1.0, 0.3, flicker)


func _start_flicker() -> void:
	_is_flickering = true
	_flicker_timer = 0.0
	_flicker_duration = randf_range(0.1, 0.4)


func trigger_glitch(duration: float = 0.5) -> void:
	"""
	Trigger a screen glitch effect.
	"""
	_start_flicker()
	_flicker_duration = duration
