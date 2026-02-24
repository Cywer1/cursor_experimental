extends CanvasLayer

signal shop_closed

const TEXTURE_PANEL_NORMAL := preload("res://assets/sprites/UI/UI_Panel_Normal.png")
const TEXTURE_PANEL_DISABLED := preload("res://assets/sprites/UI/UI_Panel_Disabled.png")

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

func _update_button_affordability() -> void:
	if container == null or _player == null:
		return
	for child in container.get_children():
		var btn := child as Button
		if btn == null or btn.text == "SOLD":
			continue
		if not btn.has_meta("upgrade"):
			continue
		var upgrade: Dictionary = btn.get_meta("upgrade")
		var cost: int = upgrade.cost
		if _player.currency < cost:
			btn.disabled = true
		else:
			btn.disabled = false

var _upgrade_manager: Node
var _player: CharacterBody2D
var _hud: CanvasLayer

func _apply_button_style(btn: Button) -> void:
	var style_normal := StyleBoxTexture.new()
	style_normal.texture = TEXTURE_PANEL_NORMAL

	var style_hover := StyleBoxTexture.new()
	style_hover.texture = TEXTURE_PANEL_NORMAL

	var style_pressed := StyleBoxTexture.new()
	style_pressed.texture = TEXTURE_PANEL_NORMAL

	var style_disabled := StyleBoxTexture.new()
	style_disabled.texture = TEXTURE_PANEL_DISABLED

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_try_buy_at_index(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_try_buy_at_index(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_try_buy_at_index(2)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

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
	var upgrades: Array = _upgrade_manager.get_random_upgrades(3, _player)
	var new_buttons: Array[Button] = []
	for upgrade: Dictionary in upgrades:
		var btn := Button.new()
		btn.set_meta("upgrade", upgrade)
		btn.text = "%s\n%s\nCost: %d" % [upgrade.name, upgrade.description, upgrade.cost]
		btn.custom_minimum_size = Vector2(180, 80)
		_apply_button_style(btn)
		var cost: int = upgrade.cost
		if _player.currency < cost:
			btn.disabled = true
		btn.pressed.connect(_buy_upgrade.bind(upgrade, btn))
		container.add_child(btn)
		new_buttons.append(btn)
	if new_buttons.size() > 0:
		for btn in new_buttons:
			btn.focus_neighbor_bottom = btn.get_path_to(close_button)
		close_button.focus_neighbor_top = close_button.get_path_to(new_buttons[0])
		new_buttons[0].grab_focus()
	else:
		close_button.grab_focus()

func _try_buy_at_index(index: int) -> void:
	if container == null:
		return
	var children := container.get_children()
	if index < 0 or index >= children.size():
		return
	var btn := children[index] as Button
	if btn == null or btn.disabled or not btn.has_meta("upgrade"):
		return
	var upgrade: Dictionary = btn.get_meta("upgrade")
	_buy_upgrade(upgrade, btn)

func _buy_upgrade(upgrade: Dictionary, button: Button) -> void:
	var cost: int = upgrade.cost
	if _player.currency < cost:
		return
	_player.currency -= cost
	_player.currency_changed.emit(_player.currency)
	_update_scrap_label()
	_apply_effect(upgrade)
	button.disabled = true
	button.text = "SOLD"
	_update_button_affordability()
	var refocused := false
	for child in container.get_children():
		var btn := child as Button
		if btn != null and not btn.disabled:
			btn.grab_focus()
			refocused = true
			break
	if not refocused:
		close_button.grab_focus()

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
		"Knockback":
			_player.dash_knockback_strength += value
		"Regen":
			_player.stamina_regen_per_sec += value
		"Explosive":
			_player.explosive_chance += value
		"Vampire":
			_player.vampire_chance += value
		"Thorns":
			_player.thorns_damage += value

func _on_close_pressed() -> void:
	_close_shop()

func _close_shop() -> void:
	var t := _player.get_tree() if _player else get_tree()
	if t:
		t.paused = false
	hide()
	shop_closed.emit()
