extends CanvasLayer

signal shop_closed

@onready var container: HBoxContainer = _find_container()
@onready var close_button: Button = _find_close_button()
@onready var scrap_label: Label = _find_scrap_label()

func _find_container() -> HBoxContainer:
	for path in ["UpgradeContainer", "Panel/UpgradeContainer", "Panel/CenterContainer/VBoxContainer/UpgradeContainer", "Panel/CenterContainer/UpgradeContainer"]:
		var n := get_node_or_null(path) as HBoxContainer
		if n:
			return n
	return null

func _find_close_button() -> Button:
	for path in ["CloseButton", "Panel/CloseButton", "Panel/CenterContainer/VBoxContainer/CloseButton"]:
		var n := get_node_or_null(path) as Button
		if n:
			return n
	return null

func _find_scrap_label() -> Label:
	for path in ["ScrapLabel", "Panel/ScrapLabel", "Panel/CenterContainer/VBoxContainer/ScrapLabel"]:
		var n := get_node_or_null(path) as Label
		if n:
			return n
	return null

func _update_scrap_label() -> void:
	if scrap_label and _player:
		scrap_label.text = "Scrap: %d" % _player.currency

var _upgrade_manager: Node
var _player: CharacterBody2D
var _hud: CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func setup(upgrade_manager: Node, player: CharacterBody2D, hud: CanvasLayer) -> void:
	_upgrade_manager = upgrade_manager
	_player = player
	_hud = hud

func open_shop(tree: SceneTree = null) -> void:
	var t := tree if tree else (_player.get_tree() if _player else get_tree())
	if t:
		t.paused = true
	show()
	_update_scrap_label()
	if container == null:
		push_error("ShopUI: No upgrade container found. Add an HBoxContainer named 'UpgradeContainer' to your shop scene.")
		return
	for child in container.get_children():
		child.queue_free()
	var upgrades: Array = _upgrade_manager.get_random_upgrades(3)
	for upgrade: Dictionary in upgrades:
		var btn := Button.new()
		btn.text = "%s\nCost: %d scraps\n%s" % [upgrade.name, upgrade.cost, upgrade.description]
		btn.custom_minimum_size = Vector2(180, 80)
		btn.pressed.connect(_buy_upgrade.bind(upgrade))
		container.add_child(btn)

func _buy_upgrade(upgrade: Dictionary) -> void:
	var cost: int = upgrade.cost
	if _player.currency < cost:
		return
	_player.currency -= cost
	_player.currency_changed.emit(_player.currency)
	_update_scrap_label()
	_apply_effect(upgrade)
	_close_shop()

func _apply_effect(upgrade: Dictionary) -> void:
	var effect_type: String = upgrade.effect_type
	var value: float = upgrade.effect_value
	match effect_type:
		"Health":
			_player.health = minf(_player.health + value, _player.health_max)
			_player.health_changed.emit(_player.health, _player.health_max)
		"Damage":
			_player.dash_damage += value
		"Speed":
			_player.speed += value
		"Stamina":
			_player.stamina_max += value
			_player.stamina = minf(_player.stamina, _player.stamina_max)

func _on_close_pressed() -> void:
	_close_shop()

func _close_shop() -> void:
	var t := _player.get_tree() if _player else get_tree()
	if t:
		t.paused = false
	hide()
	shop_closed.emit()
