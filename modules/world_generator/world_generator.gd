extends Node
class_name WorldGenerator

@export var world_node: Node2D
@export var camera: Camera2D

const CHUNK_HEIGHT: float = 800.0
const GENERATE_AHEAD: int = 2
const CLEAN_BEHIND: int = 2

var _spike_scene: PackedScene
var _generated_top: float = 0.0
var _chunks_generated: int = 0


func _ready() -> void:
	_spike_scene = load("res://modules/world_generator/spike.tscn") as PackedScene
	call_deferred("_initial_generate")


func _initial_generate() -> void:
	# Fallback if NodePath export didn't resolve (common in hand-written .tscn)
	if not is_instance_valid(world_node):
		world_node = get_parent().get_node_or_null("World") as Node2D
	if not world_node:
		push_error("WorldGenerator: world_node not found")
		return
	for i in range(4):
		_generate_chunk(200.0 + i * CHUNK_HEIGHT)
	_generated_top = 200.0


func _process(_delta: float) -> void:
	if not camera:
		return

	var cam_top := camera.global_position.y - 960.0

	# Generate ahead
	while _generated_top > cam_top - GENERATE_AHEAD * CHUNK_HEIGHT:
		_generated_top -= CHUNK_HEIGHT
		_generate_chunk(_generated_top)


func _generate_chunk(chunk_y: float) -> void:
	_chunks_generated += 1
	var height_m := int(-chunk_y / 250.0)

	var spike_count := _get_spike_count(height_m)
	for i in range(spike_count):
		var spike := _spike_scene.instantiate() as Node2D
		var sx := randf_range(100.0, 980.0)
		var sy := chunk_y + randf_range(100.0, CHUNK_HEIGHT - 100.0)
		spike.global_position = Vector2(sx, sy)
		spike.rotation = randf_range(-0.2, 0.2)
		world_node.add_child(spike)


func _get_spike_count(height_m: int) -> int:
	if height_m < 20:
		return randi_range(0, 1)
	elif height_m < 50:
		return randi_range(1, 2)
	elif height_m < 100:
		return randi_range(1, 3)
	else:
		return randi_range(2, 4)
