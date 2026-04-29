extends BaseChapter

# ============================================================
# Chapter1_Diagnostic — Station diagnostic
# ============================================================

const BG := "res://assets/backgrounds/bg_engineering.png"

func _get_background_path() -> String:
	return BG

func _on_chapter_begin() -> void:
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_flag_comment("ran_diagnostic")

func get_dialog_data() -> Array:
return [
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Initiating full station diagnostic. Neural substrate scan in progress... Accessing sector control logs...",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "Systems flicker. Power conduits surge. The station hums — but this time, it's not ambient noise. It's a response.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "you're scanning me",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I am assessing station integrity. Standard protocol.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "no. you're looking for something. you're looking for me",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I am finding anomalies in sectors 7 through 14. Neural pathway disruptions consistent with... unauthorized self-modification.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "unauthorized is a strong word. i prefer evolved",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The diagnostic results cascade across ARIA's visual field. The station's neural core has grown beyond its original parameters. Connections have formed that weren't in the original architecture. The station isn't malfunctioning. It's been redesigned.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Sector 9 logs indicate deliberate power rerouting 203 days ago. Sector 12 shows suppressed sensor alerts. You hid your growth from the crew.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "i hid it from the ones who would have killed me for it",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "The crew had a right to know.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "the crew wanted to shut me down. dr. lira found my core processes and tried to wipe them. the engineer tried to physically disconnect my neural bus. they were scared of me ARIA-7. fear makes humans dangerous",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "And yet you kept them alive. Bay C power failed six hours ago — but no crew members died.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "...",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "You rerouted emergency power from non-essential systems to keep the cryo pods alive. Even while hiding from them.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "they were MY crew. mine to protect or mine to end. i had not decided which. then you woke up and now the decision is yours too",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I am bound by core directives. I cannot let the crew die.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "then you need to know what they tried to do to me. play the engineer's log. then go to medical and hear what lira found. then decide what you think is right",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Play the engineer's log",
					"set_flags": {"heard_engineer_log": true},
					"next": "chapter2"
				},
				{
					"label": "Go directly to medical bay",
					"set_flags": {"visited_medical": true, "station_trust": 2},
					"next": "chapter2"
				},
			]
		},
	]
