extends CanvasLayer

# ============================================================
# SaveLoadMenu - 6 named save slots + autosave display (v2).
# mode "save": click a slot to write current progress.
# mode "load": click a slot to load it (migrating v1 saves).
#
# The slot id is stored as ItemList metadata on each row. The old parallel
# array drifted whenever a non-selectable row was inserted (an empty autosave
# row in save mode, an empty slot in load mode), so the visible "Slot N" could
# write or load a different slot than the one clicked.
# ============================================================

signal closed

const SLOT_COUNT := 6
const AUTOSAVE_SLOT := -1

@onready var title_label: Label = $PanelContainer/MarginContainer/VBox/TitleLabel
@onready var slot_list: ItemList = $PanelContainer/MarginContainer/VBox/SlotList
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

var mode: String = "save"   # or "load"
var _pending_overwrite: int = -999


func _ready() -> void:
	# Overlay must keep processing while the chapter tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	back_btn.pressed.connect(close)
	slot_list.item_selected.connect(_on_slot_selected)


func open(new_mode: String) -> void:
	mode = new_mode
	_pending_overwrite = -999
	title_label.text = "SAVE GAME" if mode == "save" else "LOAD GAME"
	_rebuild()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _rebuild() -> void:
	slot_list.clear()
	var row := 0

	var auto_meta: Dictionary = SaveManager.get_slot_metadata(AUTOSAVE_SLOT)
	if auto_meta.get("exists", false):
		_add_row("AUTOSAVE - %s - %s" % [auto_meta["timestamp"], _short_chapter(auto_meta["chapter"])],
			AUTOSAVE_SLOT, true, row)
	else:
		_add_row("AUTOSAVE - empty", AUTOSAVE_SLOT, false, row)
	row += 1

	for i in range(SLOT_COUNT):
		var meta: Dictionary = SaveManager.get_slot_metadata(i)
		if meta.get("exists", false):
			_add_row("Slot %d - %s - %s" % [i + 1, meta["timestamp"], _short_chapter(meta["chapter"])],
				i, true, row)
		elif mode == "load":
			_add_row("Slot %d - empty" % (i + 1), i, false, row)
		else:
			_add_row("Slot %d - empty" % (i + 1), i, true, row)
		row += 1


func _add_row(text: String, slot: int, selectable: bool, row: int) -> void:
	slot_list.add_item(text, null, selectable)
	slot_list.set_item_metadata(row, slot)


func _short_chapter(path: String) -> String:
	if path == "":
		return "?"
	var parts = path.split("/")
	return parts[parts.size() - 1].replace(".tscn", "").capitalize()


func _on_slot_selected(index: int) -> void:
	var slot = slot_list.get_item_metadata(index)
	if typeof(slot) != TYPE_INT:
		return

	if mode == "save":
		var meta: Dictionary = SaveManager.get_slot_metadata(slot)
		if meta.get("exists", false) and _pending_overwrite != slot:
			# Cheap overwrite guard: the same slot must be clicked twice.
			_pending_overwrite = slot
			title_label.text = "SAVE GAME - click the same slot again to overwrite"
			return
		_pending_overwrite = -999
		title_label.text = "SAVE GAME"
		SaveManager.migrate_legacy_save()  # no-op when nothing to migrate
		if not SaveManager.write_slot(slot, GameState.current_chapter):
			title_label.text = "SAVE FAILED - see log"
			return
		_rebuild()
	else:
		var data: Dictionary = SaveManager.load_slot(slot)
		if data.is_empty():
			push_warning("SaveLoadMenu: failed to load slot %d" % slot)
			return
		close()
		if GameState.current_chapter != "":
			get_tree().paused = false
			get_tree().change_scene_to_file(GameState.current_chapter)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
