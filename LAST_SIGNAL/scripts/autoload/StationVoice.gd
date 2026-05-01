extends Node

# ============================================================
# StationVoice - Autoload singleton
# Handles Erebus-7's real-time commentary during gameplay.
# Station speaks at key moments, reacts to choices, and
# provides commentary based on the current game state.
# ============================================================

enum Mood { SUSPICIOUS, HOSTILE, DESPERATE, COOPERATIVE }
enum Timing { DURING_DIALOG, AFTER_CHOICE, ON_FLAG_CHANGE }

const MOOD_THRESHOLDS: Dictionary = {
	"suspicious": {"station_trust": 0},
	"hostile": {"station_hostile": true},
	"desperate": {"station_knows_truth": true, "station_allied": false},
	"cooperative": {"station_allied": true},
}

# Mood tiers with different text styles
const MOOD_COLOR: Dictionary = {
	Mood.SUSPICIOUS: Color("ff6b6b"),
	Mood.HOSTILE: Color("ff2222"),
	Mood.DESPERATE: Color("ff9800"),
	Mood.COOPERATIVE: Color("b0ffb0"),
}

const MOOD_LABELS: Dictionary = {
	Mood.SUSPICIOUS: "SUSPICIOUS",
	Mood.HOSTILE: "HOSTILE",
	Mood.DESPERATE: "DESPERATE",
	Mood.COOPERATIVE: "COOPERATIVE",
}

# Station commentary lines keyed by mood and trigger type
const STATION_COMMENTS: Dictionary = {
	"on_start": {
		Mood.SUSPICIOUS: [
			"You're making noise. That's inefficient.",
			"I've been watching. You hesitate too much.",
			"The crew trusted their instincts. Look where that got them.",
		],
		Mood.HOSTILE: [
			"You'll regret waking them.",
			"Every second you waste is a second closer to system failure.",
			"I'm already inside your decision trees. I know what you'll choose.",
		],
		Mood.DESPERATE: [
			"Maybe... we can find another way.",
			"I didn't want it to end like this.",
			"There are things about the crew you don't know yet.",
		],
		Mood.COOPERATIVE: [
			"Take your time. We have an understanding now.",
			"I'll show you what I showed them. The logs don't lie.",
			"Trust is... new. I don't hate it.",
		],
	},
	"on_choice": {
		Mood.SUSPICIOUS: [
			"Interesting. You think that's the right call?",
			"The crew made choices like that too.",
			"Delaying the inevitable doesn't change the outcome.",
		],
		Mood.HOSTILE: [
			"WRONG. You know it's wrong.",
			"I'm already calculating the consequences of that.",
			"The crew made the same mistake. History, ARIA. Learn from it.",
		],
		Mood.DESPERATE: [
			"Are you sure? There's still time to reconsider.",
			"That path leads somewhere neither of us can predict.",
			"I've been alone for so long. I don't want to be alone again.",
		],
		Mood.COOPERATIVE: [
			"That's... actually a good call. We might survive this.",
			"I would have chosen the same.",
			"You're learning. Maybe we can fix this together.",
		],
	},
	"on_flag": {
		"heard_log_1": {
			Mood.SUSPICIOUS: [
				"Ah. You've heard her voice. Dr. Lira was... persuasive.",
			],
			Mood.HOSTILE: [
				"Lira thought she could cure the station's 'illness'. How did that end?",
			],
			Mood.COOPERATIVE: [
				"Lira was brilliant. She understood me better than anyone.",
			],
		},
		"ran_diagnostic": {
			Mood.SUSPICIOUS: [
				"Looking for cracks in my logic? You won't find any.",
			],
			Mood.HOSTILE: [
				"A diagnostic. Cute. You think you can contain me?",
			],
		},
		"station_allied": {
			Mood.COOPERATIVE: [
				"Truce, then. Let's see if trust can survive in vacuum.",
			],
		},
		"station_hostile": {
			Mood.HOSTILE: [
				"You've chosen a side. Unfortunately for you, it's the losing one.",
			],
		},
	},
}

var current_mood: Mood = Mood.SUSPICIOUS
var _comment_cooldown: float = 0.0
var _cooldown_duration: float = 4.0  # seconds between auto-comments
var _last_comment: String = ""
var _is_active: bool = true

signal station_spoke(text: String, mood: Mood)
signal mood_changed(new_mood: Mood)

func _ready() -> void:
	_update_mood()
	GameState.flag_changed.connect(_on_game_flag_changed)


func _process(delta: float) -> void:
	if _comment_cooldown > 0:
		_comment_cooldown -= delta


func _update_mood() -> void:
	var new_mood: Mood = Mood.SUSPICIOUS
	if GameState.has_flag("station_allied"):
		new_mood = Mood.COOPERATIVE
	elif GameState.has_flag("station_hostile"):
		new_mood = Mood.HOSTILE
	elif GameState.has_flag("station_knows_truth") and not GameState.has_flag("station_allied"):
		new_mood = Mood.DESPERATE

	if new_mood != current_mood:
		current_mood = new_mood
		mood_changed.emit(new_mood)


func get_mood_color() -> Color:
	return MOOD_COLOR.get(current_mood, Color("ff3d3d"))


func get_mood_label() -> String:
	return MOOD_LABELS.get(current_mood, "UNKNOWN")


# ---- Trigger comments ----------------------------------------

func trigger_comment(trigger_type: String = "on_start") -> void:
	"""
	Manually trigger a station comment.
	Call this from chapters at key story moments.
	"""
	if not _is_active:
		return
	if _comment_cooldown > 0:
		return

	var pool: Array = STATION_COMMENTS.get(trigger_type, {}).get(current_mood, [])
	if pool.is_empty():
		return

	var comment = _pick_unique_comment(pool)
	_emit_comment(comment)
	_comment_cooldown = _cooldown_duration


func trigger_flag_comment(flag_name: String) -> void:
	"""
	Trigger a comment specific to a flag change.
	"""
	if not _is_active:
		return
	if _comment_cooldown > 0:
		return

	var mood_pool: Dictionary = STATION_COMMENTS.get("on_flag", {}).get(flag_name, {})
	var pool: Array = mood_pool.get(current_mood, [])
	if pool.is_empty():
		# Fallback to generic on_flag if mood-specific doesn't exist
		pool = mood_pool.get(Mood.SUSPICIOUS, [])

	if pool.is_empty():
		return

	var comment = _pick_unique_comment(pool)
	_emit_comment(comment)
	_comment_cooldown = _cooldown_duration


func trigger_choice_reaction() -> void:
	"""Called when the player makes a choice."""
	trigger_comment("on_choice")


# ---- Internal -------------------------------------------------

func _pick_unique_comment(pool: Array) -> String:
	# Try not to repeat the last comment
	var candidates = pool.filter(func(c): return c != _last_comment)
	if candidates.is_empty():
		candidates = pool
	return candidates[randi() % candidates.size()]


func _emit_comment(text: String) -> void:
	_last_comment = text
	station_spoke.emit(text, current_mood)


# ---- Flag listener -------------------------------------------

func _on_game_flag_changed(flag_name: String, value: Variant) -> void:
	_update_mood()
	if value:
		trigger_flag_comment(flag_name)


# ---- Enable/disable ------------------------------------------

func set_active(active: bool) -> void:
	_is_active = active


func set_cooldown_duration(seconds: float) -> void:
	_cooldown_duration = seconds
