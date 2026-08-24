extends Node

# ============================================================
# DialogManager - Autoload singleton
# Manages dialog queue, typewriter effect, and speaker state.
# v2: script-command content player (see docs/DIALOG_FORMAT.md),
# backlog history recording, auto-advance, and hold-to-skip.
# ============================================================

signal dialog_started
signal dialog_finished
signal line_displayed(line_index: int)
signal choice_requested(choices: Array)
signal typewriter_tick(visible_chars: int, total_chars: int)
signal background_changed(path: String)
signal portrait_changed(who: String, expr: String)
signal dive_state_changed(active: bool)
signal codex_unlock_requested(entry_id: String)
signal auto_mode_changed(enabled: bool)
signal skip_mode_changed(active: bool)

enum Speaker { AI, STATION, CREW_LOG, NARRATOR }

const SPEAKER_COLOR: Dictionary = {
	Speaker.AI: Color("00e5ff"),       # cyan
	Speaker.STATION: Color("ff3d3d"),  # red
	Speaker.CREW_LOG: Color("b0bec5"), # grey-blue
	Speaker.NARRATOR: Color("ffffff"), # white
}

const SPEAKER_NAME: Dictionary = {
	Speaker.AI: "ARIA-7",
	Speaker.STATION: "EREBUS-7",
	Speaker.CREW_LOG: "[CREW LOG]",
	Speaker.NARRATOR: "",
}

const AUTO_DELAY_BASE := 1.2       # seconds after a finished line, before auto-advance
const SKIP_HOLD_TIME := 0.6        # seconds of holding to engage skip mode

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

# ---- v2 state ----------------------------------------------------
# Backlog: array of {speaker: String, text: String, chapter: String}
var backlog: Array = []
var _backlog_chapter: String = ""

# Auto mode
var auto_mode: bool = false
var _auto_timer: float = 0.0
var _auto_waiting: bool = false

# Skip (hold-to-fast-forward already-seen lines)
var _skip_hold_timer: float = 0.0
var skip_mode_active: bool = false

# Script-player runtime (docs/DIALOG_FORMAT.md)
var _script_lines: Array = []      # raw parsed command dicts
var _script_labels: Dictionary = {}  # label name -> index
var _script_running: bool = false
var _script_pc: int = 0            # program counter
var _seen_lines: Dictionary = {}   # text hash -> true (for skip gating)


func _process(delta: float) -> void:
	if is_typing:
		var speed := typewriter_speed
		if skip_mode_active:
			speed = minf(speed * 0.05, 0.001)
		_typewriter_timer += delta
		while _typewriter_timer >= speed and is_typing:
			_typewriter_timer -= speed
			_typewriter_progress += 1
			typewriter_tick.emit(_typewriter_progress, _typewriter_target.length())
			if _typewriter_progress >= _typewriter_target.length():
				finish_typewriter()
	else:
		_update_auto(delta)
		_update_skip_hold(delta)

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


# ---- v2: script command player -----------------------------------
# Executes lines produced by parse_script() (docs/DIALOG_FORMAT.md).
# Commands are dicts: {"cmd": "...", ...}. "say" and "choice" map
# onto the classic dialog flow; everything else executes instantly.

func run_script(script_text: String) -> void:
	var lines := parse_script(script_text)
	_script_labels.clear()
	for i in range(lines.size()):
		if lines[i].get("cmd", "") == "label":
			_script_labels[lines[i]["name"]] = i
	_script_lines = lines
	_script_running = true
	_script_pc = 0
	dialog_started.emit()
	_script_advance()


func _script_advance() -> void:
	while _script_running and _script_pc < _script_lines.size():
		var line: Dictionary = _script_lines[_script_pc]
		var cmd: String = line.get("cmd", "")
		match cmd:
			"label":
				_script_pc += 1
			"say":
				_record_backlog(line.get("speaker_name", ""), line.get("text", ""))
				current_speaker = line.get("speaker", Speaker.NARRATOR)
				_start_typewriter(line.get("text", ""))
				line_displayed.emit(_script_pc)
				return  # wait for advance()
			"choice":
				choice_requested.emit(line.get("choices", []))
				return  # resumes via resume_after_choice()
			"set_flag":
				GameState.set_flag(line.get("flag", ""), line.get("value", true))
				_script_pc += 1
			"if_flag":
				if GameState.has_flag(line.get("flag", "")):
					_script_pc = _resolve_jump(line.get("target", ""))
				else:
					_script_pc += 1
			"goto":
				_script_pc = _resolve_jump(line.get("target", ""))
			"sfx":
				AudioManager.play_sfx_id(line.get("id", ""))
				_script_pc += 1
			"music":
				AudioManager.play_music_id(line.get("id", ""))
				_script_pc += 1
			"voice":
				AudioManager.play_voice_id(line.get("id", ""))
				_script_pc += 1
			"bg":
				background_changed.emit(line.get("path", ""))
				_script_pc += 1
			"portrait":
				portrait_changed.emit(line.get("who", ""), line.get("expr", ""))
				_script_pc += 1
			"dive_start":
				dive_state_changed.emit(true)
				_script_pc += 1
			"dive_end":
				dive_state_changed.emit(false)
				_script_pc += 1
			"codex_unlock":
				codex_unlock_requested.emit(line.get("entry_id", ""))
				_script_pc += 1
			_:
				push_warning("DialogManager: unknown command '%s' at pc=%d" % [cmd, _script_pc])
				_script_pc += 1
	if _script_running:
		_script_running = false
		dialog_finished.emit()


func _resolve_jump(label: String) -> int:
	if _script_labels.has(label):
		return int(_script_labels[label])
	push_warning("DialogManager: unknown label '%s'" % label)
	return _script_pc + 1


func resume_after_choice(choice_data: Dictionary) -> void:
	"""Called by ChoiceMenu flow after a script 'choice' resolves."""
	if choice_data.has("goto_label"):
		_script_pc = _resolve_jump(choice_data["goto_label"])
	else:
		_script_pc += 1
	_script_advance()


# ---- v2: parser (authoritative syntax in docs/DIALOG_FORMAT.md) ---

static func parse_script(script_text: String) -> Array:
	var out: Array = []
	for raw_line in script_text.split("\n"):
		var line := raw_line.strip_edges()
		if line == "" or line.begins_with("#") or line.begins_with("//"):
			continue
		out.append(parse_command(line))
	return out


static func parse_command(line: String) -> Dictionary:
	var space_idx := line.find(" ")
	var head := line if space_idx < 0 else line.substr(0, space_idx)
	var rest := "" if space_idx < 0 else line.substr(space_idx + 1)
	match head:
		"say":
			# say <speaker>|<text>
			var parts = rest.split("|", true, 1)
			return {
				"cmd": "say",
				"speaker_name": parts[0].strip_edges(),
				"text": parts[1] if parts.size() > 1 else "",
			}
		"choice":
			# choice <prompt>|opt1|opt2|...
			var opts = rest.split("|")
			var prompt: String = ""
			var choices: Array = []
			if opts.size() > 0:
				prompt = opts[0].strip_edges()
			for i in range(1, opts.size()):
				# opt format: label->LABEL_NAME or plain text
				var opt := opts[i].strip_edges()
				if "->" in opt:
					var bits = opt.split("->", true, 1)
					choices.append({"label": bits[0].strip_edges(), "goto_label": bits[1].strip_edges()})
				else:
					choices.append({"label": opt})
			return {"cmd": "choice", "prompt": prompt, "choices": choices}
		"set_flag":
			# set_flag <flag> [on|off|<value>]
			var bits = rest.split(" ", true, 1)
			var value: Variant = true
			if bits.size() > 1:
				var vs := bits[1].strip_edges().to_lower()
				if vs == "off" or vs == "false":
					value = false
				elif vs == "on" or vs == "true":
					value = true
				else:
					value = bits[1].strip_edges()
			return {"cmd": "set_flag", "flag": bits[0].strip_edges(), "value": value}
		"if_flag":
			# if_flag <flag> goto <label>
			var re = RegEx.new()
			re.compile("^\\s*(\\S+)\\s+goto\\s+(\\S+)\\s*$")
			var m = re.search(rest)
			if m:
				return {"cmd": "if_flag", "flag": m.get_string(1), "target": m.get_string(2)}
			return {"cmd": "if_flag", "flag": rest.strip_edges(), "target": ""}
		"label":
			return {"cmd": "label", "name": rest.strip_edges()}
		"sfx", "music", "voice":
			return {"cmd": head, "id": rest.strip_edges()}
		"bg":
			return {"cmd": "bg", "path": rest.strip_edges()}
		"portrait":
			# portrait <who>:<expr>
			var pi = rest.find(":")
			if pi >= 0:
				return {"cmd": "portrait", "who": rest.substr(0, pi).strip_edges(), "expr": rest.substr(pi + 1).strip_edges()}
			return {"cmd": "portrait", "who": rest.strip_edges(), "expr": ""}
		"dive_start":
			return {"cmd": "dive_start"}
		"dive_end":
			return {"cmd": "dive_end"}
		"codex_unlock":
			return {"cmd": "codex_unlock", "entry_id": rest.strip_edges()}
	push_warning("DialogManager.parse_command: unrecognized line '%s'" % line)
	return {"cmd": "unknown", "raw": line}


# ---- Backlog ------------------------------------------------------

func set_backlog_chapter(chapter_marker: String) -> void:
	_backlog_chapter = chapter_marker


func _record_backlog(speaker: String, text: String) -> void:
	backlog.append({"speaker": speaker, "text": text, "chapter": _backlog_chapter})
	if backlog.size() > 200:
		backlog.pop_front()


func clear_backlog() -> void:
	backlog.clear()

# ---- Auto / Skip --------------------------------------------------

func set_auto_mode(enabled: bool) -> void:
	auto_mode = enabled
	_auto_waiting = false
	auto_mode_changed.emit(enabled)


func toggle_auto_mode() -> void:
	set_auto_mode(not auto_mode)


func _update_auto(delta: float) -> void:
	if not auto_mode or not _auto_waiting:
		return
	_auto_timer -= delta
	if _auto_timer <= 0.0:
		_auto_waiting = false
		skip_or_advance()


func _arm_auto_delay() -> void:
	# Per-line delay scaled by the player's text speed setting:
	# faster text -> shorter dwell time.
	var speed_factor: float = clampf(Settings.get_setting("text_speed", 0.03) / 0.03, 0.5, 4.0)
	_auto_timer = AUTO_DELAY_BASE * speed_factor + _typewriter_target.length() * 0.01
	_auto_waiting = true


func _update_skip_hold(delta: float) -> void:
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_select"):
		_skip_hold_timer += delta
		if not skip_mode_active and _skip_hold_timer >= SKIP_HOLD_TIME:
			skip_mode_active = _has_seen_current()
			skip_mode_changed.emit(skip_mode_active)
	else:
		_skip_hold_timer = 0.0
		if skip_mode_active:
			skip_mode_active = false
			skip_mode_changed.emit(false)


func _has_seen_current() -> bool:
	var key := _typewriter_target.strip_edges().to_lower()
	return key != "" and _seen_lines.get(key.hash(), false)


func _mark_seen(text: String) -> void:
	_seen_lines[text.strip_edges().to_lower().hash()] = true

# ---- Core flow ----------------------------------------------------

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
	_mark_seen(text)


func finish_typewriter() -> void:
	"""Complete the current line instantly."""
	if not is_typing:
		return
	is_typing = false
	_typewriter_progress = _typewriter_target.length()
	typewriter_tick.emit(_typewriter_progress, _typewriter_target.length())
	_arm_auto_delay()


func skip_or_advance() -> void:
	"""
	Called on click/tap/enter.
	If typewriter is running -> skip to end.
	If typewriter is done -> advance to next line.
	"""
	if is_typing:
		finish_typewriter()
	else:
		advance()


func advance() -> void:
	"""Move to the next line."""
	if _script_running:
		_script_pc += 1
		_script_advance()
		return
	current_line_index += 1
	_show_current_line()


func get_current_text() -> String:
	if is_typing:
		return _typewriter_target.substr(0, _typewriter_progress)
	return _typewriter_target


func get_current_speaker() -> Speaker:
	return current_speaker


func get_speaker_name() -> String:
	if _script_running:
		return str(current_speaker)
	return SPEAKER_NAME.get(current_speaker, "")


func get_speaker_color() -> Color:
	if _script_running:
		return _speaker_color_for_name(str(current_speaker))
	return SPEAKER_COLOR.get(current_speaker, Color.WHITE)


func _speaker_color_for_name(name: String) -> Color:
	match name.to_upper():
		"ARIA-7", "AI":
			return SPEAKER_COLOR[Speaker.AI]
		"EREBUS-7", "STATION":
			return SPEAKER_COLOR[Speaker.STATION]
		"[CREW LOG]", "CREW_LOG", "CREW LOG":
			return SPEAKER_COLOR[Speaker.CREW_LOG]
	return SPEAKER_COLOR[Speaker.NARRATOR]


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
	  - goto_label: String (script label, optional - v2 script mode)
	"""
	if choice_data.has("set_flags"):
		for flag in choice_data["set_flags"]:
			GameState.set_flag(flag, choice_data["set_flags"][flag])
	if _script_running:
		resume_after_choice(choice_data)
	elif choice_data.has("jump_to"):
		get_tree().change_scene_to_file(choice_data["jump_to"])
	elif choice_data.has("next"):
		get_tree().change_scene_to_file(choice_data["next"])
	else:
		advance()
