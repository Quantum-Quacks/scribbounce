extends Node
class_name PlayerAnimationComponent

const SQUASH_SCALE: Vector2 = Vector2(1.4, 0.5)
const MAX_TILT_ANGLE: float = deg_to_rad(35.0)

@export_group("Tilt")
@export var tilt_speed: float = 5.0
@export var tilt_threshold: float = 100.0

var player: RigidBody2D
var skins: Node2D
var skins_base_scale: Vector2
var physics_component: PlayerPhysicsComponent

var current_tilt: float = 0.0
var base_scale: float = 0.5

var _is_bounce_animating: bool = false
var _bounce_time: float = 0.0
const BOUNCE_DURATION: float = 0.15


func initialize(owner_node: RigidBody2D, base_sprite_scale: float = 0.5) -> void:
	player = owner_node
	skins = player.get_node("%Skins")
	base_scale = base_sprite_scale
	skins_base_scale = Vector2(base_scale, base_scale)
	skins.scale = skins_base_scale
	physics_component = player.get_node("PhysicsComponent")


func animate_bounce(_normal: Vector2) -> void:
	_apply_bounce_squash()


func process_animation(delta: float) -> void:
	_update_bounce_animation(delta)
	_scale_based_on_velocity()
	_tilt_based_on_movement(delta)
	_update_sprite_flip()


func _update_sprite_flip() -> void:
	var vx: float = player.linear_velocity.x
	if absf(vx) > 50.0:
		skins.flip_h = vx > 0.0


func _tilt_based_on_movement(delta: float) -> void:
	if _is_bounce_animating:
		return
	var vx: float = player.linear_velocity.x
	var target_tilt: float = 0.0
	if absf(vx) > tilt_threshold:
		var norm: float = clampf(vx / physics_component.normal_speed, -1.0, 1.0)
		target_tilt = norm * MAX_TILT_ANGLE
	current_tilt = lerpf(current_tilt, target_tilt, tilt_speed * delta)
	skins.rotation = current_tilt


func _scale_based_on_velocity() -> void:
	if _is_bounce_animating:
		return
	var t: float = clampf(player.linear_velocity.length() / physics_component.max_speed, 0.0, 1.0)
	skins.scale = skins_base_scale.lerp(skins_base_scale * SQUASH_SCALE, t)


func _apply_bounce_squash() -> void:
	_is_bounce_animating = true
	_bounce_time = 0.0


func _update_bounce_animation(delta: float) -> void:
	if not _is_bounce_animating:
		return
	_bounce_time += delta
	if _bounce_time >= BOUNCE_DURATION:
		_is_bounce_animating = false
		skins.scale = skins_base_scale
		return
	var progress: float = _bounce_time / BOUNCE_DURATION
	var squashed: Vector2 = Vector2(base_scale * 0.66, base_scale * 1.46)
	if progress < 0.4:
		skins.scale = skins_base_scale.lerp(squashed, progress / 0.4)
	else:
		skins.scale = squashed.lerp(skins_base_scale, ease((progress - 0.4) / 0.6, -2.0))


func update_base_scale(new_scale: float) -> void:
	base_scale = new_scale
	skins_base_scale = Vector2(base_scale, base_scale)
	if not _is_bounce_animating:
		skins.scale = skins_base_scale
