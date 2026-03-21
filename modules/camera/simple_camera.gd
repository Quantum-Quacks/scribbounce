extends Camera2D
class_name SimpleCamera

@export var target: Node2D
@export var follow_speed: float = 4.0
@export var target_y_ratio: float = 0.35

var _viewport_size: Vector2


func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	if target:
		global_position = Vector2(_viewport_size.x / 2.0, target.global_position.y)


func _process(delta: float) -> void:
	if not target:
		return

	_viewport_size = get_viewport_rect().size
	var desired_y := target.global_position.y - _viewport_size.y * (1.0 - target_y_ratio)

	# Only follow upward
	desired_y = minf(desired_y, global_position.y)

	var new_y := lerpf(global_position.y, desired_y, follow_speed * delta)
	global_position = Vector2(_viewport_size.x / 2.0, new_y)


func is_duck_below_death_line(pos: Vector2) -> bool:
	return pos.y > global_position.y + _viewport_size.y / 2.0 + 300.0
