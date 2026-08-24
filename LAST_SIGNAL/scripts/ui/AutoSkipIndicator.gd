extends CanvasLayer

# ============================================================
# AutoSkipIndicator - Unobtrusive corner indicators for
# auto-advance mode and hold-to-skip state (v2).
# Instanced by BaseChapter; listens to DialogManager signals.
# ============================================================

@onready var auto_label: Label = $AutoLabel
@onready var skip_label: Label = $SkipLabel

func _ready() -> void:
	auto_label.visible = DialogManager.auto_mode
	skip_label.visible = false
	DialogManager.auto_mode_changed.connect(_on_auto_changed)
	DialogManager.skip_mode_changed.connect(_on_skip_changed)

func _on_auto_changed(enabled: bool) -> void:
	auto_label.visible = enabled

func _on_skip_changed(active: bool) -> void:
	skip_label.visible = active
