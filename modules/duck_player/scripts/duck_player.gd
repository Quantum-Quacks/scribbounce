extends RigidBody2D
class_name Player

## Duck Player Controller - Scribbounce version
## Simplified: no PhantomCamera2D, no AudioManager calls, no skin VFX

signal on_hit_material(collision_material: String, contact_point: Vector2, collision_normal: Vector2)
signal on_hit_floor(contact_point: Vector2, collision_normal: Vector2)

@onready var input_component: PlayerInputComponent = $InputComponent
@onready var physics_component: PlayerPhysicsComponent = $PhysicsComponent
@onready var animation_component: PlayerAnimationComponent = $AnimationComponent
@onready var effects_component: PlayerEffectsComponent = $EffectsComponent

@export_group("Appearance")
@export_range(0.05, 2.0, 0.01) var sprite_scale: float = 0.5

@export_group("Physics")
@export_range(0.5, 3.0, 0.1) var custom_gravity_scale: float = 1.3

@export_group("Animation")
@export var flip_follows_input: bool = true

@export_group("Debug")
@export var enable_up_down: bool = false


func _ready() -> void:
	add_to_group("player")
	_setup_components()
	SkinManager.skin_changed.connect(_on_skin_manager_skin_changed)


func _exit_tree() -> void:
	if SkinManager.skin_changed.is_connected(_on_skin_manager_skin_changed):
		SkinManager.skin_changed.disconnect(_on_skin_manager_skin_changed)


func _setup_components() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	gravity_scale = custom_gravity_scale

	input_component.initialize(self)
	input_component.enable_up_down = enable_up_down

	physics_component.initialize(self)
	animation_component.initialize(self, sprite_scale)
	animation_component.flip_follows_input = flip_follows_input
	animation_component.input_component = input_component
	effects_component.initialize(self)

	physics_component.player = self


func _physics_process(delta: float) -> void:
	physics_component.process_physics(delta)


func _process(delta: float) -> void:
	animation_component.process_animation(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	effects_component.process_hitstop()
	physics_component.integrate_forces(state)

	if state.get_contact_count() > 0:
		var collision_normal := state.get_contact_local_normal(0)
		animation_component.animate_bounce(collision_normal)


func apply_boost(boost: float) -> void:
	physics_component.apply_boost(boost)


func is_duck_player() -> bool:
	return true


func disable_control() -> void:
	freeze = true


func enable_control() -> void:
	freeze = false


func _on_skin_manager_skin_changed(_new_skin) -> void:
	pass
