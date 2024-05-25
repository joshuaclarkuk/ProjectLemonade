extends Node3D

@onready var overview_cam: Camera3D = $OverviewCam
@onready var player: CharacterBody3D = $Player


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		toggle_debug_cam()


func toggle_debug_cam() -> void:
	if overview_cam.is_current():
			player.get_node("CameraPivot/SmoothCamera").set_current(true)
	else:
		overview_cam.set_current(true)
