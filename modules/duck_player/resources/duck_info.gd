@tool class_name DuckInfo extends Resource


signal texture_changed(texture: Texture)
signal name_changed(name: String)


# Clicks to unlock!
enum RARITY {
    COMMON = 10,
    RARE = 15,
    EPIC = 20,
    LEGENDARY = 25,
}


@export var texture: Texture:
    set(value):
        texture = value
        texture_changed.emit(value)
        emit_changed()


@export var name := "Duck":
    set(value):
        name = value
        name_changed.emit(value)
        emit_changed()


@export var rarity := RARITY.COMMON

@export var clicks_required := 1
