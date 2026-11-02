extends Control
## Shows the working image over a checkerboard, with zoom and pan.
## Wheel: zoom at the cursor. Middle-drag or Space + left-drag: pan.
## Overlays (pieces, pivots, rig) will draw on top of this later.

signal zoom_changed(zoom: float)
signal cursor_moved(image_pos: Vector2i, inside: bool)

const ZOOM_MIN := 0.05
const ZOOM_MAX := 64.0
const ZOOM_STEP := 1.25
const FIT_MARGIN := 24.0
const CHECKER_SIZE := 8
const BG_COLOR := Color(0.13, 0.14, 0.16)
const HINT_COLOR := Color(1, 1, 1, 0.4)

var texture: Texture2D
var zoom := 1.0
## Screen position of the image's top-left corner.
var origin := Vector2.ZERO

var _checker: ImageTexture
var _panning := false
var _fit_pending := false


func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_checker = _make_checker()
	resized.connect(_on_resized)


func set_image(image: Image) -> void:
	texture = ImageTexture.create_from_image(image)
	fit()


func image_size() -> Vector2:
	return texture.get_size() if texture else Vector2.ZERO


func fit() -> void:
	if texture == null:
		return
	if size.x <= FIT_MARGIN * 2.0 or size.y <= FIT_MARGIN * 2.0:
		_fit_pending = true
		return
	_fit_pending = false
	var avail := size - Vector2(FIT_MARGIN, FIT_MARGIN) * 2.0
	var s := image_size()
	zoom = clampf(minf(avail.x / s.x, avail.y / s.y), ZOOM_MIN, ZOOM_MAX)
	origin = ((size - s * zoom) / 2.0).round()
	zoom_changed.emit(zoom)
	queue_redraw()


func zoom_at(screen_pos: Vector2, new_zoom: float) -> void:
	new_zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	var image_pos := (screen_pos - origin) / zoom
	zoom = new_zoom
	origin = (screen_pos - image_pos * zoom).round()
	zoom_changed.emit(zoom)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					zoom_at(mb.position, zoom * ZOOM_STEP)
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					zoom_at(mb.position, zoom / ZOOM_STEP)
				accept_event()
			MOUSE_BUTTON_MIDDLE:
				_panning = mb.pressed
				accept_event()
			MOUSE_BUTTON_LEFT:
				if mb.pressed and Input.is_key_pressed(KEY_SPACE):
					_panning = true
					accept_event()
				elif not mb.pressed and _panning:
					_panning = false
					accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			origin += mm.relative
			queue_redraw()
		_emit_cursor(mm.position)
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		zoom_at(mg.position, zoom * mg.factor)
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	if texture == null:
		var text := "Open an image to start (File > Open image…, or drop a file here)"
		draw_string(get_theme_default_font(), Vector2(0, size.y / 2.0), text,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, get_theme_default_font_size(), HINT_COLOR)
		return
	var rect := Rect2(origin, image_size() * zoom)
	draw_texture_rect(_checker, rect, true)
	draw_texture_rect(texture, rect, false)


func _emit_cursor(screen_pos: Vector2) -> void:
	if texture == null:
		return
	var p := ((screen_pos - origin) / zoom).floor()
	var s := image_size()
	cursor_moved.emit(Vector2i(p), p.x >= 0 and p.y >= 0 and p.x < s.x and p.y < s.y)


func _on_resized() -> void:
	if _fit_pending:
		fit()


static func _make_checker() -> ImageTexture:
	var image := Image.create_empty(CHECKER_SIZE * 2, CHECKER_SIZE * 2, false, Image.FORMAT_RGB8)
	image.fill(Color(0.22, 0.22, 0.24))
	var light := Color(0.29, 0.29, 0.31)
	image.fill_rect(Rect2i(0, 0, CHECKER_SIZE, CHECKER_SIZE), light)
	image.fill_rect(Rect2i(CHECKER_SIZE, CHECKER_SIZE, CHECKER_SIZE, CHECKER_SIZE), light)
	return ImageTexture.create_from_image(image)
