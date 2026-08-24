extends CanvasLayer

# ============================================================
# SettingsMenu - Overlay for adjusting preferences.
# ============================================================

signal closed

@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBox/MasterSlider
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBox/MusicSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBox/SFXSlider
@onready var speed_slider: HSlider = $PanelContainer/MarginContainer/VBox/SpeedSlider
@onready var text_size_btn: OptionButton = $PanelContainer/MarginContainer/VBox/TextSizeBtn
@onready var contrast_btn: CheckButton = $PanelContainer/MarginContainer/VBox/ContrastBtn
@onready var crt_slider: HSlider = $PanelContainer/MarginContainer/VBox/CRTSlider
@onready var fullscreen_btn: CheckButton = $PanelContainer/MarginContainer/VBox/FullscreenBtn
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

const TEXT_SIZE_LABELS: Array[String] = ["Small", "Medium", "Large"]

func _ready() -> void:
	visible = false
	_connect_signals()
	_load_values()
	for label in TEXT_SIZE_LABELS:
		text_size_btn.add_item(label)

func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	text_size_btn.item_selected.connect(_on_text_size_changed)
	contrast_btn.toggled.connect(_on_contrast_toggled)
	crt_slider.value_changed.connect(_on_crt_changed)
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	back_btn.pressed.connect(_on_back)

func _load_values() -> void:
	master_slider.value = Settings.get_setting("master_volume") * 100.0
	music_slider.value = Settings.get_setting("music_volume") * 100.0
	sfx_slider.value = Settings.get_setting("sfx_volume") * 100.0
	# Text speed slider: 0.01 (fast) to 0.10 (slow)
	var speed = Settings.get_setting("text_speed")
	speed_slider.value = (0.10 - speed) * 1000.0
	var size_idx: int = clampi(int(Settings.get_setting("text_size", 1)), 0, TEXT_SIZE_LABELS.size() - 1)
	text_size_btn.select(size_idx)
	contrast_btn.button_pressed = bool(Settings.get_setting("high_contrast", false))
	crt_slider.value = float(Settings.get_setting("crt_intensity", 0.5)) * 100.0
	fullscreen_btn.button_pressed = Settings.get_setting("fullscreen")

func open() -> void:
	visible = true
	get_tree().paused = true

func _on_master_changed(val: float) -> void:
	Settings.set_setting("master_volume", val / 100.0)

func _on_music_changed(val: float) -> void:
	Settings.set_setting("music_volume", val / 100.0)

func _on_sfx_changed(val: float) -> void:
	Settings.set_setting("sfx_volume", val / 100.0)

func _on_speed_changed(val: float) -> void:
	# Slider 0-90 maps to 0.10 - 0.01
	var actual = 0.10 - (val / 1000.0)
	Settings.set_setting("text_speed", actual)
	DialogManager.typewriter_speed = actual

func _on_fullscreen_toggled(val: bool) -> void:
	Settings.set_setting("fullscreen", val)


func _on_text_size_changed(idx: int) -> void:
	Settings.set_setting("text_size", clampi(idx, 0, 2))


func _on_contrast_toggled(val: bool) -> void:
	Settings.set_setting("high_contrast", val)


func _on_crt_changed(val: float) -> void:
	# 0..100 slider -> 0.0..1.0 intensity; 0 disables flicker/shake
	Settings.set_setting("crt_intensity", val / 100.0)

func _on_back() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()
