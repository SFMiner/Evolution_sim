extends PanelContainer
## Makes a panel draggable by clicking and dragging
## Prevents organisms from getting stuck behind UI panels

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Enable mouse input for dragging
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				# Stop dragging
				dragging = false
	
	elif event is InputEventMouseMotion:
		if dragging:
			# Move panel with mouse
			global_position = get_global_mouse_position() - drag_offset

func _input(event: InputEvent) -> void:
	# Also handle mouse motion outside the panel while dragging
	if dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
