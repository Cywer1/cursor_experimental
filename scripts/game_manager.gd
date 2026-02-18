extends Node

const ENEMY_SCENE := preload("res://scenes/enemy.tscn") as PackedScene
const ENEMY_CHARGER_SCENE := preload("res://scenes/enemy_charger.tscn") as PackedScene
const ENEMY_SHOOTER_SCENE := preload("res://scenes/enemy_shooter.tscn") as PackedScene
const ENEMY_TANK_SCENE := preload("res://scenes/enemy_tank.tscn") as PackedScene
const ENEMY_BOSS_SCENE := preload("res://scenes/enemy_boss.tscn") as PackedScene
const HAZARD_SCENE := preload("res://scenes/hazard.tscn") as PackedScene
const BOSS_UI_SCENE := preload("res://scenes/boss_ui.tscn") as PackedScene
const CRATE_SCENE := preload("res://scenes/crate.tscn") as PackedScene
const BOSS_SCRAP_REWARD := 50
const CRATE_SPAWN_INTERVAL_MIN := 8.0
const CRATE_SPAWN_INTERVAL_MAX := 15.0
const CRATE_SPAWN_SAFE_DISTANCE := 350.0
const CRATE_SPAWN_ATTEMPTS := 20
const CHARGER_SPAWN_CHANCE := 0.2
const SHOOTER_SPAWN_CHANCE := 0.15
const TANK_SPAWN_CHANCE := 0.15
const TANK_WAVE_MIN := 4
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
var boss_active := false

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var enemies_container: Node2D = get_parent().get_node("Enemies")
@onready var game_over_ui: CanvasLayer = get_parent().get_node("GameOverLayer")
@onready var hud: CanvasLayer = get_parent().get_node("HUDLayer")

@onready var hazards_container: Node2D = $"../Hazards"

var upgrade_manager: Node
var crates_container: Node2D
var _crate_spawn_timer := 0.0
var shop_ui: CanvasLayer
var boss_ui: CanvasLayer

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
	var hazards_node := get_parent().get_node_or_null("Hazards")
	if hazards_node == null:
		hazards_node = Node2D.new()
		hazards_node.name = "Hazards"
		get_parent().add_child(hazards_node)
	hazards_container = hazards_node
	var crates_node := get_parent().get_node_or_null("Crates")
	if crates_node == null:
		crates_node = Node2D.new()
		crates_node.name = "Crates"
		get_parent().call_deferred("add_child", crates_node)
	crates_container = crates_node
	_crate_spawn_timer = randf_range(CRATE_SPAWN_INTERVAL_MIN, CRATE_SPAWN_INTERVAL_MAX)
	boss_ui = BOSS_UI_SCENE.instantiate() as CanvasLayer
	get_parent().call_deferred("add_child", boss_ui)
	call_deferred("_start_next_wave")

func _process(delta: float) -> void:
	if game_over:
		return
	if in_wave_break:
		return
	if boss_active:
		return
	wave_timer -= delta
	if crates_container != null:
		_crate_spawn_timer -= delta
		if _crate_spawn_timer <= 0.0:
			_crate_spawn_timer = randf_range(CRATE_SPAWN_INTERVAL_MIN, CRATE_SPAWN_INTERVAL_MAX)
			_spawn_crate()
	if wave_timer < 0.0:
		wave_timer = 0.0
	hud.set_countdown(wave_timer)

func _start_next_wave() -> void:
	if game_over:
		return
	current_wave += 1
	_spawn_hazards_for_wave(current_wave)
	var is_boss_wave := current_wave % 10 == 0
	if is_boss_wave:
		boss_active = true
		var tier: int = int(current_wave / 10)
		_spawn_boss(tier)
	else:
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
	hud.set_enemies_remaining(_get_enemy_count())
	hud.set_countdown(wave_timer)
	await get_tree().create_timer(0.5).timeout
	_check_wave_clear()

const SPAWN_SAFE_DISTANCE := 400.0
const SPAWN_HAZARD_MIN_DISTANCE := 50.0
const SPAWN_SAFE_ATTEMPTS := 10
const HAZARD_BASE_COUNT := 2
const HAZARD_PLAYER_MIN_DISTANCE := 300.0
const HAZARD_MIN_SPACING := 80.0
const HAZARD_SPAWN_ATTEMPTS := 30

func _get_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()

func _spawn_boss(tier: int) -> void:
	var boss: Node2D = ENEMY_BOSS_SCENE.instantiate() as Node2D
	boss.tier = tier
	var pos: Vector2
	for attempt in SPAWN_SAFE_ATTEMPTS:
		pos = Vector2(
			randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MAX.x),
			randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MAX.y)
		)
		if pos.distance_to(player.global_position) < SPAWN_SAFE_DISTANCE:
			continue
		if _is_pos_near_hazard(pos):
			continue
		break
	boss.global_position = pos
	enemies_container.add_child(boss)
	boss.boss_health_changed.connect(_on_boss_health_changed)
	boss.boss_died.connect(_on_boss_died)
	boss_ui.show_boss_ui(boss.max_health)

func _on_boss_health_changed(current: float, max_hp: float) -> void:
	boss_ui.update_health(current, max_hp)

func _on_boss_died() -> void:
	player.add_currency(BOSS_SCRAP_REWARD)
	boss_ui.hide_boss_ui()
	boss_active = false
	_start_wave_break()

func _spawn_enemy() -> void:
	var use_tank := current_wave >= TANK_WAVE_MIN and randf() < TANK_SPAWN_CHANCE
	var use_shooter := current_wave >= 3 and randf() < SHOOTER_SPAWN_CHANCE
	var use_charger := current_wave >= 2 and randf() < CHARGER_SPAWN_CHANCE
	var scene: PackedScene = ENEMY_SCENE
	if use_tank:
		scene = ENEMY_TANK_SCENE
	elif use_shooter:
		scene = ENEMY_SHOOTER_SCENE
	elif use_charger:
		scene = ENEMY_CHARGER_SCENE
	var enemy: Node2D = scene.instantiate() as Node2D
	var pos: Vector2
	for attempt in SPAWN_SAFE_ATTEMPTS:
		pos = Vector2(
			randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MAX.x),
			randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MAX.y)
		)
		if pos.distance_to(player.global_position) < SPAWN_SAFE_DISTANCE:
			continue
		if _is_pos_near_hazard(pos):
			continue
		break
	enemy.global_position = pos
	enemies_container.add_child(enemy)

func _spawn_crate() -> void:
	if crates_container == null:
		return
	var center_x := (SPAWN_BOUNDS_MIN.x + SPAWN_BOUNDS_MAX.x) * 0.5
	var center_y := (SPAWN_BOUNDS_MIN.y + SPAWN_BOUNDS_MAX.y) * 0.5
	var pos: Vector2
	for attempt in CRATE_SPAWN_ATTEMPTS:
		var zone := randi() % 5
		match zone:
			0:
				pos = Vector2(randf_range(center_x - 400, center_x + 400), randf_range(center_y - 300, center_y + 300))
			1:
				pos = Vector2(randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MIN.x + 400), randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MIN.y + 300))
			2:
				pos = Vector2(randf_range(SPAWN_BOUNDS_MAX.x - 400, SPAWN_BOUNDS_MAX.x), randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MIN.y + 300))
			3:
				pos = Vector2(randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MIN.x + 400), randf_range(SPAWN_BOUNDS_MAX.y - 300, SPAWN_BOUNDS_MAX.y))
			_:
				pos = Vector2(randf_range(SPAWN_BOUNDS_MAX.x - 400, SPAWN_BOUNDS_MAX.x), randf_range(SPAWN_BOUNDS_MAX.y - 300, SPAWN_BOUNDS_MAX.y))
		if pos.distance_to(player.global_position) >= CRATE_SPAWN_SAFE_DISTANCE and not _is_pos_near_hazard(pos):
			break
	var crate := CRATE_SCENE.instantiate() as Node2D
	crate.global_position = pos
	crates_container.add_child(crate)

func _is_pos_near_hazard(pos: Vector2) -> bool:
	for hazard in get_tree().get_nodes_in_group("hazards"):
		var node := hazard as Node2D
		if node != null and pos.distance_to(node.global_position) < SPAWN_HAZARD_MIN_DISTANCE:
			return true
	return false

func _spawn_hazards_for_wave(wave_index: int) -> void:
	if hazards_container == null:
		return
	for child in hazards_container.get_children():
		child.queue_free()
	var hazard_count := HAZARD_BASE_COUNT + int(wave_index / 2)
	for i in hazard_count:
		var pos: Vector2
		for attempt in HAZARD_SPAWN_ATTEMPTS:
			pos = Vector2(
				randf_range(SPAWN_BOUNDS_MIN.x, SPAWN_BOUNDS_MAX.x),
				randf_range(SPAWN_BOUNDS_MIN.y, SPAWN_BOUNDS_MAX.y)
			)
			if pos.distance_to(player.global_position) < HAZARD_PLAYER_MIN_DISTANCE:
				continue
			var too_near := false
			for existing in hazards_container.get_children():
				var node := existing as Node2D
				if node != null and pos.distance_to(node.global_position) < HAZARD_MIN_SPACING:
					too_near = true
					break
			if not too_near:
				break
		var hazard := HAZARD_SCENE.instantiate() as Node2D
		hazard.add_to_group("hazards")
		hazards_container.add_child(hazard)
		hazard.global_position = pos

func _start_wave_break() -> void:
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

func _check_wave_clear() -> void:
	if game_over:
		return
	await get_tree().create_timer(0.2).timeout
	var enemy_count := _get_enemy_count()
	hud.set_enemies_remaining(enemy_count)
	if enemy_count <= 0 or wave_timer <= 0.0:
		_start_wave_break()
	else:
		await get_tree().create_timer(0.5).timeout
		_check_wave_clear()

func _on_shop_closed() -> void:
	_start_next_wave()

func _on_player_died() -> void:
	game_over = true
	game_over_ui.show_game_over()
