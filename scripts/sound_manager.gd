extends Node

const num_players := 12
const bus_name := "Master"

var available_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _busy_callables: Dictionary = {}

func _ready() -> void:
	for i in num_players:
		var p := AudioStreamPlayer.new()
		p.bus = bus_name
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		available_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = bus_name
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = null
	if available_players.is_empty():
		return
	p = available_players.pop_back()
	var c := _on_sfx_finished.bind(p)
	_busy_callables[p] = c
	p.finished.connect(c)
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.play()

func _on_sfx_finished(player_ref: AudioStreamPlayer) -> void:
	if _busy_callables.has(player_ref):
		player_ref.finished.disconnect(_busy_callables[player_ref])
		_busy_callables.erase(player_ref)
	available_players.append(player_ref)

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
