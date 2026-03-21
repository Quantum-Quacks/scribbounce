## Signal bus singleton - centralizes event communication between systems
extends Node

# === PLAYER SIGNALS ===
@warning_ignore("unused_signal")
signal player_died(position: Vector2)
@warning_ignore("unused_signal")
signal player_respawned(position: Vector2)
@warning_ignore("unused_signal")
signal player_bounced(point: Vector2, normal: Vector2, velocity: float)
@warning_ignore("unused_signal")
signal player_height_changed(height: float)
