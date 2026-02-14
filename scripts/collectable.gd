extends Area2D

const VALUE := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and "add_currency" in body:
		body.add_currency(VALUE)
		queue_free()
