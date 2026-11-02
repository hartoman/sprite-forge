extends "res://src/ui/step_panel.gd"
## Step 3: find the separate pieces (connected regions) and tidy them up.

var pieces_list: ItemList


func _ready() -> void:
	add_heading("Pieces")
	add_hint("Each separate shape becomes a piece. Small loose bits, such as sparks or spikes, can merge into the nearest big piece.")
	add_slider("Min. size", 0, 2000, 10, 200, &"set_min_piece_size", " px")
	add_check("Merge small bits automatically", true, &"toggle_auto_merge")
	add_button("Find pieces", &"find_pieces")

	add_section("Found")
	pieces_list = add_list(220, true)
	add_button_row([["Merge selected", &"merge_pieces"], ["Delete", &"delete_piece"]])
