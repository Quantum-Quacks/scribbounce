extends CanvasLayer
class_name DeathScreen

@onready var height_label: Label = %HeightLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart)


func show_death(height: float) -> void:
	visible = true
	height_label.text = "Height: %dm" % int(height)


func _on_restart() -> void:
	get_tree().reload_current_scene()
