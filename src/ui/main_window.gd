extends PanelContainer
## The editor window: menu bar, step list, canvas, inspector, timeline and status bar.
## Every control reports an action through `_on_request`; actions not built yet say so
## in the status bar.

const ImageIO := preload("res://src/core/imaging/image_io.gd")
const CanvasView := preload("res://src/ui/canvas_view.gd")
const Timeline := preload("res://src/ui/timeline.gd")

## [title, panel script] per workflow step, in order.
const STEPS := [
	["Source", preload("res://src/ui/steps/source_step.gd")],
	["Background", preload("res://src/ui/steps/background_step.gd")],
	["Pieces", preload("res://src/ui/steps/pieces_step.gd")],
	["Parts", preload("res://src/ui/steps/parts_step.gd")],
	["Pivots", preload("res://src/ui/steps/pivots_step.gd")],
	["Animate", preload("res://src/ui/steps/animate_step.gd")],
	["Bake", preload("res://src/ui/steps/bake_step.gd")],
]
const STEP_SOURCE := 0
const STEP_ANIMATE := 5
const IMAGE_FILTER := "*.png, *.jpg, *.jpeg, *.jfif, *.webp, *.bmp ; Images"

enum Menu { NEW_PROJECT, OPEN_PROJECT, OPEN_IMAGE, SAVE_PROJECT, SAVE_PROJECT_AS, QUIT, FIT, ACTUAL_SIZE, ABOUT }

var image: Image
var image_path := ""

var canvas: CanvasView
var timeline: Timeline
var file_dialog: FileDialog
var step_buttons: Array[Button] = []
## Step panel nodes, in STEPS order (untyped: each has its own script).
var panels: Array = []
var status_label: Label
var cursor_label: Label
var _zoom := 1.0
var _cursor := ""


func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_menu_bar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root.add_child(body)
	body.add_child(_build_step_list())

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(split)
	var center := VSplitContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(center)
	canvas = CanvasView.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.zoom_changed.connect(_on_zoom_changed)
	canvas.cursor_moved.connect(_on_cursor_moved)
	center.add_child(canvas)
	timeline = Timeline.new()
	timeline.request.connect(_on_request)
	center.add_child(timeline)
	split.add_child(_build_inspector())

	root.add_child(_build_status_bar())
	_build_file_dialog()
	get_window().files_dropped.connect(_on_files_dropped)

	_select_step(STEP_SOURCE)
	_update_step_access()


func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.ctrl_pressed and key.keycode == KEY_O:
		_open_image_dialog()
	elif not key.ctrl_pressed and key.keycode == KEY_F:
		canvas.fit()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Building -----------------------------------------------------------------

func _build_menu_bar() -> Control:
	var panel := PanelContainer.new()
	var bar := HBoxContainer.new()
	panel.add_child(bar)
	bar.add_child(_menu("File", [
		["New project", Menu.NEW_PROJECT],
		["Open project…", Menu.OPEN_PROJECT],
		["Open image…  (Ctrl+O)", Menu.OPEN_IMAGE],
		[],
		["Save project", Menu.SAVE_PROJECT],
		["Save project as…", Menu.SAVE_PROJECT_AS],
		[],
		["Quit", Menu.QUIT],
	]))
	bar.add_child(_menu("View", [
		["Fit to window  (F)", Menu.FIT],
		["Actual size (100%)", Menu.ACTUAL_SIZE],
	]))
	bar.add_child(_menu("Help", [["About Sprite Forge", Menu.ABOUT]]))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var title := Label.new()
	title.text = "Sprite Forge  ·  Untitled project"
	title.modulate.a = 0.7
	bar.add_child(title)
	return panel


## `items` is a list of [label, Menu id] pairs; an empty entry adds a separator.
func _menu(title: String, items: Array) -> MenuButton:
	var button := MenuButton.new()
	button.text = title
	button.switch_on_hover = true
	var popup := button.get_popup()
	for item in items:
		if item.is_empty():
			popup.add_separator()
		else:
			popup.add_item(item[0], item[1])
	popup.id_pressed.connect(_on_menu)
	return button


func _build_step_list() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 160
	var box := VBoxContainer.new()
	panel.add_child(box)
	var group := ButtonGroup.new()
	for i in STEPS.size():
		var button := Button.new()
		button.text = "%d   %s" % [i + 1, STEPS[i][0]]
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 40
		button.pressed.connect(_select_step.bind(i))
		box.add_child(button)
		step_buttons.append(button)
	return panel


func _build_inspector() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 330
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	scroll.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	for entry in STEPS:
		var step_panel = entry[1].new()
		step_panel.visible = false
		step_panel.request.connect(_on_request)
		stack.add_child(step_panel)
		panels.append(step_panel)
	return panel


func _build_status_bar() -> Control:
	var panel := PanelContainer.new()
	var bar := HBoxContainer.new()
	panel.add_child(bar)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_label.text = "Ready."
	bar.add_child(status_label)
	cursor_label = Label.new()
	cursor_label.modulate.a = 0.7
	bar.add_child(cursor_label)
	return panel


func _build_file_dialog() -> void:
	file_dialog = FileDialog.new()
	file_dialog.title = "Open image"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.filters = PackedStringArray([IMAGE_FILTER])
	var samples := ProjectSettings.globalize_path("res://samples")
	if DirAccess.dir_exists_absolute(samples):
		file_dialog.current_dir = samples
	file_dialog.file_selected.connect(_load_image)
	add_child(file_dialog)


# --- Actions ------------------------------------------------------------------

func _on_request(action: StringName, _value: Variant) -> void:
	match action:
		&"open_image":
			_open_image_dialog()
		_:
			_set_status("Not built yet: %s" % action)


func _on_menu(id: int) -> void:
	match id:
		Menu.OPEN_IMAGE:
			_open_image_dialog()
		Menu.FIT:
			canvas.fit()
		Menu.ACTUAL_SIZE:
			canvas.zoom_at(canvas.size / 2.0, 1.0)
		Menu.ABOUT:
			_show_about()
		Menu.QUIT:
			get_tree().quit()
		_:
			_set_status("Not built yet: that menu item.")


func _open_image_dialog() -> void:
	file_dialog.popup_centered_ratio(0.6)


func _load_image(path: String) -> void:
	var loaded := ImageIO.load_image(path)
	if loaded == null:
		_set_status("Could not load %s (not a PNG, JPEG, WebP or BMP image?)" % path.get_file())
		return
	image = loaded
	image_path = path
	canvas.set_image(image)
	panels[STEP_SOURCE].show_image_info(path, image.get_size())
	_update_step_access()
	_set_status("Loaded %s (%d × %d px)." % [path.get_file(), image.get_width(), image.get_height()])


func _on_files_dropped(files: PackedStringArray) -> void:
	if not files.is_empty():
		_load_image(files[0])


func _select_step(index: int) -> void:
	step_buttons[index].set_pressed_no_signal(true)
	for i in panels.size():
		panels[i].visible = i == index
	timeline.visible = index == STEP_ANIMATE


## Steps after Source stay locked until an image is loaded.
func _update_step_access() -> void:
	for i in range(1, step_buttons.size()):
		step_buttons[i].disabled = image == null


func _show_about() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "About Sprite Forge"
	dialog.dialog_text = "Sprite Forge\nTurns one parts image into animated sprite sheets."
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


# --- Status bar ---------------------------------------------------------------

func _set_status(text: String) -> void:
	status_label.text = text


func _on_zoom_changed(zoom: float) -> void:
	_zoom = zoom
	_update_cursor_label()


func _on_cursor_moved(image_pos: Vector2i, inside: bool) -> void:
	_cursor = "%d, %d" % [image_pos.x, image_pos.y] if inside else ""
	_update_cursor_label()


func _update_cursor_label() -> void:
	var parts := PackedStringArray()
	if _cursor != "":
		parts.append(_cursor)
	if image:
		parts.append("%d × %d" % [image.get_width(), image.get_height()])
	parts.append("%d%%" % roundi(_zoom * 100.0))
	cursor_label.text = "   ·   ".join(parts)
