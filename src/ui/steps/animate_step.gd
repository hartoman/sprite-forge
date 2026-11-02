extends "res://src/ui/step_panel.gd"
## Step 6: pose the rig and build motions; frames live in the timeline below the canvas.


func _ready() -> void:
	add_heading("Animate")
	add_option("Motion", ["Idle", "Walk", "Attack: thrust", "Attack: swing", "Hit", "Death"], &"set_motion")
	add_option("Mode", ["Frame by frame", "Key poses + in-betweens"], &"set_anim_mode")
	add_option("Easing", ["Ease in-out", "Linear", "Ease in", "Ease out"], &"set_easing")
	add_slider("Strength", 0, 200, 5, 100, &"set_strength", "%")
	add_slider("Speed", 25, 200, 5, 100, &"set_speed", "%")

	add_section("Pose")
	add_hint("Drag a part to rotate it around its pivot; Shift-drag to move it.")
	add_button_row([["Reset part", &"reset_part"], ["Reset pose", &"reset_pose"], ["Mirror", &"mirror_pose"]])

	add_section("Procedural (layered on top)")
	add_slider("Sway", 0, 100, 1, 0, &"set_sway", "%")
	add_slider("Breathe", 0, 100, 1, 0, &"set_breathe", "%")

	add_section("Library")
	add_button_row([["Save motion…", &"save_motion"], ["Load motion…", &"load_motion"]])
