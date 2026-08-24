extends CanvasLayer

# ============================================================
# SaveLoadMenu - 6 named save slots + autosave display (v2).
# mode "save": click a slot to write current progress.
# mode "load": click a slot to load it (migrating v1 saves).
# ============================================================

signal closed

const SLOT_COUNT := 6
const AUTOSAVE_SLOT := -1

@onready var title_label: Label = $PanelContainer/MarginContainer/VBox/TitleLabel
@onready var slot_list: ItemList = $PanelContainer/MarginContainer/VBox/SlotList
@onready var back_btn: Button = $PanelContainer/MarginContainer/VBox/BackBtn

var mode: String = "save"   # or "load"
var _slot_for_item: Array[int] = []

func _ready() -> void:
	visible = false
	back_btn.pressed.connect(close)
	slot_list.item_selected.connect(_on_slot_selected)

func open(new_mode: String) -> void:
	mode = new_mode
	title_label.text = "SAVE GAME" if mode == "save" else "LOAD GAME"
	_rebuild()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _rebuild() -> void:
	slot_list.clear()
	_slot_for_item.clear()
	var auto_meta: Dictionary = SaveManager.get_slot_metadata(AUTOSAVE_SLOT)
	if auto_meta.get("exists", false):
		slot_list.add_item("AUTOSAVE - %s - %s" % [auto_meta["timestamp"], _short_chapter(auto_meta["chapter"])])
		_slot_for_item.append(AUTOSAVE_SLOT)
	else:
		slot_list.add_item("AUTOSAVE - empty", null, false)
	for i in range(SLOT_COUNT):
		var meta: Dictionary = SaveManager.get_slot_metadata(i)
		if meta.get("exists", false):
			slot_list.add_item("Slot %d - %s - %s" % [i + 1, meta["timestamp"], _short_chapter(meta["chapter"])])
			_slot_for_item.append(i)
		elif mode == "load":
			slot_list.add_item("Slot %d - empty" % (i + 1), null, false)
		else:
			slot_list.add_item("Slot %d - empty" % (i + 1))
			_slot_for_item.append(i)

func _short_chapter(path: String) -> String:
	if path == "":
		return "?"
	var parts = path.split("/")
	return parts[parts.size() - 1].replace(".tscn", "").capitalize()

func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= _slot_for_item.size():
		return
	var slot := _slot_for_item[index]
	if mode == "save":
		SaveManager.migrate_legacy_save()  # no-op when nothing to migrate
		SaveManager.write_slot(slot, GameState.current_chapter, GameState.endings_unlocked)
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
