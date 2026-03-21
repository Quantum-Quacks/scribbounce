extends Node
class_name PlayerPhysicsComponent

## Component responsible for duck player physics behavior
##
## Handles movement forces, damping, collisions, and bounce mechanics.
## All physics-related calculations are centralized here.
## IMPORTANT: Velocity modifications happen in _integrate_forces() only.

#### CONSTANTS ####
const MOVE_FORCE_MULTIPLIER: int = 1000

#### EXPORT VARIABLES ####
@export_group("Movement")
@export var move_force: float = 0.75 ## Force applied to the ball when using input controls (aumentado para compensar gravity_scale 1.3)
@export var normal_speed: float = 1000.0 ## Target speed for normal movement
@export var max_speed: float = 4000.0 ## Maximum velocity the player can reach

@export_subgroup("Damping")
@export var damping_factor: float = 0.6 ## Damping applied when exceeding normal_speed (0-1)
@export var horizontal_factor: float = 0.5 ## Horizontal movement correction factor

@export_group("Direction Change Response")
@export var counter_force_bonus: float = 9.0 ## Bonus máximo de fuerza al frenar inercia contraria (9.0 = hasta 10x total)
@export var use_max_speed_as_reference: bool = true ## Usar max_speed como referencia en lugar de reference_speed
@export var reference_speed: float = 1000.0 ## Velocidad de referencia para calcular el ratio de inercia (ignorado si use_max_speed_as_reference = true)
@export var min_velocity_threshold: float = 50.0 ## Velocidad mínima para ignorar micro-ajustes
@export var inertia_response_curve: Curve ## Curva para controlar cómo crece la fuerza (lineal si null)
@export var debug_counter_force: bool = false ## Mostrar debug de multiplicador de fuerza en consola

@export_group("Bounce")
@export var bounce_velocity: float = 1300.0 ## Minimum velocity boost applied on bounce (aumentado de 1000 para compensar gravity_scale 1.3)
@export var bounce_force_factor: float = 0.95 ## Multiplier for speed increment when below bounce_velocity
@export var bounce_floor_angle_max: float = 1.0 ## Max angle (radians) to apply bounce boost on flat surfaces

# Component references
var player: RigidBody2D
var input_component: PlayerInputComponent

# ✅ NUEVO: Variables para modificaciones pendientes de física
var pending_velocity_override: float = -1.0
var should_apply_damping: bool = false
var should_apply_horizontal_correction: bool = true
var cached_input: Vector2 = Vector2.ZERO


func initialize(owner_node: RigidBody2D) -> void:
	if not owner_node:
		push_error("PlayerPhysicsComponent: owner_node is null!")
		return

	player = owner_node
	input_component = player.get_node("InputComponent")

	if not input_component:
		push_error("PlayerPhysicsComponent: InputComponent not found!")


## Main physics processing loop
## ✅ MODIFICADO: Ya no modifica velocidad directamente
func process_physics(_delta: float) -> void:
	# Solo cachear input y marcar flags
	cached_input = input_component.get_input_vector()
	
	# Marcar que se debe aplicar damping si es necesario
	if player.linear_velocity.length() > normal_speed:
		should_apply_damping = true


## ✅ NUEVO: Toda la lógica de física se maneja aquí
func integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 1. Aplicar fuerzas de input
	apply_input_force_internal(state)
	
	# 2. Aplicar corrección horizontal
	if should_apply_horizontal_correction:
		apply_horizontal_correction_internal(state)
	
	# 3. Aplicar damping de velocidad
	if should_apply_damping:
		apply_damping_internal(state)
		should_apply_damping = false
	
	# 4. Aplicar override de velocidad (boost)
	if pending_velocity_override > 0:
		state.linear_velocity = state.linear_velocity.normalized() * pending_velocity_override
		pending_velocity_override = -1.0
	
	# 5. Procesar colisiones y bounce
	process_collisions(state)


## ✅ MODIFICADO: Aplicar fuerzas de input con sistema gradual anti-inercia
func apply_input_force_internal(state: PhysicsDirectBodyState2D) -> void:
	if cached_input.x == 0:
		return  # Sin input horizontal, no aplicar fuerza

	var current_velocity_x: float = state.linear_velocity.x
	var input_direction: float = sign(cached_input.x)

	# Calcular inercia contraria (velocidad en dirección opuesta al input)
	var counter_momentum := 0.0

	if abs(current_velocity_x) > min_velocity_threshold:
		# Si la velocidad y el input tienen signos opuestos, hay inercia contraria
		if sign(current_velocity_x) != input_direction:
			counter_momentum = abs(current_velocity_x)

	# Calcular ratio de inercia (0.0 a 1.0)
	var speed_reference: float = max_speed if use_max_speed_as_reference else reference_speed
	var inertia_ratio: float = clamp(counter_momentum / speed_reference, 0.0, 1.0)

	# Aplicar curva si está configurada, sino usar ratio lineal
	var curve_value: float = inertia_ratio
	if inertia_response_curve:
		curve_value = inertia_response_curve.sample(inertia_ratio)

	# Calcular multiplicador final (1.0 = normal, 1.0 + bonus = máximo)
	var force_multiplier: float = 1.0 + (curve_value * counter_force_bonus)

	# Aplicar fuerza con el multiplicador gradual
	var base_force: Vector2 = cached_input * move_force * MOVE_FORCE_MULTIPLIER
	var final_force: Vector2 = base_force * force_multiplier

	state.apply_force(final_force)

	# Debug opcional
	if debug_counter_force and inertia_ratio > 0.1:
		print("Inercia contraria: %.0f | Ratio: %.2f | Curva: %.2f | Multiplicador: %.2fx" % [counter_momentum, inertia_ratio, curve_value, force_multiplier])


## ✅ NUEVO: Aplicar corrección horizontal dentro de integrate_forces
func apply_horizontal_correction_internal(state: PhysicsDirectBodyState2D) -> void:
	var force_horizontal := -state.linear_velocity.x * horizontal_factor
	state.apply_force(Vector2(force_horizontal, 0))


## ✅ NUEVO: Aplicar damping dentro de integrate_forces
func apply_damping_internal(state: PhysicsDirectBodyState2D) -> void:
	var current_length := state.linear_velocity.length()
	if current_length > normal_speed:
		var clamped_velocity := normal_speed + (current_length - normal_speed) * damping_factor
		state.linear_velocity = state.linear_velocity.normalized() * clamped_velocity


## Processes all collisions and emits appropriate signals
func process_collisions(state: PhysicsDirectBodyState2D) -> void:
	var contact_count := state.get_contact_count()
	
	for i in range(contact_count):
		var contact_point := state.get_contact_local_position(i)
		var collider_object := state.get_contact_collider_object(i)
		var collision_normal := state.get_contact_local_normal(i)
		
		# Get the material of the colliding object
		var collision_material := "default"
		if collider_object and collider_object.has_meta("Material"):
			collision_material = collider_object.get_meta("Material")
		
		# Apply bounce boost if needed
		apply_bounce_boost_internal(state, collision_normal)
		
		# Emit signals
		player.on_hit_material.emit(collision_material, contact_point, collision_normal)
		player.on_hit_floor.emit(contact_point, collision_normal)
		SignalBus.player_bounced.emit(contact_point, collision_normal, state.linear_velocity.length())


## ✅ MODIFICADO: Aplicar bounce boost usando state
func apply_bounce_boost_internal(state: PhysicsDirectBodyState2D, normal: Vector2) -> void:
	var is_flat: bool = abs(normal.angle_to(Vector2.UP)) < bounce_floor_angle_max
	var current_velocity: float = state.linear_velocity.length()
	var need_boost: bool = current_velocity < bounce_velocity
	
	if is_flat and need_boost:
		var boosted_velocity := current_velocity + ((bounce_velocity - current_velocity) * bounce_force_factor)
		state.linear_velocity = state.linear_velocity.normalized() * boosted_velocity


## ✅ MODIFICADO: Marcar boost pendiente en lugar de aplicar directamente
func apply_boost(boost: float) -> void:
	pending_velocity_override = boost
