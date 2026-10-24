extends Control

@onready var body: RichTextLabel = $Margin/VBox/Scroll/Body

func _ready() -> void:
    resized.connect(_fit_text)
    _fit_text()
    var file := FileAccess.open("res://THIRD_PARTY_LICENSES.md", FileAccess.READ)
    if file:
        body.text = file.get_as_text()
        file.close()
    else:
        body.text = "Credits file missing."

func _fit_text() -> void:
    body.custom_minimum_size.x = maxf(120.0, size.x - 28.0)

func _on_back_pressed() -> void:
    queue_free()
