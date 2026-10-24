class_name SafeArea
extends RefCounted

## Screen safe-area insets converted into viewport pixels.
## Vector4 is (left, top, right, bottom).

static func margins_for(viewport: Viewport) -> Vector4:
    var window_size := Vector2(DisplayServer.window_get_size())
    var vp := viewport.get_visible_rect().size
    if window_size.x <= 1.0 or window_size.y <= 1.0 or vp.x <= 1.0 or vp.y <= 1.0:
        return Vector4.ZERO
    var safe := DisplayServer.get_display_safe_area()
    if safe.size.x <= 0 or safe.size.y <= 0:
        return Vector4.ZERO
    var scale := vp / window_size
    var left := safe.position.x * scale.x
    var top := safe.position.y * scale.y
    var right := (window_size.x - safe.end.x) * scale.x
    var bottom := (window_size.y - safe.end.y) * scale.y
    if left < -1.0 or top < -1.0 or right < -1.0 or bottom < -1.0:
        return Vector4.ZERO
    # A safe rect reported in the wrong space (some desktop drivers) would
    # swallow the layout. Drop insets that are too large to be a notch.
    if left + right > vp.x * 0.5 or top + bottom > vp.y * 0.45:
        return Vector4.ZERO
    return Vector4(maxf(left, 0.0), maxf(top, 0.0), maxf(right, 0.0), maxf(bottom, 0.0))


## Insets to apply to a control. Full-bleed screens inset their content.
## A stage that has already been fitted inside the safe rect does not inset again.
static func content_insets(control: Control) -> Vector4:
    if control == null or control.get_viewport() == null:
        return Vector4.ZERO
    var vp := control.get_viewport().get_visible_rect().size
    if absf(control.size.x - vp.x) > 1.5 or absf(control.size.y - vp.y) > 1.5:
        return Vector4.ZERO
    return margins_for(control.get_viewport())
