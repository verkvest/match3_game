extends Control

## Handle the UI for the game scene. Not cover the pieces (see grid.gd).

@onready var grid = $CanvasGroup/Grid
@onready var board: Control = $HBoxContainer
@onready var cover: ColorRect = $CoverFirstRow

func _ready() -> void:
    resized.connect(_layout_board)
    get_viewport().size_changed.connect(_layout_board)
    call_deferred("_layout_board")
    if not grid.is_node_ready():
        await grid.ready
    grid.try_next_match()
    Events.current_level = 1
    Events.game_over.connect(func(_score) -> void: queue_free())

func _layout_board() -> void:
    if size.x < 8.0 or size.y < 8.0:
        return
    var m := SafeArea.content_insets(self)
    board.offset_left = m.x
    board.offset_top = m.y
    board.offset_right = -m.z
    board.offset_bottom = -m.w
    var inner_w := size.x - m.x - m.z
    var inner_h := size.y - m.y - m.w
    var top_h := 64.0
    var bottom_h := 64.0
    var sprite := float(grid.SPRITE_SIZE)
    var visual_w := float(grid.grid_size_x) * sprite
    var visual_h := float(grid.grid_size_y) * sprite
    var area_top := m.y + top_h
    var area_h := maxf(0.0, inner_h - top_h - bottom_h)
    var x := m.x + (inner_w - visual_w) * 0.5 + sprite * 0.5
    var y := area_top + maxf(0.0, area_h - visual_h) * 0.5 + sprite * 0.5
    grid.position = Vector2(x, y)
    cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cover.position = Vector2(0, y - sprite * 0.5)
    cover.size = Vector2(size.x, sprite)

func _on_menu_pressed() -> void:
    Events.return_to_menu.emit()
