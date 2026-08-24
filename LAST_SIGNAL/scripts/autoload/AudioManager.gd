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
	"main_theme": "res://assets/audio/music/main_theme.wav",
	"calm_loop": "res://assets/audio/music/calm_loop.wav",
	"tension_loop": "res://assets/audio/music/tension_loop.wav",
	"dread_loop": "res://assets/audio/music/dread_loop.wav",
	"hope_loop": "res://assets/audio/music/hope_loop.wav",
}

const SFX_IDS: Dictionary = {
	"ui_hover": "res://assets/audio/sfx/ui_hover.wav",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.wav",
	"ui_back": "res://assets/audio/sfx/ui_back.wav",
	"log_play": "res://assets/audio/sfx/log_play.wav",
	"terminal_type": "res://assets/audio/sfx/terminal_type.wav",
	"door_open": "res://assets/audio/sfx/door_open.wav",
	"door_close": "res://assets/audio/sfx/door_close.wav",
	"alarm_soft": "res://assets/audio/sfx/alarm_soft.wav",
	"alarm_hard": "res://assets/audio/sfx/alarm_hard.wav",
	"pod_hiss": "res://assets/audio/sfx/pod_hiss.wav",
	"power_down": "res://assets/audio/sfx/power_down.wav",
	"power_up": "res://assets/audio/sfx/power_up.wav",
	"heartbeat_low": "res://assets/audio/sfx/heartbeat_low.wav",
	"cryo_beep_loop": "res://assets/audio/sfx/cryo_beep_loop.wav",
	"static_burst": "res://assets/audio/sfx/static_burst.wav",
}

const VOICE_IDS: Dictionary = {
	"station_low": "res://assets/audio/voice/station_low.wav",
	"station_hostile": "res://assets/audio/voice/station_hostile.wav",
	"station_intimate": "res://assets/audio/voice/station_intimate.wav",
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
