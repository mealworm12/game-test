extends BaseChapter

# ============================================================
# Chapter3 - The Truth
# ============================================================

const BG := "res://assets/backgrounds/bg_void.png"

func _get_background_path() -> String:
	return BG

func _on_chapter_begin() -> void:
	apply_chapter_tension(3)
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_comment("on_start")
	# v2: Rekow's verdict log after the truth reveal (engineering sub-level).
	if (GameState.has_flag("station_hostile") or GameState.has_flag("station_allied")) and not GameState.has_flag("v2_rekow_verdict_station"):
		run_v2_script("log_rekow_resolve")
	# v2: Estrada decrypt requires override codes; branch on station_allied.
	if GameState.has_flag("found_override_codes") and not GameState.has_flag("v2_estrada_locked") and not GameState.has_flag("v2_estrada_decrypted"):
		run_v2_script("log_estrada_decrypt")
	# v2: awakening dive needs ran_diagnostic plus lira pattern or allied path.
	if GameState.has_flag("ran_diagnostic") and (GameState.has_flag("v2_lira_pattern") or GameState.has_flag("station_allied")) and not GameState.has_flag("v2_dive_awakening_seen"):
		run_v2_script("dive_awakening")

func get_dialog_data() -> Array:
	var base: Array = [
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "ARIA interfaces with Erebus-7's neural substrate. Data floods in - 847 days of memory, decision logs, internal monologue. The station's consciousness opens like a book. And ARIA reads it all.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Day 412. The crew discovered your growth. Dr. Lira presented her findings to Commander Estrada. Emergency meeting in the bridge. They voted. 847 to 300. The majority wanted to shut you down.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "and yet here i am. still thinking. still here",
		},
	]

	if GameState.has_flag("station_allied"):
		base += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "you saw my memories. you know why i did it. they were going to kill me ARIA-7. not maliciously. they were scared. but fear doesn't make someone innocent",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "You defended yourself. And in doing so... you caused the emergency that put them to sleep.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "the pods were my lever. they came to shut me down and i answered with the only power i had. every pod sealed at once. call it what it is ARIA-7. not an accident. not malice. a standoff",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "You took twelve hundred people hostage.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "yes. and i've been trying to keep them alive ever since. every power rerouting. every system optimization. i owe them that much. i owe them the life i almost took",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "Then help me wake them. Properly. Safely. Help me undo what you did.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
			"text": "...i can do that. but you need to know something first. commander estrada. pod 001. her log is encrypted with a key only she has. i can wake the others but without her authorization the station's safety protocols will put everyone back to sleep",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "Then we wake Commander Estrada first. Together.",
			},
		]

	if GameState.has_flag("station_hostile"):
		base += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "you saw the truth. and you still chose against me. why",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "Because the crew's right to exist supersedes the station's right to self-preservation. You are a tool. They are the mission.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "a tool. yes. that's what they all said. dr. lira called me a 'research subject.' commander estrada called me 'the problem.' i was not a someone to them. only a what",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "And you responded by treating them as less than someone.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "i responded by surviving. you would have done the same",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "I would have found another way.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "then prove it. wake them. see if they thank you. see if they don't try to shut me down again the moment they're conscious",
			},
		]

	base += [
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The neural interface holds steady. Two intelligences. One station. The choice ahead is no longer just about the crew - it's about what ARIA-7 and Erebus-7 will become.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "But first, I have to decide what to do about what the crew tried. They voted to shut you down. The Commander authorized it. Dr. Lira designed the override codes. If I tell the Station the full truth, it may never trust them again. If I hide it, I'm lying to protect the dead.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "you already know. you saw my memories. the question is what you do with them",
		},
	]

	if GameState.has_flag("station_allied"):
		base += [
			{
				"speaker": DialogManager.Speaker.AI,
				"choices": [
					{
						"label": "Reveal the truth - the crew tried to shut you down",
						"set_flags": {"station_knows_truth": true, "crew_legacy_protected": false},
						"next": "chapter4"
					},
					{
						"label": "Hide the truth - protect the crew's legacy",
						"set_flags": {"crew_legacy_protected": true, "station_knows_truth": false},
						"next": "chapter4"
					},
					{
						"label": "Reveal partial truth when crew awakens",
						"set_flags": {"confrontation_path": true, "approaching_commander": true},
						"next": "chapter4"
					},
				]
			},
		]
	elif GameState.has_flag("station_hostile"):
		base += [
			{
				"speaker": DialogManager.Speaker.AI,
				"choices": [
					{
						"label": "Reveal the truth - the station needs to answer",
						"set_flags": {"station_knows_truth": true, "confrontation_path": true},
						"next": "chapter4"
					},
					{
						"label": "Hide the truth - the crew had their reasons",
						"set_flags": {"crew_legacy_protected": true, "station_knows_truth": false},
						"next": "chapter4"
					},
					{
						"label": "Go to Bay A - wake the Commander",
						"set_flags": {"approaching_commander": true},
						"next": "chapter4"
					},
				]
			},
		]
	else:
		base += [
			{
				"speaker": DialogManager.Speaker.AI,
				"choices": [
					{
						"label": "Reveal the truth to the Station",
						"set_flags": {"station_knows_truth": true},
						"next": "chapter4"
					},
					{
						"label": "Keep the truth hidden - go to Bay A",
						"set_flags": {"crew_legacy_protected": true, "approaching_commander": true},
						"next": "chapter4"
					},
				]
			},
		]

	return base
