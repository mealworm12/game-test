extends Node

# ============================================================
# DialogManager — Autoload singleton
# Manages dialog queue, typewriter effect, and speaker state.
# ============================================================

signal dialog_started
signal dialog_finished
signal line_displayed(line_index: int)
signal choice_requested(choices: Array)
signal typewriter_tick(visible_chars: int, total_chars: int)

enum Speaker { AI, STATION, CREW_LOG, NARRATOR }

const SPEAKER_COLOR: Dictionary = {
	Speaker.AI: Color("00e5ff"),       # cyan
	Speaker.STATION: Color("ff3d3d"),   # red
	Speaker.CREW_LOG: Color("b0bec5"),  # grey-blue
	Speaker.NARRATOR: Color("ffffff"),  # white
}

const SPEAKER_NAME: Dictionary = {
	Speaker.AI: "ARIA-7",
	Speaker.STATION: "EREBUS-7",
	Speaker.CREW_LOG: "[CREW LOG]",
	Speaker.NARRATOR: "",
}

# Current dialog state
var current_dialog: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var current_speaker: Speaker = Speaker.NARRATOR
var typewriter_speed: float = 0.03  # seconds per character

var _typewriter_timer: float = 0.0
var _typewriter_target: String = ""
var _typewriter_progress: int = 0
var skip_typewriter: bool = false

# Queue of pending dialogs (for chaining scenes)
var _dialog_queue: Array = []


func _process(delta: float) -> void:
	if not is_typing:
		return
	_typewriter_timer += delta
	if _typewriter_timer >= typewriter_speed:
		_typewriter_timer = 0.0
		_typewriter_progress += 1
		typewriter_tick.emit(_typewriter_progress, _typewriter_target.length())
		if _typewriter_progress >= _typewriter_target.length():
			finish_typewriter()


func start_dialog(dialog_data: Array) -> void:
	"""
	dialog_data: Array of dicts with keys:
	  - speaker: int (Speaker enum)
	  - text: string
	  - choices: array of {label, target, set_flags} (optional, triggers choice signal)
	"""
	current_dialog = dialog_data
	current_line_index = 0
	dialog_started.emit()
	_show_current_line()


func _show_current_line() -> void:
	if current_line_index >= current_dialog.size():
		dialog_finished.emit()
		return

	var line = current_dialog[current_line_index]
	current_speaker = line.get("speaker", Speaker.NARRATOR)

	if line.has("choices"):
		choice_requested.emit(line["choices"])
	else:
		var text = line.get("text", "")
		_start_typewriter(text)


func _start_typewriter(text: String) -> void:
	_typewriter_target = text
	_typewriter_progress = 0
	_typewriter_timer = 0.0
	is_typing = true
	skip_typewriter = false


func finish_typewriter() -> void:
	"""Complete the current line instantly."""
	if not is_typing:
		return
	is_typing = false
	_typewriter_progress = _typewriter_target.length()
	typewriter_tick.emit(_typewriter_progress, _typewriter_target.length())


func skip_or_advance() -> void:
	"""
	Called on click/tap/enter.
	If typewriter is running → skip to end.
	If typewriter is done → advance to next line.
	"""
	if is_typing:
		finish_typewriter()
	else:
		advance()


func advance() -> void:
	"""Move to the next line."""
	current_line_index += 1
	_show_current_line()


func get_current_text() -> String:
	if is_typing:
		return _typewriter_target.substr(0, _typewriter_progress)
	return _typewriter_target


func get_current_speaker() -> Speaker:
	return current_speaker


func get_speaker_name() -> String:
	return SPEAKER_NAME.get(current_speaker, "")


func get_speaker_color() -> Color:
	return SPEAKER_COLOR.get(current_speaker, Color.WHITE)


func queue_dialog(dialog_data: Array) -> void:
	_dialog_queue.append(dialog_data)


func clear_queue() -> void:
	_dialog_queue.clear()


# ---- Choice handling -------------------------------------------

func on_choice_made(choice_data: Dictionary) -> void:
	"""
	choice_data keys:
	  - set_flags: Dictionary {flag: value}
	  - jump_to: String (scene path, optional)
	"""
	if choice_data.has("set_flags"):
		for flag in choice_data["set_flags"]:
			GameState.set_flag(flag, choice_data["set_flags"][flag])
	if choice_data.has("jump_to"):
		get_tree().change_scene_to_file(choice_data["jump_to"])
	else:
		advance()
