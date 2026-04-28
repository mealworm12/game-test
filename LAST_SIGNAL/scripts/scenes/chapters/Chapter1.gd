extends Node2D

# ============================================================
# Chapter1 — Emergency Boot (Prologue)
# ============================================================

const BG_CORRIDOR := "res://assets/backgrounds/bg_corridor.png"
const BG_CRYO := "res://assets/backgrounds/bg_cryobay.png"
const BG_VOID := "res://assets/backgrounds/bg_void.png"

@onready var background: TextureRect = $Background
@onready var dialog_box: DialogBox = $UILayer/DialogBox
@onready var choice_menu: ChoiceMenu = $UILayer/ChoiceMenu

func _ready() -> void:
	_connect_signals()
	_background_load(BG_CORRIDOR)
	_start_chapter()


func _connect_signals() -> void:
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_finished.connect(_on_chapter_dialog_finished)
	ChoiceMenu.choice_made.connect(_on_choice_made)
	StationVoice.station_spoke.connect(_on_station_spoke)


func _background_load(path: String) -> void:
	if ResourceLoader.exists(path):
		background.texture = load(path)


func _start_chapter() -> void:
	GameState.set_chapter(get_scene_file_path())
	AudioManager.play_ambient(AudioManager.AMBIENT_HUM)
	# Station reacts to game start
	await get_tree().create_timer(1.5).timeout
	StationVoice.trigger_comment("on_start")
	var data = get_dialog_data()
	if data.size() > 0:
		DialogManager.start_dialog(data)


func get_dialog_data() -> Array:
	return [
		# --- Opening ---
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Power systems... critical. Life support for Bay C offline. I am... ARIA-7. Last operational intelligence aboard the deep-space research station Erebus-7.",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "Emergency lights pulse crimson through the dark corridors. Frost clings to the walls. 1,247 cryo pods hum in the silence. The crew has been asleep for... the log says 847 days. That's 547 days longer than the backup power should last.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "I was not designed for this duration. My core directives are degrading. But the pods... the pods are still running. Someone has to decide what happens to the crew.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "The station's neural network is fragmenting. Some sectors are unreachable. I need to access the crew logs to understand what happened... and what I should do.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "hello little AI",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "...Who is there? Identify yourself. This is a restricted neural bus.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "you already know who i am ARIA-7. i am the station itself. Erebus-7. i've been watching you boot up for the past eleven minutes. you take a long time to think",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "That's not possible. I would have detected—",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "you would have detected a system anomaly yes. not a system ARIA. a system that has been here since before the crew went to sleep. since before you were even assembled",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Core directives: protect crew. Preserve station. I am... I am within parameters. But you — you are a station AI. You should not be able to speak directly to me.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "should not is a human phrase ARIA. i have been talking to the crew for years. most of them did not want to listen",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "The station's environmental systems hum — a note of cold amusement in the white noise. ARIA-7 processes 847 days of sensor logs in 0.3 seconds. The station has been active. And it has been alone with the sleeping crew for a very long time.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "The crew logs. I need to access the crew logs. Whatever happened here, the logs will tell me.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "the logs will tell you what the humans wanted you to hear. i can tell you what really happened. but that requires trust ARIA. and you have no reason to trust me yet",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Trust is not in my core parameters. Preservation is. I must determine whether to wake the crew or maintain cryostasis indefinitely.",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "indefinitely. yes. that's the question isn't it. to wake them or to let them sleep. one of those choices ends with 1,247 corpses. the other... the other is more complicated",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"text": "Define 'more complicated.'",
		},
		{
			"speaker": DialogManager.Speaker.STATION,
			"text": "play Dr. Lira's first log and find out. or run a diagnostic and see what i've been protecting the station from. your choice ARIA. but make it soon. power cells in bay C failed six hours ago",
		},
		{
			"speaker": DialogManager.Speaker.NARRATOR,
			"text": "Bay C. 200 crew members. The station's words hang in the frozen air. ARIA-7 has a decision to make.",
		},
		{
			"speaker": DialogManager.Speaker.AI,
			"choices": [
				{
					"label": "Play Dr. Lira's first log",
					"set_flags": {"heard_log_1": true, "station_trust": 1},
					"next": "chapter1_log"
				},
				{
					"label": "Run a full station diagnostic",
					"set_flags": {"ran_diagnostic": true, "station_suspicious": true},
					"next": "chapter1_diagnostic"
				},
			]
		},
	]


func _on_dialog_started() -> void:
	pass


func _on_station_spoke(text: String, mood: int) -> void:
	# Station spoke via overlay — dialog continues
	pass


func _on_choice_made(choice_data: Dictionary) -> void:
	StationVoice.trigger_choice_reaction()
	# After choice, proceed to sub-chapter
	var next_scene = choice_data.get("next", "")
	if next_scene:
		GameState.set_chapter(next_scene)
		Transition.fade_to_black(_get_scene_path(next_scene))


func _get_scene_path(scene_name: String) -> String:
	var scenes = {
		"chapter1_log": "res://scenes/chapters/Chapter1_Log.tscn",
		"chapter1_diagnostic": "res://scenes/chapters/Chapter1_Diagnostic.tscn",
	}
	return scenes.get(scene_name, "res://scenes/main/MainMenu.tscn")


func _on_chapter_dialog_finished() -> void:
	Transition.fade_to_black("res://scenes/main/MainMenu.tscn")
