extends Node2D
class_name Spike

func _ready() -> void:
	var kill_area := $Kill as Area2D
	if kill_area:
		kill_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.player_died.emit(body.global_position)
