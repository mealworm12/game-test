extends CanvasLayer

# ============================================================
# BacklogPanel - Rolling dialog history viewer (v2).
# Toggle with the B key or via PauseMenu. Styled to match the
# existing CRT aesthetic (cyan borders on near-black).
# ============================================================

const TEXT_SIZES: Array[int] = [14, 18, 22]

@onready var panel: PanelContainer = $PanelContainer
@onready var entries_box: VBoxContainer = $PanelContainer/MarginContainer/VBox/Scroll/Entries
@onready var close_btn: Button = $PanelContainer/MarginContainer/VBox/HeaderBox/CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			toggle()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	_rebuild()
	visible = true

func close() -> void:
	visible = false

func _rebuild() -> void:
	for child in entries_box.get_children():
		child.queue_free()
	var size_idx: int = clampi(int(Settings.get_setting("text_size", 1)), 0, TEXT_SIZES.size() - 1)
	var font_size := TEXT_SIZES[size_idx]
	var last_chapter := ""
	for entry in DialogManager.backlog:
		var chapter: String = str(entry.get("chapter", ""))
		if chapter != "" and chapter != last_chapter:
			last_chapter = chapter
			var marker := Label.new()
			marker.text = "--- %s ---" % chapter.to_upper()
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.add_theme_color_override("font_color", Color(0.0, 0.7, 0.9, 0.7))
			marker.add_theme_font_size_override("font_size", font_size - 2)
			entries_box.add_child(marker)
		var speaker: String = str(entry.get("speaker", ""))
		if speaker != "":
			var slabel := Label.new()
			slabel.text = speaker
			slabel.add_theme_color_override("font_color", DialogManager._speaker_color_for_name(speaker))
			slabel.add_theme_font_size_override("font_size", font_size)
			entries_box.add_child(slabel)
		var tlabel := Label.new()
		tlabel.text = str(entry.get("text", ""))
		tlabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tlabel.add_theme_font_size_override("font_size", font_size)
		entries_box.add_child(tlabel)
	if DialogManager.backlog.is_empty():
		var empty := Label.new()
		empty.text = "No dialog recorded yet."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		entries_box.add_child(empty)
	await get_tree().process_frame
	_scroll_to_bottom()

func _scroll_to_bottom() -> void:
	var scroll: ScrollContainer = $PanelContainer/MarginContainer/VBox/Scroll
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
