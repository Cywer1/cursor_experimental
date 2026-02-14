extends Node

const ENEMY_SCENE := preload("res://scenes/enemy.tscn") as PackedScene
const SHOP_SCENE := preload("res://scenes/shop.tscn") as PackedScene
const SPAWN_BOUNDS_MIN := Vector2(100, 100)
const SPAWN_BOUNDS_MAX := Vector2(2540, 1520)
const WAVE_DELAY := 2.5
const WAVE_DURATION := 90.0
const BASE_ENEMIES := 1

var current_wave := 0
var game_over := false
var wave_timer := 0.0
var in_wave_break := false

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var enemies_container: Node2D = get_parent().get_node("Enemies")
@onready var game_over_ui: CanvasLayer = get_parent().get_node("GameOverLayer")
@onready var hud: CanvasLayer = get_parent().get_node("HUDLayer")

var upgrade_manager: Node
var shop_ui: CanvasLayer

func _ready() -> void:
	# #region agent log
	var _log := {"id":"gm_ready","timestamp":int(Time.get_ticks_msec()),"location":"game_manager.gd:_ready","message":"GameManager _ready before _start_next_wave","data":{},"hypothesisId":"H1"}
	var _f := FileAccess.open("res://.cursor/debug.log", FileAccess.READ_WRITE)
	if _f:
		_f.seek_end()
	if _f:
		_f.store_line(JSON.stringify(_log))
		_f.close()
	# #endregion
	player.died.connect(_on_player_died)
	upgrade_manager = Node.new()
	upgrade_manager.set_script(preload("res://scripts/upgrade_manager.gd") as GDScript)
	add_child(upgrade_manager)
	shop_ui = SHOP_SCENE.instantiate() as CanvasLayer
	get_parent().call_deferred("add_child", shop_ui)
	shop_ui.setup(upgrade_manager, player, hud)
	shop_ui.shop_closed.connect(_on_shop_closed)
	call_deferred("_start_next_wave")

func _process(delta: float) -> void:
	if game_over:
		return
	if in_wave_break:
		return
	wave_timer -= delta
	if wave_timer < 0.0:
		wave_timer = 0.0
	hud.set_countdown(wave_timer)

func _start_next_wave() -> void:
	if game_over:
		return
	current_wave += 1
	var count := BASE_ENEMIES + current_wave
	for i in count:
		_spawn_enemy()
	# #region agent log
	var _log := {"id":"gm_set_wave","timestamp":int(Time.get_ticks_msec()),"location":"game_manager.gd:_start_next_wave","message":"About to call hud.set_wave","data":{"current_wave":current_wave},"hypothesisId":"H1"}
	var _f := FileAccess.open("res://.cursor/debug.log", FileAccess.READ_WRITE)
	if _f:
		_f.seek_end()
	if _f:
		_f.store_line(JSON.stringify(_log))
		_f.close()
	# #endregion
	in_wave_break = false
	wave_timer = WAVE_DURATION
	hud.set_wave(current_wave)
	hud.set_enemies_remaining(enemies_container.get_child_count())
	hud.set_countdown(wave_timer)
	await get_tree().create_timer(0.5).timeout
	_check_wave_clear()

func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate() as Node2D
	enemy.global_position = Vector2(
		randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MAX.x),
		randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MAX.y)
	)
	enemies_container.add_child(enemy)

func _check_wave_clear() -> void:
	if game_over:
		return
	await get_tree().create_timer(0.2).timeout
	var enemy_count := enemies_container.get_child_count()
	hud.set_enemies_remaining(enemy_count)
	if enemy_count <= 0 or wave_timer <= 0.0:
		in_wave_break = true
		var remaining := WAVE_DELAY
		hud.show_countdown(remaining)
		while remaining > 0.0 and not game_over:
			await get_tree().create_timer(0.1).timeout
			remaining -= 0.1
			if remaining < 0.0:
				remaining = 0.0
			hud.update_countdown(remaining)
		hud.set_countdown(0.0)
		if not game_over:
			shop_ui.open_shop(get_tree())
	else:
		await get_tree().create_timer(0.5).timeout
		_check_wave_clear()

func _on_shop_closed() -> void:
	_start_next_wave()

func _on_player_died() -> void:
	game_over = true
	game_over_ui.show_game_over()
