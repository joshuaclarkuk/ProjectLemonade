class_name Player extends CharacterBody3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var vision_cast: RayCast3D = $CameraPivot/VisionCast
@onready var game_ui: Control = $GameUI
@onready var interact_label: Label = $GameUI/InteractLabel
@onready var money_made_label: Label = $GameUI/MoneyMadeLabel
@onready var combo_label: Label = $GameUI/MoneyMadeLabel/ComboLabel
@onready var day_timer_label_hours: Label = $GameUI/VBoxContainer/DayTimerLabelContainer/DayTimerLabelHours
@onready var day_timer_label_minutes: Label = $GameUI/VBoxContainer/DayTimerLabelContainer/DayTimerLabelMinutes
@onready var fear_bar: ProgressBar = $GameUI/FearBar

@export_range(0.001, 0.005) var mouse_sensitivity: float = 0.002
@export var combo_multiplier_to_add: float = 0.2
@export var max_fear_before_game_over: int = 20

var mouse_motion: Vector2 = Vector2.ZERO
var object_to_interact_with: Interactable = null
var interact_ui_updated: bool = false
var money_made: float = 0.0
var current_multiplier: float = 1.0
var perfect_orders_in_a_row: int = 0

var fear_amount: int = 0

signal fear_at_max


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.set_player(self)
	
	# Needs changing to be set via UI
	GameManager.is_mouse_inverted = true
	
	interact_label.set_visible(false)
	money_made = 0.0
	combo_label.set_visible(false)
	update_money_UI()
	
	# Initialise fear bar
	fear_bar.min_value = 0
	fear_bar.max_value = max_fear_before_game_over
	fear_bar.step = 1


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
		update_interact_UI()
	else:
		# This works but needs refactoring so it's not closing the UI every frame
		interact_label.set_visible(false)
		interact_ui_updated = false
		object_to_interact_with = null


func update_interact_UI() -> void:
	if !interact_ui_updated:
		interact_label.set_visible(true)
		interact_label.text = str("Left-Click to interact with ", object_to_interact_with.string_name)
		interact_ui_updated = true


func update_money_UI() -> void:
	money_made_label.text = "$%.2f" % money_made


func update_combo_UI() -> void:
	combo_label.text = "combo: x%.2f " % current_multiplier


func get_paid_and_update_UI(amount: float, was_perfect: bool) -> void:
	if was_perfect:
		perfect_orders_in_a_row += 1
		if perfect_orders_in_a_row > 1:
			current_multiplier += combo_multiplier_to_add
			update_combo_UI()
			combo_label.set_visible(true)
	else:
		combo_label.set_visible(false)
		perfect_orders_in_a_row = 0
		current_multiplier = 1.0
		
	money_made += amount * current_multiplier
	update_money_UI()


func increase_fear_amount() -> void:
	fear_amount += 1
	fear_bar.value = fear_amount
	print("Player fear amount: ", str(fear_amount))
	
	if fear_amount >= max_fear_before_game_over:
		fear_at_max.emit()


func end_day() -> void:
	game_ui.set_visible(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_physics_process(false)
