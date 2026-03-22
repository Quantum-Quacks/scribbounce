extends RigidBody2D
class_name Player

signal on_hit_material(collision_material: String, contact_point: Vector2, collision_normal: Vector2)
signal on_hit_floor(contact_point: Vector2, collision_normal: Vector2)

@onready var physics_component: PlayerPhysicsComponent = $PhysicsComponent
@onready var animation_component: PlayerAnimationComponent = $AnimationComponent
@onready var effects_component: PlayerEffectsComponent = $EffectsComponent

@export_group("Physics")
@export_range(0.5, 3.0, 0.1) var custom_gravity_scale: float = 1.3

@export_group("Appearance")
@export_range(0.05, 2.0, 0.01) var sprite_scale: float = 0.5


func _ready() -> void:
	add_to_group("player")
	contact_monitor = true
	max_contacts_reported = 10
	gravity_scale = custom_gravity_scale

	physics_component.initialize(self)
	animation_component.initialize(self, sprite_scale)
	effects_component.initialize(self)


func _process(delta: float) -> void:
	animation_component.process_animation(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	effects_component.process_hitstop()
	physics_component.integrate_forces(state)

	if state.get_contact_count() > 0:
		animation_component.animate_bounce(state.get_contact_local_normal(0))


func apply_boost(boost: float) -> void:
	physics_component.apply_boost(boost)


func is_duck_player() -> bool:
	return true


func disable_control() -> void:
	freeze = true


func enable_control() -> void:
	freeze = false
