extends PanelContainer
## The frame strip under the canvas, shown in the Animate step.

signal request(action: StringName, value: Variant)

const CELL_SIZE := Vector2(72, 72)

var _strip: HBoxContainer
var _frames := ButtonGroup.new()


func _ready() -> void:
	custom_minimum_size.y = 120
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	var transport := VBoxContainer.new()
	row.add_child(transport)
	var buttons := HBoxContainer.new()
	transport.add_child(buttons)
	buttons.add_child(_button("Prev", &"prev_frame"))
	var play := Button.new()
	play.text = "Play"
	play.toggle_mode = true
	play.custom_minimum_size.x = 60
	play.toggled.connect(func(on: bool):
		play.text = "Stop" if on else "Play"
		request.emit(&"toggle_play", on))
	buttons.add_child(play)
	buttons.add_child(_button("Next", &"next_frame"))
	var fps_row := HBoxContainer.new()
	transport.add_child(fps_row)
	var fps_label := Label.new()
	fps_label.text = "FPS"
	fps_row.add_child(fps_label)
	var fps := SpinBox.new()
	fps.min_value = 1
	fps.max_value = 60
	fps.value = 10
	fps.value_changed.connect(func(v: float): request.emit(&"set_fps", v))
	fps_row.add_child(fps)
	var onion := CheckBox.new()
	onion.text = "Onion skin"
	onion.toggled.connect(func(on: bool): request.emit(&"toggle_onion", on))
	transport.add_child(onion)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	_strip = HBoxContainer.new()
	_strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_strip)

	var edit := VBoxContainer.new()
	row.add_child(edit)
	edit.add_child(_button("Add frame", &"add_frame"))
	edit.add_child(_button("Delete frame", &"delete_frame"))
	edit.add_child(_button("Mark impact", &"mark_impact"))

	set_frame_count(0)


## Rebuilds the strip with `count` numbered frame cells.
func set_frame_count(count: int) -> void:
	for child in _strip.get_children():
		child.queue_free()
	if count == 0:
		var empty := Label.new()
		empty.text = "No frames yet. Pose the rig, then Add frame."
		empty.modulate.a = 0.6
		empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_strip.add_child(empty)
		return
	for i in count:
		var cell := Button.new()
		cell.text = str(i + 1)
		cell.toggle_mode = true
		cell.button_group = _frames
		cell.custom_minimum_size = CELL_SIZE
		cell.pressed.connect(func(): request.emit(&"select_frame", i))
		_strip.add_child(cell)


func _button(text: String, action: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(func(): request.emit(action, null))
	return button
