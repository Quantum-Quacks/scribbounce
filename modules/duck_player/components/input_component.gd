extends Node
class_name PlayerInputComponent

var player: RigidBody2D
var enable_up_down: bool = false

func initialize(owner_node: RigidBody2D) -> void:
	player = owner_node

func get_input_vector() -> Vector2:
	return Vector2.ZERO

func is_reset_pressed() -> bool:
	return false
