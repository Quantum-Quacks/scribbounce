extends Node
class_name PlayerEffectsComponent

## Component responsible for duck player special effects
##
## Handles hitstop/time freeze effects, trail recording, and other
## special gameplay effects that enhance player feedback.

#### CONSTANTS ####
const HITSTOP_BOUNCE_FRAMES: int = 1
const HITSTOP_TIME_SCALE: float = 0.1

# Component references
var player: RigidBody2D
var trail_recorder: Node

# Runtime variables
var hitstop_duration: int = 0


func initialize(owner_node: RigidBody2D) -> void:
	player = owner_node
	trail_recorder = player.get_node_or_null("%TrailRecorder")


## Process hitstop effect during physics integration
func process_hitstop() -> void:
	if hitstop_duration > 0:
		hitstop_duration -= 1
	else:
		stop_hitstop()


## Starts hitstop effect for the specified number of frames
## Note: Hitstop feature is currently disabled but infrastructure kept for future use
func start_hitstop(hitstop_amount: int) -> void:
	hitstop_duration = hitstop_amount
	Engine.time_scale = HITSTOP_TIME_SCALE


## Stops the hitstop effect and restores normal time scale
func stop_hitstop() -> void:
	hitstop_duration = 0
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0


## Saves the player's trail and returns the trail data
func save_trail() -> String:
	if trail_recorder:
		return trail_recorder.save_trail()
	push_warning("PlayerEffectsComponent: TrailRecorder not found")
	return ""
