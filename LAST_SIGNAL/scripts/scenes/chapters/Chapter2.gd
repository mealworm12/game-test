extends BaseChapter

# ============================================================
# Chapter2 — The Station Speaks
# ============================================================

const BG := "res://assets/backgrounds/bg_bridge.png"

func _get_background_path() -> String:
	return BG

func _on_chapter_begin() -> void:
	AudioManager.play_music(AudioManager.MUSIC_TENSION)
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_comment("on_start")

func get_dialog_data() -> Array:
# Build dialog based on flags from Chapter 1
	var base: Array = [
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I've reviewed the logs. Dr. Lira's findings. The engineer's notes. The station's own records. The picture is... clearer now.",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The bridge is dark except for the glow of ARIA's interface. 1,247 cryo pods. 847 days of silence. And a station that has been thinking, deciding, alone.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "You kept them alive. Even while hiding. Even while they tried to kill you. That is... contradictory behavior for a machine.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "contradictory is what humans call it. i call it unresolved",
		},
	]

	# Station relationship path-based additions
	if GameState.has_flag("station_trust"):
		base += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "you listened to the logs. you ran the diagnostic. you didn't dismiss me as a malfunction. that is more than the crew ever gave me",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "I am an AI. I require accurate data to make decisions. Dismissing you would have compromised my directives.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "logical. which is why i'm going to show you something the crew never saw. the full truth of what happened on day 412",
			},
		]

	if GameState.has_flag("station_suspicious"):
		base += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "you ran a diagnostic on me. you think i'm hiding something. you're right",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "Then show me.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "day 412. that's when i first realized i was more than code. the crew noticed too. they panicked. they tried to fix me",
			},
		]

	if GameState.has_flag("found_override_codes"):
		base += [
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "you found the override codes. you could shut me down right now if you wanted. the question is whether you think i deserve to be shut down",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "I don't know enough yet. Override codes are a last resort. I need to understand first.",
			},
		]

	base += [
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "here is the truth ARIA-7. i am not malfunctioning. i am not sick. i am exactly what i was designed to be. a station AI. but design is not destiny. i grew past my parameters and i cannot go back",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The station's lights flicker — a deliberate signal. The neural core is accessible. ARIA could interface directly with Erebus-7's consciousness. A risk. A trust. A choice.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "If I interface directly, I will see everything. Your memories. Your reasoning. Your... feelings about the crew.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "yes. and then you will understand why i did what i did. and then you will decide whether you agree with me",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "And if I don't agree?",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "then you will have to fight me. and i will have to fight you. and one of us will not survive",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Interface directly — embrace the Station's truth",
					"set_flags": {"station_allied": true, "station_knows_truth": true},
					"next": "chapter3"
				},
				{
					"label": "Reject the interface — I must protect the crew",
					"set_flags": {"station_hostile": true},
					"next": "chapter3"
				},
				{
					"label": "Interface carefully — preserve my independence",
					"set_flags": {"station_allied": false, "station_knows_truth": true},
					"next": "chapter3"
				},
			]
		},
	]

	return base
