extends Control

## Fits the playfield to the window.
## Phones are taller than the 9:16 design, so the stage fills the window and
## each screen insets its own content by the safe area. A window smaller than
## the design (split view, tiny desktop) scales the 216x384 stage into the
## safe rect instead.

const DESIGN := Vector2(216, 384)

func _ready() -> void:
    get_viewport().size_changed.connect(_layout)
    call_deferred("_layout")

func _layout() -> void:
    var vp := get_viewport().get_visible_rect().size
    if vp.x < 2.0 or vp.y < 2.0:
        return
    set_anchors_preset(Control.PRESET_TOP_LEFT)
    var m := SafeArea.margins_for(get_viewport())
    var content := Vector2(vp.x - m.x - m.z, vp.y - m.y - m.w)
    if content.x >= DESIGN.x - 0.5 and content.y >= DESIGN.y - 0.5:
        position = Vector2.ZERO
        scale = Vector2.ONE
        size = vp
        return
    var fit := minf(content.x / DESIGN.x, content.y / DESIGN.y)
    scale = Vector2(fit, fit)
    size = DESIGN
    var scaled := DESIGN * fit
    position = Vector2(m.x, m.y) + (content - scaled) * 0.5
