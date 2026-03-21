extends Node2D
class_name GameScene

@onready var duck: Player = $DuckPlayer
@onready var camera: SimpleCamera = $Camera
@onready var line_system: LineDrawingSystem = $LineDrawingSystem
@onready var world_gen: WorldGenerator = $WorldGenerator
@onready var hud: HUD = $HUD
@onready var death_screen: DeathScreen = $DeathScreen
@onready var world: Node2D = $World

var _dead: bool = false
var _max_height: float = 0.0


func _ready() -> void:
	# Initial impulse: random horizontal direction
	var dir := 1.0 if randf() > 0.5 else -1.0
	duck.linear_velocity = Vector2(dir * 250.0, -500.0)

	# Connect signals
	line_system.ink_changed.connect(hud.update_ink)
	SignalBus.player_died.connect(_on_player_died)

	_setup_walls()
	hud.update_ink(800.0, 800.0)
	hud.update_height(0.0)


func _process(_delta: float) -> void:
	if _dead:
		return

	# Track height (upward = positive meters)
	var height := -duck.global_position.y / 250.0
	if height > _max_height:
		_max_height = height
		hud.update_height(_max_height)

	# Death by falling below camera
	if camera.is_duck_below_death_line(duck.global_position):
		_trigger_death()


func _on_player_died(_pos: Vector2) -> void:
	_trigger_death()


func _trigger_death() -> void:
	if _dead:
		return
	_dead = true
	duck.disable_control()
	death_screen.show_death(_max_height)


func _setup_walls() -> void:
	# Left wall at x=0
	var left_wall := StaticBody2D.new()
	left_wall.collision_layer = 1
	left_wall.collision_mask = 0
	var left_shape := CollisionShape2D.new()
	var left_seg := SegmentShape2D.new()
	left_seg.a = Vector2(0.0, -50000.0)
	left_seg.b = Vector2(0.0, 50000.0)
	left_shape.shape = left_seg
	left_wall.add_child(left_shape)
	add_child(left_wall)

	# Right wall at x=1080
	var right_wall := StaticBody2D.new()
	right_wall.collision_layer = 1
	right_wall.collision_mask = 0
	var right_shape := CollisionShape2D.new()
	var right_seg := SegmentShape2D.new()
	right_seg.a = Vector2(1080.0, -50000.0)
	right_seg.b = Vector2(1080.0, 50000.0)
	right_shape.shape = right_seg
	right_wall.add_child(right_shape)
	add_child(right_wall)
