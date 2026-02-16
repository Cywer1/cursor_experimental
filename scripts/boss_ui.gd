extends CanvasLayer

@onready var health_bar: ProgressBar = $CenterTop/VBoxContainer/BossHealthBar

func _ready() -> void:
	visible = false

func show_boss_ui(max_hp: float) -> void:
	visible = true
	health_bar.min_value = 0.0
	health_bar.max_value = max_hp
	health_bar.value = max_hp

func update_health(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current

func hide_boss_ui() -> void:
	visible = false
