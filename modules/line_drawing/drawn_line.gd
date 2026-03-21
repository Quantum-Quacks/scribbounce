extends Node2D
class_name DrawnLine

signal line_expired

const FADE_START: float = 2.0

var lifetime: float = 8.0
var _timer: float = 0.0
var _visual: Line2D

func setup(from: Vector2, to: Vector2, line_lifetime: float = 8.0) -> void:
	lifetime = line_lifetime

	# Visual
	_visual = Line2D.new()
	_visual.name = "Visual"
	_visual.width = 18.0
	_visual.default_color = Color(0.2, 0.2, 0.8, 1.0)
	_visual.add_point(from)
	_visual.add_point(to)
	add_child(_visual)

	# Physics body
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	shape.name = "Collision"
	var segment := SegmentShape2D.new()
	segment.a = from
	segment.b = to
	shape.shape = segment
	body.add_child(shape)
	add_child(body)


func _process(delta: float) -> void:
	_timer += delta

	# Fade out in last FADE_START seconds
	var remaining := lifetime - _timer
	if remaining < FADE_START:
		var alpha := clamp(remaining / FADE_START, 0.0, 1.0)
		if _visual:
			var c := _visual.default_color
			_visual.default_color = Color(c.r, c.g, c.b, alpha)

	if _timer >= lifetime:
		line_expired.emit()
		queue_free()
