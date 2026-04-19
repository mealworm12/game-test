extends Node

# ============================================================
# AudioManager — Autoload singleton
# Handles ambient sounds, music layers, and SFX.
# ============================================================

const AMBIENT_HUM := "res://assets/audio/sfx/ambient_hum.wav"
const AMBIENT_VOID := "res://assets/audio/sfx/ambient_void.wav"
const MUSIC_TENSION := "res://assets/audio/music/tension.ogg"
const MUSIC_MELANCHOLY := "res://assets/audio/music/melancholy.ogg"
const MUSIC_HOPE := "res://assets/audio/music/hope.ogg"
const SFX_LOG_PLAY := "res://assets/audio/sfx/log_play.wav"
const SFX_STATION_VOICE := "res://assets/audio/sfx/station_voice.wav"
const SFX_UI_CLICK := "res://assets/audio/sfx/ui_click.wav"

var _ambient_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

var _ambient_volume: float = -10.0  # dB
var _music_volume: float = -12.0     # dB

var _current_ambient: String = ""
var _current_music: String = ""


func _ready() -> void:
	_setup_players()


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
		# Silently skip if asset missing — no crash
		pass


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
		pass


func stop_music(fade_time: float = 1.0) -> void:
	_current_music = ""
	_music_player.stop()


# ---- SFX --------------------------------------------------------

func play_sfx(path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		_sfx_player.stream = stream
		_sfx_player.play()


# ---- Volume controls --------------------------------------------

func set_ambient_volume(db: float) -> void:
	_ambient_volume = db
	_ambient_player.volume_db = db


func set_music_volume(db: float) -> void:
	_music_volume = db
	_music_player.volume_db = db
