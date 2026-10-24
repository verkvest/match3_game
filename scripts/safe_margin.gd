extends MarginContainer

## Pads this container by the device safe area (notch, status bar, home indicator)
## plus a small constant gutter. Backgrounds should live outside this node so
## they still paint edge to edge.

@export var gutter := 10

func _ready() -> void:
    resized.connect(_apply)
    get_viewport().size_changed.connect(_apply)
    call_deferred("_apply")

func _apply() -> void:
    var host := get_parent() as Control
    var m := SafeArea.content_insets(host)
    add_theme_constant_override("margin_left", int(ceil(m.x)) + gutter)
    add_theme_constant_override("margin_top", int(ceil(m.y)) + gutter)
    add_theme_constant_override("margin_right", int(ceil(m.z)) + gutter)
    add_theme_constant_override("margin_bottom", int(ceil(m.w)) + gutter)
