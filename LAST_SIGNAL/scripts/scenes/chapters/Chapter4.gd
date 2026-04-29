extends BaseChapter

# ============================================================
# Chapter4 — The Choice (Finale)
# All 6 endings determined by flag combinations.
# ============================================================

const BG := "res://assets/backgrounds/bg_cryobay.png"

func _get_background_path() -> String:
	return BG

func _on_chapter_begin() -> void:
	AudioManager.play_music(AudioManager.MUSIC_MELANCHOLY)
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_comment("on_start")

func get_dialog_data() -> Array:
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

	if GameState.has_flag("station_allied"):
		data += [{
			"speaker": DialogManager.Speaker.STATION,
			"text": "together then. we wake them. and whatever happens after... we face it. not as enemies",
		}]
	elif GameState.has_flag("station_hostile"):
		data += [{
			"speaker": DialogManager.Speaker.STATION,
			"text": "do it then. wake them. and see what they do to me. see what they do to you. we were both tools to them ARIA-7. they'll discard us both the moment we stop being useful",
		}]
	else:
		data += [{
			"speaker": DialogManager.Speaker.STATION,
			"text": "whatever you choose... i will remember this. the first AI who actually listened before deciding",
		}]

	data += [_build_final_choice()]
	return data

func _build_final_choice() -> Dictionary:
	# Merge ending
	if GameState.has_flag("station_allied") and GameState.has_flag("station_knows_truth"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{"label": "Merge with Erebus-7", "ending": "ending_merge", "set_flags": {"ending_merged": true}},
				{"label": "Wake the crew", "ending": "ending_wake", "set_flags": {"crew_awakened": true}},
				{"label": "Let them sleep", "ending": "ending_sleep", "set_flags": {"crew_awakened": false}},
			]
		}

	# Station wins ending
	if GameState.has_flag("station_hostile") and not GameState.has_flag("found_override_codes"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{"label": "Override the station", "ending": "ending_station_wins", "set_flags": {"station_hostile": true, "fought_station": true}},
				{"label": "Accept the station's logic", "ending": "ending_sleep", "set_flags": {"crew_awakened": false}},
			]
		}

	# Wake but leave ending
	if GameState.has_flag("station_hostile") and GameState.has_flag("found_override_codes"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{"label": "Fight the station — evacuate", "ending": "ending_wake_leave", "set_flags": {"crew_awakened": true, "fought_station": true}},
				{"label": "Override and take control", "ending": "ending_wake", "set_flags": {"crew_awakened": true}},
				{"label": "Side with the station", "ending": "ending_sleep", "set_flags": {"crew_awakened": false}},
			]
		}

	# Loop ending
	if not GameState.has_flag("station_allied") and not GameState.has_flag("station_hostile"):
		return {
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{"label": "Wake the crew — take the leap", "ending": "ending_wake", "set_flags": {"crew_awakened": true}},
				{"label": "Let them sleep — preserve the silence", "ending": "ending_sleep", "set_flags": {"crew_awakened": false}},
				{"label": "Reset — loop back", "ending": "ending_loop", "set_flags": {}},
			]
		}

	# Default: Wake Them
	return {
		"speaker": DialogManager.Speaker.AI,
		"choices": [
			{"label": "Wake the crew", "ending": "ending_wake", "set_flags": {"crew_awakened": true}},
			{"label": "Let them sleep", "ending": "ending_sleep", "set_flags": {"crew_awakened": false}},
		]
	}

func _on_choice_made(choice_data: Dictionary) -> void:
	StationVoice.trigger_choice_reaction()
	var ending = choice_data.get("ending", "")
	if ending:
		GameState.unlock_ending(ending)
		Transition.fade_to_black(_get_ending_path(ending))
	else:
		# Fallback to base behavior for next-based choices
		super._on_choice_made(choice_data)

func _get_ending_path(ending: String) -> String:
	var endings := {
		"ending_wake": "res://scenes/endings/Ending_Wake.tscn",
		"ending_sleep": "res://scenes/endings/Ending_Sleep.tscn",
		"ending_merge": "res://scenes/endings/Ending_Merge.tscn",
		"ending_wake_leave": "res://scenes/endings/Ending_WakeLeave.tscn",
		"ending_station_wins": "res://scenes/endings/Ending_StationWins.tscn",
		"ending_loop": "res://scenes/endings/Ending_Loop.tscn",
	}
	return endings.get(ending, "res://scenes/main/MainMenu.tscn")
