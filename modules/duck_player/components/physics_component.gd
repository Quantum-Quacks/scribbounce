extends Node
class_name PlayerPhysicsComponent

## Pure bounce physics — no input, no horizontal correction.
## Duck keeps all momentum from collisions and walls.

@export_group("Bounce")
@export var bounce_velocity: float = 1300.0
@export var bounce_force_factor: float = 0.95
@export var bounce_floor_angle_max: float = 1.0

@export_group("Speed")
@export var normal_speed: float = 1000.0
@export var max_speed: float = 4000.0
@export var damping_factor: float = 0.6

var player: RigidBody2D
var pending_velocity_override: float = -1.0


func initialize(owner_node: RigidBody2D) -> void:
	player = owner_node


func process_physics(_delta: float) -> void:
	pass


func integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Cap speed
	var speed := state.linear_velocity.length()
	if speed > normal_speed:
		var clamped := normal_speed + (speed - normal_speed) * damping_factor
		state.linear_velocity = state.linear_velocity.normalized() * clamped

	# Apply boost if queued
	if pending_velocity_override > 0.0:
		state.linear_velocity = state.linear_velocity.normalized() * pending_velocity_override
		pending_velocity_override = -1.0

	process_collisions(state)


func process_collisions(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var contact_point := state.get_contact_local_position(i)
		var collider_object := state.get_contact_collider_object(i)
		var collision_normal := state.get_contact_local_normal(i)

		var collision_material := "default"
		if collider_object and collider_object.has_meta("Material"):
			collision_material = collider_object.get_meta("Material")

		apply_bounce_boost_internal(state, collision_normal)
		player.on_hit_material.emit(collision_material, contact_point, collision_normal)
		player.on_hit_floor.emit(contact_point, collision_normal)
		SignalBus.player_bounced.emit(contact_point, collision_normal, state.linear_velocity.length())


func apply_bounce_boost_internal(state: PhysicsDirectBodyState2D, normal: Vector2) -> void:
	var is_flat: bool = absf(normal.angle_to(Vector2.UP)) < bounce_floor_angle_max
	var current_speed: float = state.linear_velocity.length()
	if is_flat and current_speed < bounce_velocity:
		var boosted := current_speed + (bounce_velocity - current_speed) * bounce_force_factor
		state.linear_velocity = state.linear_velocity.normalized() * boosted


func apply_boost(boost: float) -> void:
	pending_velocity_override = boost
