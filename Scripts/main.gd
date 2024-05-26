extends Node3D

@onready var overview_cam: Camera3D = $OverviewCam
@onready var player: CharacterBody3D = $Player
@onready var zombie_manager: Node3D = $ZombieManager
@onready var queue_points: Node3D = $QueuePoints
@onready var spawn_points: Node3D = $SpawnPoints
@onready var leave_points: Node3D = $LeavePoints
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer
@onready var lemonade_stand: CSGBox3D = $LemonadeStand

@export var zombie: PackedScene

var tool_manager: ToolManager
var spawn_points_array: Array = []
var queue_points_array: Array[QueuePoint] = []
var leave_points_array: Array[Marker3D] = []
var zombies_spawned: int = 0
var max_zombies_to_spawn: int = 0
var zombie_array: Array[Zombie] = []


func _ready() -> void:
	# Get reference to Tool_Manager
	tool_manager = lemonade_stand.get_node("ObjectManager")
	if !tool_manager:
		printerr("Couldn't find ToolManager!")
	
	# Populate spawn points array
	for i in spawn_points.get_children():
		spawn_points_array.append(i)
	# Populate queue points array
	for i in queue_points.get_children():
		queue_points_array.append(i)
	# Populate leave points array
	for i in leave_points.get_children():
		leave_points_array.append(i)
		print(i.name)
	
	# Set queue points indices
	for index in range(queue_points_array.size()):
		var point = queue_points_array[index]
		point.queue_point_index = index
		print(point.name, " queue point index: ", str(point.queue_point_index))
	
	max_zombies_to_spawn = queue_points_array.size()
	print("Max zombies to spawn: ", str(max_zombies_to_spawn))
	
	tool_manager.drink_served.connect(serve_zombie_at_front_of_queue)


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
	
	# Determine leave point
	var random_leave_point_index = randi_range(0, leave_points_array.size() - 1)
	zombie_instance.point_to_leave = leave_points_array[random_leave_point_index].global_position
	
	# Get first available queue point
	for point in queue_points_array:
		if !point.is_occupied:
			zombie_instance.set_queue_point_location(point)
			point.is_occupied = true # Will need to remember to set this to false once zombie leaves
			break
	zombie_instance.is_moving_to_queue_point = true
	
	# Populate array
	zombie_array.append(zombie_instance)


func serve_zombie_at_front_of_queue(ingredients_in_drink: Array[GameManager.LemonadeState]) -> void:
	queue_points_array[0].occupying_zombie.be_served_drink(ingredients_in_drink)
	shuffle_zombies_forward(queue_points_array[0].occupying_zombie)


func shuffle_zombies_forward(served_zombie: Zombie) -> void:
	zombie_array.erase(served_zombie) # Remove zombie at front of queue from pool of moving candidates
	zombies_spawned -= 1
	
	for zombie in zombie_array:
		for point in queue_points_array:
			if !point.is_occupied:
				print(zombie.name, ": is moving to: ", str(point.name))
				zombie.queue_point.is_occupied = false
				zombie.set_queue_point_location(point)
				point.is_occupied = true # Will need to remember to set this to false once zombie leaves
				break
		zombie.is_moving_to_queue_point = true
