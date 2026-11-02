extends Control
## Entry point. The UI is built in code (see src/ui/); this scene stays a bare root.

const MainWindow := preload("res://src/ui/main_window.gd")


func _ready() -> void:
	var main_window := MainWindow.new()
	add_child(main_window)
	main_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
