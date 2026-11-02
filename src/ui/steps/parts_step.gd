extends "res://src/ui/step_panel.gd"
## Step 4: say which piece is which part of the body type ("this is the head").

var parts_tree: Tree


func _ready() -> void:
	add_heading("Parts")
	add_hint("Match each part of the body type to a piece. The tool guesses from the layout the prompt asked for; click a row to fix it.")
	add_button("Guess from layout", &"guess_parts")

	parts_tree = Tree.new()
	parts_tree.columns = 2
	parts_tree.column_titles_visible = true
	parts_tree.set_column_title(0, "Part")
	parts_tree.set_column_title(1, "Piece")
	parts_tree.hide_root = true
	parts_tree.custom_minimum_size.y = 240
	add_child(parts_tree)

	add_check("Highlight the selected part", true, &"toggle_part_highlight")
