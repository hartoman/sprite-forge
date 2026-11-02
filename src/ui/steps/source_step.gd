extends "res://src/ui/step_panel.gd"
## Step 1: the input image, how it was drawn, and the body type.

var _info: Label


func _ready() -> void:
	add_heading("Source")
	add_hint("One image of the creature: a parts sheet (the assembled figure plus its pieces, laid out apart) or a single drawing.")
	add_button("Open image…", &"open_image")
	_info = add_hint("No image loaded.")

	add_section("How it was drawn")
	add_option("Style", ["Pixel art", "Painted / clean", "Pencil sketch"], &"set_style")
	add_option("Input", ["Parts sheet", "Single image"], &"set_input_path")

	add_section("Body type")
	add_option("Preset", ["Biped"], &"set_preset")
	add_button("Copy parts-sheet prompt", &"copy_prompt")


func show_image_info(path: String, image_size: Vector2i) -> void:
	_info.text = "%s\n%d × %d px" % [path.get_file(), image_size.x, image_size.y]
