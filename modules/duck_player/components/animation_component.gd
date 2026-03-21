extends Node
class_name PlayerAnimationComponent

## Component responsible for player visual animations
##
## Handles tilt/lean animations, scaling, and bounce animations based on player state
## and velocity. Unlike the ball player, the duck does not rotate freely, instead
## it leans forward/backward based on movement direction (max 35°).

#### CONSTANTS ####
const SQUASH_SCALE: Vector2 = Vector2(1.4, 0.5)
const MAX_TILT_ANGLE: float = deg_to_rad(35.0) ## Maximum tilt angle in radians (35 degrees)

#### EXPORT VARIABLES ####
@export_group("Tilt")
@export var tilt_speed: float = 5.0 ## How fast the duck tilts towards target angle
@export var tilt_threshold: float = 100.0 ## Minimum velocity to start tilting

# Component references
var player: RigidBody2D
var animation_player: AnimationPlayer
var skins: Node2D
var skins_base_scale: Vector2
var input_component: PlayerInputComponent

# Configuration
var flip_follows_input: bool = true ## Flip based on input direction instead of velocity

# Runtime variables
var current_tilt: float = 0.0
var base_scale: float = 0.5 ## Base scale set from Player export parameter

# Physics component reference for speed values
var physics_component: PlayerPhysicsComponent


func initialize(owner_node: RigidBody2D, base_sprite_scale: float = 0.5) -> void:
	player = owner_node
	animation_player = player.get_node_or_null("%AnimationPlayer")
	skins = player.get_node("%Skins")
	base_scale = base_sprite_scale

	# Set initial scale based on parameter
	skins_base_scale = Vector2(base_scale, base_scale)
	skins.scale = skins_base_scale

	physics_component = player.get_node("PhysicsComponent")


## Play bounce animation aligned with collision normal
func animate_bounce(_normal: Vector2) -> void:
	# Don't use AnimationPlayer, do it programmatically
	# NOTE: No rotation - only apply squash effect
	# skins.rotation = normal.angle() # REMOVED: Caused incorrect 90° rotation

	# Apply squash effect programmatically
	_apply_bounce_squash()


## Dynamically scales the duck based on velocity (squash and stretch)
func _scale_based_on_velocity() -> void:
	# Skip if bounce animation is running
	if _is_bounce_animating:
		return

	var lerp_speed: float = player.linear_velocity.length() / physics_component.max_speed
	lerp_speed = clamp(lerp_speed, 0.0, 1.0)

	var scale_vector: Vector2 = lerp(skins_base_scale, skins_base_scale * SQUASH_SCALE, lerp_speed)
	skins.scale = scale_vector


## Flips the sprite horizontally based on movement direction
## flip_h = true when moving right, flip_h = false when moving left
func _update_sprite_flip() -> void:
	if flip_follows_input and input_component:
		var input_dir: float = input_component.get_input_vector().x
		if input_dir > 0.0:
			skins.flip_h = true
		elif input_dir < 0.0:
			skins.flip_h = false
	else:
		var horizontal_velocity: float = player.linear_velocity.x
		if abs(horizontal_velocity) > 50.0:
			skins.flip_h = horizontal_velocity > 0.0


## Tilts the duck forward/backward based on horizontal movement direction
## Duck leans forward when moving right, backward when moving left
func _tilt_based_on_movement(delta: float) -> void:
	# Don't override rotation during bounce animation
	if _is_bounce_animating:
		return

	# Calculate target tilt based on horizontal velocity
	var horizontal_velocity: float = player.linear_velocity.x
	var target_tilt: float = 0.0

	# Only tilt if moving fast enough
	if abs(horizontal_velocity) > tilt_threshold:
		# Normalize velocity to -1..1 range
		var normalized_velocity: float = clamp(horizontal_velocity / physics_component.normal_speed, -1.0, 1.0)
		# Map to tilt angle (-MAX_TILT_ANGLE to MAX_TILT_ANGLE)
		target_tilt = normalized_velocity * MAX_TILT_ANGLE

	# Smoothly interpolate current tilt to target tilt
	current_tilt = lerp(current_tilt, target_tilt, tilt_speed * delta)

	# Apply tilt rotation to skins
	skins.rotation = current_tilt


#### PROGRAMMATIC BOUNCE ANIMATION ####

var _is_bounce_animating: bool = false
var _bounce_time: float = 0.0
const BOUNCE_DURATION: float = 0.15

## Apply bounce squash effect programmatically (scales with base_scale)
func _apply_bounce_squash() -> void:
	_is_bounce_animating = true
	_bounce_time = 0.0


## Update bounce animation if active
func _update_bounce_animation(delta: float) -> void:
	if not _is_bounce_animating:
		return

	_bounce_time += delta

	if _bounce_time >= BOUNCE_DURATION:
		# Animation complete, reset
		_is_bounce_animating = false
		skins.scale = skins_base_scale
		return

	# Calculate animation progress (0.0 to 1.0)
	var progress: float = _bounce_time / BOUNCE_DURATION

	# Define keyframes: start (0.0) -> squash (0.4) -> end (1.0)
	var scale_value: Vector2
	if progress < 0.4:
		# First part: normal -> squashed (0.0 to 0.4)
		var t: float = progress / 0.4
		var squashed_scale: Vector2 = Vector2(base_scale * 0.66, base_scale * 1.46) # Squash proportions
		scale_value = skins_base_scale.lerp(squashed_scale, t)
	else:
		# Second part: squashed -> normal (0.4 to 1.0)
		var t: float = (progress - 0.4) / 0.6
		# Apply easing for smooth return
		t = ease(t, -2.0) # Exponential ease out
		var squashed_scale: Vector2 = Vector2(base_scale * 0.66, base_scale * 1.46)
		scale_value = squashed_scale.lerp(skins_base_scale, t)

	skins.scale = scale_value


## Override process_animation to include bounce animation updates
func process_animation(delta: float) -> void:
	_update_bounce_animation(delta)
	_scale_based_on_velocity()
	_tilt_based_on_movement(delta)
	_update_sprite_flip()


## Update base scale dynamically (called when sprite_scale changes in editor)
func update_base_scale(new_scale: float) -> void:
	base_scale = new_scale
	skins_base_scale = Vector2(base_scale, base_scale)

	# Only update sprite scale if not animating
	if not _is_bounce_animating:
		skins.scale = skins_base_scale
