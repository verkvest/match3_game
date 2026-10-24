extends Control

const UiGamePrefab = preload("res://scenes/game.tscn")
const UiGameOverPrefab = preload("res://scenes/game_over.tscn")
const UiCreditsPrefab = preload("res://scenes/credits.tscn")

@onready var stage: Control = $Stage
@onready var ui_menu: Control = $Stage/MainMenuUI
@onready var exit_button: Button = $Stage/MainMenuUI/Margin/VBox/Exit

var ui_game = null
var ui_game_over = null
var ui_credits = null

func _ready() -> void:
    _fill_root()
    get_viewport().size_changed.connect(_fill_root)
    if not OS.has_feature("mobile") and OS.get_environment("CINDERMOTE_SCREENSHOT").is_empty():
        var window := get_window()
        window.size *= 2
        window.position = Vector2.ZERO
    if OS.has_feature("mobile"):
        exit_button.visible = false
    Events.game_over.connect(on_game_over)
    Events.return_to_menu.connect(_leave_play)
    _maybe_capture_screenshots()

func _fill_root() -> void:
    position = Vector2.ZERO
    size = get_viewport().get_visible_rect().size

func on_game_over(score) -> void:
    ui_game = null
    if ui_game_over:
        return
    ui_game_over = UiGameOverPrefab.instantiate()
    ui_game_over.init(score)
    ui_game_over.tree_exited.connect(func() -> void: ui_game_over = null)
    stage.add_child(ui_game_over)

func _on_btn_new_game_pressed() -> void:
    if ui_game or ui_game_over or ui_credits:
        return
    ui_game = UiGamePrefab.instantiate()
    stage.add_child(ui_game)

func _on_btn_credits_pressed() -> void:
    if ui_game or ui_game_over or ui_credits:
        return
    ui_credits = UiCreditsPrefab.instantiate()
    ui_credits.tree_exited.connect(func() -> void: ui_credits = null)
    stage.add_child(ui_credits)

func _on_btn_exit_pressed() -> void:
    get_tree().quit()

func _leave_play() -> void:
    if ui_game_over:
        ui_game_over.queue_free()
        ui_game_over = null
    if ui_game:
        var leaving = ui_game
        ui_game = null
        leaving.queue_free()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        _go_back()

func _input(event: InputEvent) -> void:
    var back_key := false
    if event is InputEventKey:
        var key := event as InputEventKey
        back_key = key.pressed and not key.echo and key.keycode == KEY_BACK
    if event.is_action_pressed("GoBack") or back_key:
        _go_back()
        get_viewport().set_input_as_handled()

func _go_back() -> void:
    if ui_credits:
        ui_credits.queue_free()
        ui_credits = null
        return
    if ui_game_over or ui_game:
        _leave_play()
        return
    if OS.has_feature("mobile"):
        get_tree().quit()

func _maybe_capture_screenshots() -> void:
    var dir := OS.get_environment("CINDERMOTE_SCREENSHOT")
    if dir.is_empty():
        return
    DirAccess.make_dir_recursive_absolute(dir)
    print("screenshot: waiting for menu frame")
    await RenderingServer.frame_post_draw
    await get_tree().create_timer(0.6).timeout
    _save_viewport(dir, "menu")
    _on_btn_new_game_pressed()
    print("screenshot: waiting for level frame")
    await get_tree().create_timer(2.4).timeout
    await RenderingServer.frame_post_draw
    _save_viewport(dir, "level")
    print("screenshot: done")
    get_tree().quit()

func _save_viewport(dir: String, shot_name: String) -> void:
    var image := get_viewport().get_texture().get_image()
    var path := dir.path_join(shot_name + ".png")
    var err := image.save_png(path)
    print("screenshot ", path, " ", err)
