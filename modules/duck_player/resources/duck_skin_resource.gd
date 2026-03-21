@tool
class_name DuckSkinResource
extends DuckInfo

## Resource que define un skin completo para el Player
##
## Extiende DuckInfo para mantener compatibilidad con el sistema de desbloqueo
## y añade configuración de efectos visuales (trail, partículas, efectos especiales)

#### TRAIL CONFIGURATION ####

@export_group("Trail")
@export var trail_color: Color = Color(0.574, 0.562, 0, 0.698):
	set(value):
		trail_color = value
		emit_changed()

@export var trail_gradient: Gradient:
	set(value):
		trail_gradient = value
		emit_changed()

@export_range(10.0, 100.0, 1.0) var trail_width: float = 42.0:
	set(value):
		trail_width = value
		emit_changed()

@export_range(8, 64, 1) var trail_length: int = 32:
	set(value):
		trail_length = value
		emit_changed()

#### EFFECTS CONFIGURATION ####

@export_group("Effects")
@export var particle_effects: Array[DuckEffectBase] = []:
	set(value):
		particle_effects = value
		emit_changed()

@export var enable_effects: bool = true:
	set(value):
		enable_effects = value
		emit_changed()

#### VISUAL SCALE ####

@export_group("Appearance")
@export_range(0.1, 2.0, 0.05) var skin_scale: float = 0.5:
	set(value):
		skin_scale = value
		emit_changed()


## Returns true if this skin has any particle effects
func has_effects() -> bool:
	return enable_effects and particle_effects.size() > 0


## Returns all active effects
func get_active_effects() -> Array[DuckEffectBase]:
	if not enable_effects:
		return []
	return particle_effects.filter(func(e): return e != null)


## Creates a default gradient if none is set
func get_trail_gradient() -> Gradient:
	if trail_gradient:
		return trail_gradient

	# Create default gradient based on trail_color
	var grad := Gradient.new()
	grad.set_color(0, trail_color)
	var transparent := trail_color
	transparent.a = 0.0
	grad.set_color(1, transparent)
	return grad
