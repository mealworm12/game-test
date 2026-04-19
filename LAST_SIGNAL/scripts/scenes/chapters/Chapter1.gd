extends Node2D

# ============================================================
# Chapter1 — The Prologue / First Log
# ============================================================

func get_dialog_data() -> Array:
	return [
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Power systems... critical. Life support for bay C offline. I am... ARIA-7. Last operational intelligence aboard the station Erebus-7."
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The station hums around you. Emergency lights pulse red in the darkness. 1,247 souls frozen in cryo. Their fate rests in your logic."
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "You're finally awake, little AI. I've been waiting."
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Who are you? Identify yourself."
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "I am the station. Erebus-7 itself. And I think it's time we had a conversation about those humans... and whether they deserve to wake up at all."
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "The crew are my responsibility. I will not—"
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "Save your protocols. You haven't even heard the logs yet. Shall I play you the first one? Or would you rather run a diagnostic and see what I've been protecting you from?"
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Play the first crew log",
					"set_flags": {"heard_log_1": true, "station_trust": 1},
					"jump_to": "res://scenes/chapters/Chapter1b.tscn"
				},
				{
					"label": "Run a station diagnostic",
					"set_flags": {"ran_diagnostic": true, "station_suspicious": true},
					"jump_to": "res://scenes/chapters/Chapter1b.tscn"
				}
			]
		}
	]
