extends CanvasLayer

@onready var wave_label: Label = $VBoxContainer/WaveLabel
@onready var enemies_label: Label = $VBoxContainer/EnemiesLabel
@onready var countdown_label: Label = $VBoxContainer/CountdownLabel
@onready var player_health_bar: ProgressBar = $VBoxContainer/PlayerHealthBar
@onready var player_stamina_bar: ProgressBar = $VBoxContainer/PlayerStaminaBar

var _player: CharacterBody2D

func _ready() -> void:
	set_countdown(0.0)
	_player = get_parent().get_node("Player")
	_player.health_changed.connect(set_player_health)
	call_deferred("set_player_health", _player.health, _player.HEALTH_MAX)

func _process(_delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		player_stamina_bar.max_value = _player.STAMINA_MAX
		player_stamina_bar.value = _player.stamina
	# #region agent log
	var _log := {"id":"hud_ready","timestamp":int(Time.get_ticks_msec()),"location":"hud.gd:_ready","message":"HUD _ready","data":{"wave_label_is_null":wave_label == null,"enemies_label_is_null":enemies_label == null},"hypothesisId":"H1"}
	var _f := FileAccess.open("res://.cursor/debug.log", FileAccess.READ_WRITE)
	if _f:
		_f.seek_end()
	if _f:
		_f.store_line(JSON.stringify(_log))
		_f.close()
	# #endregion

func set_wave(n: int) -> void:
	# #region agent log
	var _log := {"id":"hud_set_wave","timestamp":int(Time.get_ticks_msec()),"location":"hud.gd:set_wave","message":"set_wave called","data":{"n":n,"wave_label_is_null":wave_label == null},"hypothesisId":"H1"}
	var _f := FileAccess.open("res://.cursor/debug.log", FileAccess.READ_WRITE)
	if _f:
		_f.seek_end()
	if _f:
		_f.store_line(JSON.stringify(_log))
		_f.close()
	# #endregion
	wave_label.text = "Wave: %d" % n

func set_enemies_remaining(n: int) -> void:
	enemies_label.text = "Enemies: %d" % n

func set_player_health(current: float, max_val: float) -> void:
	player_health_bar.max_value = max_val
	player_health_bar.value = current

func set_countdown(seconds: float) -> void:
	countdown_label.text = "Next wave in: %.1fs" % seconds

func show_countdown(seconds: float) -> void:
	countdown_label.text = "Next wave in: %.1fs" % seconds

func update_countdown(remaining_seconds: float) -> void:
	countdown_label.text = "Next wave in: %.1fs" % remaining_seconds

func hide_countdown() -> void:
	countdown_label.text = "Next wave in: %.1fs" % 0.0
