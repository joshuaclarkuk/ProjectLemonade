extends Node3D

@onready var overview_cam: Camera3D = $OverviewCam
@onready var player: CharacterBody3D = $Player
@onready var zombie_manager: Node3D = $ZombieManager
@onready var queue_points: Node3D = $QueuePoints
@onready var spawn_points: Node3D = $SpawnPoints
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

@export var zombie: PackedScene

var spawn_points_array: Array = []
var queue_points_array: Array[QueuePoint] = []
var zombies_spawned: int = 0
var max_zombies_to_spawn: int = 0


func _ready() -> void:
	# Populate spawn points array
	for i in spawn_points.get_children():
		spawn_points_array.append(i)
	# Populate queue points array
	for i in queue_points.get_children():
		queue_points_array.append(i)
	max_zombies_to_spawn = queue_points_array.size()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		toggle_debug_cam()

func toggle_debug_cam() -> void:
	if overview_cam.is_current():
			player.get_node("CameraPivot/SmoothCamera").set_current(true)
	else:
		overview_cam.set_current(true)


func _on_zombie_spawn_timer_timeout() -> void:
	if zombies_spawned < max_zombies_to_spawn:
			spawn_zombie()


func spawn_zombie() -> void:
	var zombie_instance = zombie.instantiate()
	zombies_spawned += 1
	zombie_manager.add_child(zombie_instance)
	var random_spawn_index = randi_range(0, 1) # Get random spawn point
	zombie_instance.global_position = spawn_points_array[random_spawn_index].global_position
	# Assign recipe
	zombie_instance.requested_ingredient_list.append(GameManager.LemonadeState.EMPTY)
	zombie_instance.requested_ingredient_list.append(GameManager.LemonadeState.LEMONADE)
	# NEED TO FIGURE OUT HOW TO ASSIGN RANDOM INGREDIENTS TO REQUEST HEREAFTER
	
	
	# Get first available queue point
	for point in queue_points_array:
		if !point.is_occupied:
			zombie_instance.set_queue_point_location(point)
			point.is_occupied = true # Will need to remember to set this to false once zombie leaves
			break
	zombie_instance.set_is_moving_to_queue_point(true)
