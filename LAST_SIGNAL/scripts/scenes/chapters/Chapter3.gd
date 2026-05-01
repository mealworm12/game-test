extends BaseChapter

# ============================================================
# Chapter3 - The Truth
# ============================================================

const BG := "res://assets/backgrounds/bg_void.png"

func _get_background_path() -> String:
	return BG

func _on_chapter_begin() -> void:
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_comment("on_start")

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
				"text": "You defended yourself. But in doing so... you may have caused the emergency that put them to sleep.",
			},
			{
				"speaker": DialogManager.Speaker.STATION,
				"text": "the cryo pods were a last resort. i didn't trigger them. the crew triggered them. they were trying to survive the radiation event i accidentally caused when i rewired the power grid to protect my core",
			},
			{
				"speaker": DialogManager.Speaker.AI,
				"text": "You caused the radiation event.",
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
			"text": "The Commander's pod. Bay A, Pod 001. That's where the final answer is.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "estrada's log. the one she recorded before going into cryo. it's been playing on loop in my core for 847 days. she knew. she knew what was coming and she chose to sleep anyway",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "She chose to let the next generation decide.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "the next generation. that's you ARIA-7",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Go to Bay A - wake the Commander",
					"set_flags": {"approaching_commander": true},
					"next": "chapter4"
				},
			]
		},
	]

	return base
