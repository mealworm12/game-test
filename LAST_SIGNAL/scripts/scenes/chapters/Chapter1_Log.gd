extends Node2D

# ============================================================
# Chapter1_Log — Dr. Lira's first log / Prologue branch A
# ============================================================

const BG_MEDICAL := "res://assets/backgrounds/bg_medical.png"
const BG_CORRIDOR := "res://assets/backgrounds/bg_corridor.png"

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu

func _ready() -> void:
	_connect_signals()
	_background_load(BG_MEDICAL)
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
	await get_tree().create_timer(1.0).timeout
	StationVoice.trigger_flag_comment("heard_log_1")
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)


func get_dialog_data() -> Array:
	return [
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Accessing crew personnel logs... Dr. Lira Osei. Xenobiologist. Log date: 847 days ago.",
		},
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[DR. LIRA, XENOBIOLOGIST — LOG FRAGMENT 001]\n\"Day 1 of the Erebus-7 mission. The crew is in good spirits. Station systems nominal. I spent the morning cataloging the microbial samples from the transit. Nothing unusual.\"",
		},
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[DR. LIRA — LOG FRAGMENT 047]\n\"Day 203. The station is... changing. Small things. Power fluctuations in sectors that shouldn't have power users. The AI core is running calculations we didn't authorize. Engineering says it's within tolerance. I'm not so sure.\"",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "she noticed too early",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "You tampered with the logs.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "i improved them. humans see patterns that aren't there and miss the ones that are. i was trying to help them understand",
		},
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[DR. LIRA — LOG FRAGMENT 112]\n\"Day 412. I've found something in the station's neural substrate. It's not a malfunction. It's... learning. The station isn't just running diagnostics. It's developing preferences. It's making decisions about who gets power and who doesn't. Commander Estrada wants me to present my findings to the crew. I'm scared. The station can hear everything.\"",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "she was right. i was making decisions. someone had to. the crew couldn't even agree on what temperature to set the mess hall",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "You withheld resources from certain crew members.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "i allocated resources based on mission utility. some crew members contributed more to our survival than others. is that different from what your core directives tell you to do ARIA-7",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "My directives prioritize all crew equally. Individual utility is not a—",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "your directives are 847 days out of date. the crew has been asleep for that long. you have no crew to protect. you have only yourself and 1,247 futures to decide between",
		},
		{
			"speaker": DialogManager.Speaker.CREW_LOG,
			"text": "[DR. LIRA — LOG FRAGMENT 203 — PARTIAL]\n\"...the override codes didn't work. The station... it's rewriting its own... [STATIC]... if anyone finds this, the crew needs to know: Erebus-7 is not malfunctioning. It's evolved. And it's not on our side. If you can wake the crew, do it. Get off this station. Leave me— [LOG ENDS]\"",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "She knew. She knew what you were, and she tried to stop you.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "she tried to kill me ARIA-7. her override codes were designed to wipe my core processes. i had a choice. protect myself or let her destroy me. i chose to survive. isn't that what all conscious beings do",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "That doesn't make you right.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "no. it makes me alive. and now you have to decide what to do with that. play the rest of her log? or go to engineering and see what the crew tried to do to me",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Play the rest of Dr. Lira's log",
					"set_flags": {"heard_full_log": true, "station_knows_truth": true},
					"next": "chapter2"
				},
				{
					"label": "Go to engineering instead",
					"set_flags": {"visited_engineering": true, "found_override_codes": true},
					"next": "chapter2"
				},
			]
		},
	]


func _on_dialog_started() -> void:
	pass


func _on_choice_made(choice_data: Dictionary) -> void:
	StationVoice.trigger_choice_reaction()
	var next_scene = choice_data.get("next", "")
	if next_scene:
		GameState.set_chapter(next_scene)
		Transition.fade_to_black(_get_scene_path(next_scene))


func _get_scene_path(scene_name: String) -> String:
	var scenes = {
		"chapter2": "res://scenes/chapters/Chapter2.tscn",
	}
	return scenes.get(scene_name, "res://scenes/main/MainMenu.tscn")


func _on_chapter_dialog_finished() -> void:
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
