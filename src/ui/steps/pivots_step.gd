extends "res://src/ui/step_panel.gd"
## Step 5: set the joint each part turns around, and where it sits on its parent.

var parts_list: ItemList


func _ready() -> void:
	add_heading("Pivots")
	add_hint("Each part turns around its pivot. Drag the dots on the canvas to correct the guesses.")
	add_button("Guess pivots from shapes", &"guess_pivots")
	add_button("Place parts on the assembled figure", &"match_parts")

	add_section("Parts")
	parts_list = add_list(180)
	add_button("Reset selected pivot", &"reset_pivot")

	add_section("Show")
	add_check("Bones", true, &"toggle_bones")
	add_check("Assembled figure underneath", true, &"toggle_reference")
