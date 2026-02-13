extends Node2D

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 4.0

var _last_health := -1.0

func _process(_delta: float) -> void:
	var enemy := get_parent()
	if not "health" in enemy or not "MAX_HEALTH" in enemy:
		return
	var current: float = enemy.health
	if current != _last_health:
		_last_health = current
		queue_redraw()

func _draw() -> void:
	var enemy := get_parent()
	if not "health" in enemy or not "MAX_HEALTH" in enemy:
		return
	var h: float = enemy.health
	var max_h: float = enemy.MAX_HEALTH
	var ratio := clampf(h / max_h, 0.0, 1.0) if max_h > 0.0 else 0.0

	var bg_rect := Rect2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(bg_rect, Color(0.2, 0.2, 0.2))

	var fill_width := BAR_WIDTH * ratio
	if fill_width > 0.0:
		var fill_rect := Rect2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0, fill_width, BAR_HEIGHT)
		draw_rect(fill_rect, Color(1, 0, 0))
