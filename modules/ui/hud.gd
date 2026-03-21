extends CanvasLayer
class_name HUD

@onready var height_label: Label = %HeightLabel
@onready var ink_bar: ProgressBar = %InkBar
@onready var ink_label: Label = %InkLabel


func update_ink(current: float, max_ink: float) -> void:
	var pct := current / max_ink * 100.0
	ink_bar.value = pct
	if pct > 50.0:
		ink_bar.modulate = Color.WHITE
	elif pct > 25.0:
		ink_bar.modulate = Color.YELLOW
	else:
		ink_bar.modulate = Color.RED
	ink_label.text = "Ink: %d%%" % int(pct)


func update_height(h: float) -> void:
	height_label.text = "%dm" % int(h)
