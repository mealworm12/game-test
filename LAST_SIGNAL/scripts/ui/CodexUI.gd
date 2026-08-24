extends CanvasLayer

# ============================================================
# CodexUI - In-game compendium/archive (v2).
# Reads entries from the Codex autoload (content packs under
# res://content/v2/). Locked entries render as redacted
# placeholders. Accessible from main menu + pause menu.
# ============================================================

signal closed

const REDACTED_BODY := "[RECORD ENCRYPTED]\n\nAccess to this entry has not yet been granted.\nProgress further into the station's logs to unlock this record."

@onready var entry_list: ItemList = $PanelContainer/MarginContainer/VBox/HSplit/EntryList
@onready var detail_text: Label = $PanelContainer/MarginContainer/VBox/HSplit/DetailScroll/DetailText
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

var _ids: Array[String] = []

func _ready() -> void:
	visible = false
	back_btn.pressed.connect(close)
	entry_list.item_selected.connect(_on_entry_selected)

func open() -> void:
	_rebuild_list()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _rebuild_list() -> void:
	entry_list.clear()
	_ids.clear()
	var vis = Codex.get_visible_entries()
	for i in range(vis.size()):
		var e: Dictionary = vis[i]
		_ids.append(str(e["id"]))
		if e["unlocked"]:
			entry_list.add_item("%s [%s]" % [e["title"], str(e["category"]).to_upper()])
		else:
			entry_list.add_item("[REDACTED] ????????")
	detail_text.text = "Select a record to view."

func _on_entry_selected(index: int) -> void:
	if index < 0 or index >= _ids.size():
		return
	var entry: Dictionary = Codex.get_entry(_ids[index])
	if Codex.is_unlocked(_ids[index]):
		detail_text.text = "%s\n\n%s" % [str(entry.get("title", "")), str(entry.get("body", ""))]
	else:
		detail_text.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2, 1.0))
		detail_text.text = REDACTED_BODY
		return
	detail_text.remove_theme_color_override("font_color")

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
