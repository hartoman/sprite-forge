extends "res://src/ui/step_panel.gd"
## Step 2: remove the background (a flat colour key, or paper cleanup for sketches).


func _ready() -> void:
	add_heading("Background")
	add_hint("Remove the flat background colour. JPEG blurs edges, so the tolerance also catches the fringe around each shape.")
	add_option("Method", ["Flat colour key", "Paper (pencil sketch)"], &"set_key_method")

	add_section("Colour key")
	add_color("Key colour", Color(1, 0, 1), &"set_key_color")
	add_button("Pick colour from image", &"pick_key_color")
	add_slider("Tolerance", 0, 100, 1, 30, &"set_tolerance", "%")
	add_slider("Fringe", 0, 8, 1, 2, &"set_fringe", " px")

	add_section("Paper (sketch only)")
	add_hint("Brightens the paper, then fills each closed outline so the inside stays opaque.")
	add_slider("Paper level", 0, 100, 1, 80, &"set_paper_level", "%")
	add_slider("Close gaps", 0, 10, 1, 2, &"set_close_gaps", " px")

	add_section("Result")
	add_check("Show removed area", true, &"toggle_key_preview")
	add_button("Apply", &"apply_key")
