extends CharacterBody3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var vision_cast: RayCast3D = $CameraPivot/VisionCast
@onready var game_ui: Control = $GameUI
@onready var interact_label: Label = $GameUI/InteractLabel

@export_range(0.001, 0.005) var mouse_sensitivity: float = 0.002

var mouse_motion: Vector2 = Vector2.ZERO
var object_to_interact_with: Interactable = null
var ui_updated: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Needs changing to be set via UI
	GameManager.is_mouse_inverted = true
	
	game_ui.set_visible(false)


func _physics_process(delta: float) -> void:
	handle_camera_rotation()
	cast_for_interactable()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: # Stops player rotating when cursor is free
			mouse_motion = -event.relative * mouse_sensitivity
	
	if event.is_action_pressed("interact"):
		if !object_to_interact_with: return
		
		object_to_interact_with.interact()
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func handle_camera_rotation() -> void:
	rotate_y(mouse_motion.x)
	rotation_degrees.y = clampf(rotation_degrees.y, -80.0, 80.0)
	if GameManager.is_mouse_inverted == true:
		camera_pivot.rotate_x(-mouse_motion.y)
	else:
		camera_pivot.rotate_x(mouse_motion.y)
	camera_pivot.rotation_degrees.x = clampf(camera_pivot.rotation_degrees.x, -60.0, 40.0)
	mouse_motion = Vector2.ZERO


func cast_for_interactable() -> void:
	if vision_cast.get_collider() is Interactable:
		object_to_interact_with = vision_cast.get_collider()
		update_game_UI()
	else:
		# This works but needs refactoring so it's not closing the UI every frame
		game_ui.set_visible(false)
		ui_updated = false
		object_to_interact_with = null


func update_game_UI() -> void:
	if !ui_updated:
		game_ui.set_visible(true)
		interact_label.text = str("'E' to interact with ", object_to_interact_with.string_name)
		ui_updated = true
