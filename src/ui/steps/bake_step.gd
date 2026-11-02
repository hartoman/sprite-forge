extends "res://src/ui/step_panel.gd"
## Step 7: render every motion, shrink to the cell size and write the sheet + JSON.


func _ready() -> void:
	add_heading("Bake")
	add_option("Profile", ["Map Wars (68 × 42)", "Custom"], &"set_profile")

	add_section("Cell")
	add_spin("Width", 8, 1024, 68, &"set_cell_width")
	add_spin("Height", 8, 1024, 42, &"set_cell_height")
	add_spin("Anchor x", 0, 1024, 20, &"set_anchor_x")
	add_spin("Anchor y", 0, 1024, 38, &"set_anchor_y")

	add_section("Pixels")
	add_option("Downscale", ["Majority (pixel art)", "Smooth"], &"set_downscale")
	add_check("Lock to the source palette", false, &"toggle_palette_lock")
	add_check("Line boil (sketch)", false, &"toggle_line_boil")

	add_section("Output")
	add_button("Preview sheet", &"preview_sheet")
	add_button("Export PNG + JSON…", &"export_sheet")
