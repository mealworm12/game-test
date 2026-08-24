extends Node

# ============================================================
# AudioManager - Autoload singleton
# Handles ambient sounds, music layers, and SFX.
# v2: adds ID-based hooks (play_music_id / play_sfx_id /
# play_voice / crossfade_music) with graceful fallback when a
# file is missing - the game never crashes on absent assets.
# ============================================================

const AMBIENT_HUM := "res://assets/audio/sfx/ambient_hum.wav"
const AMBIENT_VOID := "res://assets/audio/sfx/ambient_void.wav"
const MUSIC_TENSION := "res://assets/audio/music/tension.wav"
const MUSIC_MELANCHOLY := "res://assets/audio/music/melancholy.wav"
const MUSIC_HOPE := "res://assets/audio/music/hope.wav"
const SFX_LOG_PLAY := "res://assets/audio/sfx/log_play.wav"
const SFX_STATION_VOICE := "res://assets/audio/sfx/station_voice.wav"
const SFX_UI_CLICK := "res://assets/audio/sfx/ui_click.wav"

# ---- v2 audio ID tables ----------------------------------------
# Canonical source: docs/AUDIO_MANIFEST.md (audio card spec).
const MUSIC_IDS: Dictionary = {
	"main_theme": "res://assets/audio/v2/music/main_theme.wav",
	"calm_loop": "res://assets/audio/v2/music/calm_loop.wav",
	"tension_loop": "res://assets/audio/v2/music/tension_loop.wav",
	"dread_loop": "res://assets/audio/v2/music/dread_loop.wav",
	"hope_loop": "res://assets/audio/v2/music/hope_loop.wav",
	"end_wake_them": "res://assets/audio/v2/music/end_wake_them.wav",
	"end_let_them_sleep": "res://assets/audio/v2/music/end_let_them_sleep.wav",
	"end_merge": "res://assets/audio/v2/music/end_merge.wav",
	"end_wake_but_leave": "res://assets/audio/v2/music/end_wake_but_leave.wav",
	"end_station_wins": "res://assets/audio/v2/music/end_station_wins.wav",
	"end_the_loop": "res://assets/audio/v2/music/end_the_loop.wav",
}

const SFX_IDS: Dictionary = {
	"ui_hover": "res://assets/audio/v2/sfx/ui_hover.wav",
	"ui_confirm": "res://assets/audio/v2/sfx/ui_confirm.wav",
	"ui_back": "res://assets/audio/v2/sfx/ui_back.wav",
	"log_play": "res://assets/audio/v2/sfx/log_play.wav",
	"terminal_type": "res://assets/audio/v2/sfx/terminal_type.wav",
	"door_open": "res://assets/audio/v2/sfx/door_open.wav",
	"door_close": "res://assets/audio/v2/sfx/door_close.wav",
	"alarm_soft": "res://assets/audio/v2/sfx/alarm_soft.wav",
	"alarm_hard": "res://assets/audio/v2/sfx/alarm_hard.wav",
	"pod_hiss": "res://assets/audio/v2/sfx/pod_hiss.wav",
	"power_down": "res://assets/audio/v2/sfx/power_down.wav",
	"power_up": "res://assets/audio/v2/sfx/power_up.wav",
	"heartbeat_low": "res://assets/audio/v2/sfx/heartbeat_low.wav",
	"cryo_beep_loop": "res://assets/audio/v2/sfx/cryo_beep_loop.wav",
	"static_burst": "res://assets/audio/v2/sfx/static_burst.wav",
}

const VOICE_IDS: Dictionary = {
	"station_low": "res://assets/audio/v2/voice/station_low.wav",
	"station_hostile": "res://assets/audio/v2/voice/station_hostile.wav",
	"station_intimate": "res://assets/audio/v2/voice/station_intimate.wav",
}

var _ambient_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _crossfade_player: AudioStreamPlayer

var _ambient_volume: float = -10.0  # dB
var _music_volume: float = -12.0     # dB

var _current_ambient: String = ""
var _current_music: String = ""
var _crossfade_tween: Tween = null


func _ready() -> void:
	_setup_players()
	_apply_settings_volumes()

func _apply_settings_volumes() -> void:
	if Settings:
		var master = Settings.get_setting("master_volume", 1.0)
		AudioServer.set_bus_volume_db(0, linear_to_db(master))
		var music = Settings.get_setting("music_volume", 0.7)
		set_music_volume(linear_to_db(music))
		var sfx = Settings.get_setting("sfx_volume", 0.8)
		_sfx_player.volume_db = linear_to_db(sfx)


func _setup_players() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = _ambient_volume
	add_child(_ambient_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = _music_volume
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Master"
	add_child(_voice_player)

	_crossfade_player = AudioStreamPlayer.new()
	_crossfade_player.bus = "Master"
	_crossfade_player.volume_db = -60.0
	add_child(_crossfade_player)

# ---- Ambient ----------------------------------------------------

func play_ambient(path: String, fade_time: float = 2.0) -> void:
	if path == _current_ambient:
		return
	_current_ambient = path
	if ResourceLoader.exists(path):
		var stream = load(path)
		_ambient_player.stream = stream
		_ambient_player.play()
	else:
		_log_missing("ambient", path)


func stop_ambient(fade_time: float = 1.0) -> void:
	_current_ambient = ""
	_ambient_player.stop()

# ---- Music ------------------------------------------------------

func play_music(path: String, fade_time: float = 2.0) -> void:
	if path == _current_music:
		return
	_current_music = path
	if ResourceLoader.exists(path):
		var stream = load(path)
		_music_player.stream = stream
		_music_player.play()
	else:
		_log_missing("music", path)


func stop_music(fade_time: float = 1.0) -> void:
	_current_music = ""
	_music_player.stop()


# v2: crossfade between two music streams using a second player.
func crossfade_music(path: String, fade_time: float = 2.0) -> void:
	if path == _current_music:
		return
	_current_music = path
	if not ResourceLoader.exists(path):
		_log_missing("music", path)
		return
	var stream = load(path)
	# Swap roles: old player fades out on _crossfade_player slot.
	var outgoing := _crossfade_player
	var incoming := _music_player
	outgoing.stream = _music_player.stream
	outgoing.volume_db = _music_player.volume_db
	if outgoing.stream and _music_player.playing:
		outgoing.play()
		_music_player.stop()
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(incoming, "volume_db", _music_volume, fade_time)
	_crossfade_tween.tween_property(outgoing, "volume_db", -60.0, fade_time)
	_crossfade_tween.chain().tween_callback(outgoing.stop)

# ---- SFX --------------------------------------------------------

func play_sfx(path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		_sfx_player.stream = stream
		_sfx_player.play()
	else:
		_log_missing("sfx", path)

# ---- v2 ID-based hooks ------------------------------------------

# Tension ladder per docs/AUDIO_SYSTEM_PROPOSAL.md:
# 0=calm 1=hope 2=tension 3=dread, standard crossfade between levels.
const TENSION_LADDER: Array = ["calm_loop", "hope_loop", "tension_loop", "dread_loop"]

var _current_tension_level: int = -1

func set_tension_level(level: int, fade_time: float = 3.0) -> void:
	var idx := clampi(level, 0, TENSION_LADDER.size() - 1)
	if idx == _current_tension_level:
		return
	_current_tension_level = idx
	play_music_id(TENSION_LADDER[idx], fade_time)

func get_tension_level() -> int:
	return _current_tension_level

# Ending stingers play once over the epilogue card, replacing the music loop.
const ENDING_STINGERS: Dictionary = {
	"ending_wake": "end_wake_them",
	"ending_sleep": "end_let_them_sleep",
	"ending_merge": "end_merge",
	"ending_wake_leave": "end_wake_but_leave",
	"ending_station_wins": "end_station_wins",
	"ending_loop": "end_the_loop",
}

func play_stinger_for_ending(ending_id: String) -> void:
	var stinger: String = ENDING_STINGERS.get(ending_id, "")
	if stinger == "":
		push_warning("AudioManager: no stinger for ending '%s'" % ending_id)
		return
	stop_music(0.5)
	_current_tension_level = -1
	play_music_id(stinger, 0.5, false)

func play_music_id(id: String, fade_time: float = 2.0, use_crossfade: bool = true) -> void:
	var path: String = MUSIC_IDS.get(id, "")
	if path == "":
		push_warning("AudioManager: unknown music id '%s'" % id)
		return
	if use_crossfade:
		crossfade_music(path, fade_time)
	else:
		play_music(path, fade_time)


func play_sfx_id(id: String) -> void:
	var path: String = SFX_IDS.get(id, "")
	if path == "":
		push_warning("AudioManager: unknown sfx id '%s'" % id)
		return
	play_sfx(path)


func play_voice_id(id: String) -> void:
	var path: String = VOICE_IDS.get(id, "")
	if path == "":
		push_warning("AudioManager: unknown voice id '%s'" % id)
		return
	if ResourceLoader.exists(path):
		_voice_player.stream = load(path)
		_voice_player.play()
	else:
		_log_missing("voice", path)


func stop_voice() -> void:
	_voice_player.stop()


func _log_missing(kind: String, path: String) -> void:
	print("AudioManager: missing %s asset (skipping): %s" % [kind, path])

# ---- Volume controls --------------------------------------------

func set_ambient_volume(db: float) -> void:
	_ambient_volume = db
	_ambient_player.volume_db = db


func set_music_volume(db: float) -> void:
	_music_volume = db
	_music_player.volume_db = db
