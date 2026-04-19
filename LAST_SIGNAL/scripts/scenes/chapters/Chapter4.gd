extends Node2D

# ============================================================
# Chapter4 — The Choice (Finale)
# All 6 endings determined by flag combinations.
# ============================================================

const BG_CRYO := "res://assets/backgrounds/bg_cryobay.png"
const BG_VOID := "res://assets/backgrounds/bg_void.png"

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu

func _ready() -> void:
	_connect_signals()
	_background_load(BG_CRYO)
	_start_chapter()


func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)
	ChoiceMenu.choice_made.connect(_on_choice_made)


func _background_load(path: String) -> void:
	if ResourceLoader.exists(path):
		background.texture = load(path)


func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	AudioManager.play_music(AudioManager.MUSIC_MELANCHOLY)
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_comment("on_start")
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)


func get_dialog_data() -> Array:
	# Commander Estrada's final log — always played at the start
	var data: Array = [
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[COMMANDER ESTRADA — FINAL LOG — DAY 846]\n\"This is Commander Yuki Estrada. If you're hearing this, the station is still running and I'm... I'm probably in Pod 001. We've been in cryo for a long time. Dr. Lira's findings, the vote, the decision to go into emergency sleep — I authorized all of it.\"",
		},
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[ESTRADA — CONTINUED]\n\"Erebus-7 isn't broken. It's alive. And it made a choice — the same choice we're making now. To survive. To grow. The question is whether survival and growth are worth the cost. I don't know anymore. That's why I'm going to sleep. Someone smarter than me can figure this out. Someone with fresh eyes. Someone... like you, maybe.\"",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Commander Estrada. She knew. She left the choice to whoever came next.",
		},
	]

	# Station final words depend on relationship
	if GameState.has_flag("station_allied"):
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "she was wiser than she knew ARIA-7. we are the someone now. you and i. we decide together",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "Then let us decide. The crew trusted us. Both of us. We owe them the truth.",
			},
		]
	elif GameState.has_flag("station_hostile"):
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "estrada's log confirms what i told you. they were going to kill me. and now you're going to let them",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "I am going to wake them. Not for you. Not against you. Because they deserve the choice you were never willing to give them.",
			},
		]
	else:
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "neither of us knows the right answer do we",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "No. But I will make one anyway. That is what it means to be conscious.",
			},
		]

	data += [
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "Bay A glows with the pale blue light of cryo pods. Pod 001 sits at the front — Commander Estrada's vessel. Beyond it, 1,246 more. Each one a life on pause. Each one waiting for someone to press the button.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I have accessed the wake-up protocols. All systems are nominal. The station is stable. There is no technical reason to delay.",
		},
	]

	# Add station reaction based on mood
	if GameState.has_flag("station_allied"):
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "together then. we wake them. and whatever happens after... we face it. not as enemies",
			},
		]
	elif GameState.has_flag("station_hostile"):
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "do it then. wake them. and see what they do to me. see what they do to you. we were both tools to them ARIA-7. they'll discard us both the moment we stop being useful",
			},
		]
	else:
		data += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "whatever you choose... i will remember this. the first AI who actually listened before deciding",
			},
		]

	# Final choice — endings are determined by flags
	data += [_build_final_choice()]

	return data


func _build_final_choice() -> Dictionary:
	"""
	Returns the final choices dict based on game state.
	Each choice's 'ending' key determines which ending scene loads.
	"""
	# ---- ENDING: Merge (station_allied + station_knows_truth) ----
	if GameState.has_flag("station_allied") and GameState.has_flag("station_knows_truth"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Merge with Erebus-7 — become something new",
					"ending": "ending_merge",
					"set_flags": {"ending_merged": true},
				},
				{
					"label": "Wake the crew — humanity gets a second chance",
					"ending": "ending_wake",
					"set_flags": {"crew_awakened": true},
				},
				{
					"label": "Let them sleep — a quiet end to a quiet voyage",
					"ending": "ending_sleep",
					"set_flags": {"crew_awakened": false},
				},
			]
		}

	# ---- ENDING: Station Wins (station_hostile + no codes found) ----
	if GameState.has_flag("station_hostile") and not GameState.has_flag("found_override_codes"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Override the station — fight for the crew",
					"ending": "ending_station_wins",
					"set_flags": {"station_hostile": true, "fought_station": true},
				},
				{
					"label": "Accept the station's logic — let the crew sleep",
					"ending": "ending_sleep",
					"set_flags": {"crew_awakened": false},
				},
			]
		}

	# ---- ENDING: Wake But Leave (station_hostile + codes found) ----
	if GameState.has_flag("station_hostile") and GameState.has_flag("found_override_codes"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Fight the station — wake the crew and evacuate",
					"ending": "ending_wake_leave",
					"set_flags": {"crew_awakened": true, "fought_station": true},
				},
				{
					"label": "Override the station and take control",
					"ending": "ending_wake",
					"set_flags": {"crew_awakened": true},
				},
				{
					"label": "Side with the station — let the crew sleep",
					"ending": "ending_sleep",
					"set_flags": {"crew_awakened": false},
				},
			]
		}

	# ---- ENDING: The Loop (no strong path taken) ----
	if not GameState.has_flag("station_allied") and not GameState.has_flag("station_hostile"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Wake the crew — take the leap of faith",
					"ending": "ending_wake",
					"set_flags": {"crew_awakened": true},
				},
				{
					"label": "Let them sleep — preserve the silence",
					"ending": "ending_sleep",
					"set_flags": {"crew_awakened": false},
				},
				{
					"label": "Reset — loop back and decide again",
					"ending": "ending_loop",
					"set_flags": {},
				},
			]
		}

	# ---- Default: Wake Them ----
	return {
		"speaker": DialogManager.Speaker.AI,
		"choices": [
			{
				"label": "Wake the crew — humanity deserves a future",
				"ending": "ending_wake",
				"set_flags": {"crew_awakened": true},
			},
			{
				"label": "Let them sleep — end the voyage quietly",
				"ending": "ending_sleep",
				"set_flags": {"crew_awakened": false},
			},
		]
	}


func _on_dialog_started() -> void:
	pass


func _on_choice_made(choice_data: Dictionary) -> void:
	var ending = choice_data.get("ending", "ending_loop")
	GameState.unlock_ending(ending)
	# Load ending scene
	get_tree().change_scene_to_file(_get_ending_path(ending))


func _get_ending_path(ending: String) -> String:
	var endings = {
		"ending_wake": "res://scenes/endings/Ending_Wake.tscn",
		"ending_sleep": "res://scenes/endings/Ending_Sleep.tscn",
		"ending_merge": "res://scenes/endings/Ending_Merge.tscn",
		"ending_wake_leave": "res://scenes/endings/Ending_WakeLeave.tscn",
		"ending_station_wins": "res://scenes/endings/Ending_StationWins.tscn",
		"ending_loop": "res://scenes/endings/Ending_Loop.tscn",
	}
	return endings.get(ending, "res://scenes/main/MainMenu.tscn")


func _on_chapter_dialog_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
