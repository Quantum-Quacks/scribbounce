@tool
class_name DuckEffectBase
extends Resource

## Base class for duck player particle effects
##
## Subclasses define specific effect behaviors (bananas, stars, trails, etc.)
## Each effect can be configured and instantiated by the Player

@export var effect_name: String = "Effect":
	set(value):
		effect_name = value
		emit_changed()

@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_range(0.0, 1000.0, 10.0) var spawn_speed_threshold: float = 150.0:
	set(value):
		spawn_speed_threshold = value
		emit_changed()

## If true, update_effect() is called every frame
## Set to false for static effects (auras, glows) to improve performance
@export var requires_constant_update: bool = true:
	set(value):
		requires_constant_update = value
		emit_changed()



## Creates and returns the effect node
## Must be implemented by subclasses
func create_effect_node() -> Node2D:
	push_error("DuckEffectBase.create_effect_node() must be implemented by subclass")
	return null


## Called when effect should start/enable
## Override for custom behavior
func on_effect_enabled(_effect_node: Node2D) -> void:
	pass


## Called when effect should stop/disable
## Override for custom behavior
func on_effect_disabled(_effect_node: Node2D) -> void:
	pass


## Called each frame to update effect based on player state
## Override for custom behavior
func update_effect(_effect_node: Node2D, _delta: float, _player: RigidBody2D) -> void:
	pass

