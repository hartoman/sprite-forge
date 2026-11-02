extends VBoxContainer
## Base for the inspector panel of one workflow step. Controls made with the helpers
## below report through `request`; the main window decides what each action does.

signal request(action: StringName, value: Variant)

const LABEL_WIDTH := 110.0
const VALUE_WIDTH := 52.0
const HINT_ALPHA := 0.6


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)


func add_heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)
	return label


func add_section(text: String) -> Label:
	add_child(HSeparator.new())
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	add_child(label)
	return label


func add_hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate.a = HINT_ALPHA
	add_child(label)
	return label


func add_button(text: String, action: StringName, value: Variant = null) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(func(): request.emit(action, value))
	add_child(button)
	return button


## `buttons` is a list of [text, action] pairs, laid out side by side.
func add_button_row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var action: StringName = entry[1]
		button.pressed.connect(func(): request.emit(action, null))
		row.add_child(button)
	add_child(row)
	return row


func add_slider(label: String, min_value: float, max_value: float, step: float,
		value: float, action: StringName, suffix := "") -> HSlider:
	var row := _row(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = VALUE_WIDTH
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = "%s%s" % [value, suffix]
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float):
		value_label.text = "%s%s" % [v, suffix]
		request.emit(action, v))
	return slider


func add_spin(label: String, min_value: float, max_value: float, value: float,
		action: StringName) -> SpinBox:
	var row := _row(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.value = value
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(v: float): request.emit(action, v))
	row.add_child(spin)
	return spin


func add_option(label: String, items: Array, action: StringName) -> OptionButton:
	var row := _row(label)
	var option := OptionButton.new()
	for item in items:
		option.add_item(item)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(func(index: int): request.emit(action, index))
	row.add_child(option)
	return option


func add_check(text: String, pressed: bool, action: StringName) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = pressed
	check.toggled.connect(func(on: bool): request.emit(action, on))
	add_child(check)
	return check


func add_color(label: String, color: Color, action: StringName) -> ColorPickerButton:
	var row := _row(label)
	var picker := ColorPickerButton.new()
	picker.color = color
	picker.edit_alpha = false
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.custom_minimum_size.y = 28
	picker.color_changed.connect(func(c: Color): request.emit(action, c))
	row.add_child(picker)
	return picker


func add_list(min_height: float, multi_select := false) -> ItemList:
	var list := ItemList.new()
	list.custom_minimum_size.y = min_height
	if multi_select:
		list.select_mode = ItemList.SELECT_MULTI
	add_child(list)
	return list


func _row(label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var caption := Label.new()
	caption.text = label
	caption.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(caption)
	add_child(row)
	return row
