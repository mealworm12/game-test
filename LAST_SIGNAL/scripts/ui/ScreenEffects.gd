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
var _dive_mode: bool = false


func _ready() -> void:
	_scanlines_setup()
	_vignette_setup()
	_apply_intensity()
	if Settings and not Settings.settings_changed.is_connected(_on_setting_changed):
		Settings.settings_changed.connect(_on_setting_changed)


func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "crt_intensity":
		_apply_intensity()


func _intensity() -> float:
	return clampf(float(Settings.get_setting("crt_intensity", 0.5)), 0.0, 1.0) if Settings else 0.5


func _apply_intensity() -> void:
	var i := _intensity()
	scanlines.modulate.a = i
	vignette.modulate.a = lerpf(0.4, 1.0, i)


func set_dive_mode(active: bool) -> void:
	_dive_mode = active
	trigger_glitch(0.6)


func _scanlines_setup() -> void:
	scanlines.visible = true


func _vignette_setup() -> void:
	vignette.visible = true


func _process(delta: float) -> void:
	_do_flicker(delta)


func _do_flicker(delta: float) -> void:
	var intensity := _intensity()
	# Photosensitivity: intensity 0 disables flicker entirely.
	if intensity <= 0.01:
		scanlines.modulate.a = 0.0
		return
	if not _is_flickering:
		if randf() < 0.002 * intensity:
			_start_flicker()
		return

	_flicker_timer += delta
	var t = _flicker_timer / _flicker_duration
	if t >= 1.0:
		_is_flickering = false
		scanlines.modulate.a = intensity
		return

	# Flicker: oscillate opacity rapidly (scaled by intensity)
	var flicker = (sin(_flicker_timer * 30.0) * 0.5 + 0.5)
	scanlines.modulate.a = lerp(intensity, intensity * 0.3, flicker)


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
