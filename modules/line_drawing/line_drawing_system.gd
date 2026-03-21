extends Node2D
class_name LineDrawingSystem

signal ink_changed(current: float, max_ink: float)

const INK_MAX: float = 800.0
const INK_REGEN: float = 120.0
const MAX_LINES: int = 2
const LINE_LIFETIME: float = 8.0
const MIN_LEN: float = 30.0

@export var world_node: Node2D

var _ink: float = INK_MAX
var _drawing: bool = false
var _start_world: Vector2 = Vector2.ZERO
var _preview: Line2D
var _active_lines: int = 0


func _ready() -> void:
	_preview = Line2D.new()
	_preview.width = 18.0
	_preview.default_color = Color(0.3, 0.3, 1.0, 0.4)
	_preview.visible = false
	add_child(_preview)


func _input(event: InputEvent) -> void:
	# Touch input
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_draw(_screen_to_world(event.position))
		else:
			_end_draw(_screen_to_world(event.position))
	elif event is InputEventScreenDrag:
		_update_preview(_screen_to_world(event.position))

	# Mouse input (desktop)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_draw(_screen_to_world(event.position))
		else:
			_end_draw(_screen_to_world(event.position))
	elif event is InputEventMouseMotion and _drawing:
		_update_preview(_screen_to_world(event.position))


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_pos


func _start_draw(world_pos: Vector2) -> void:
	if _active_lines >= MAX_LINES:
		return
	if _ink < MIN_LEN:
		return

	_drawing = true
	_start_world = world_pos
	_preview.clear_points()
	_preview.add_point(world_pos)
	_preview.add_point(world_pos)
	_preview.visible = true


func _update_preview(world_pos: Vector2) -> void:
	if not _drawing:
		return
	if _preview.get_point_count() >= 2:
		_preview.set_point_position(1, world_pos)


func _end_draw(world_pos: Vector2) -> void:
	if not _drawing:
		return
	_drawing = false
	_preview.visible = false
	_preview.clear_points()

	var direction := world_pos - _start_world
	var raw_len := direction.length()
	if raw_len < MIN_LEN:
		return

	# Trim to available ink
	var actual_len := minf(raw_len, _ink)
	var end_world := _start_world + direction.normalized() * actual_len

	_ink -= actual_len
	ink_changed.emit(_ink, INK_MAX)

	var target := world_node if world_node else self
	var line_scene := DrawnLine.new()
	target.add_child(line_scene)
	line_scene.setup(_start_world, end_world, LINE_LIFETIME)
	line_scene.line_expired.connect(_on_line_expired)
	_active_lines += 1


func _on_line_expired() -> void:
	_active_lines = maxi(_active_lines - 1, 0)


func _process(delta: float) -> void:
	if _ink < INK_MAX:
		_ink = minf(_ink + INK_REGEN * delta, INK_MAX)
		ink_changed.emit(_ink, INK_MAX)
