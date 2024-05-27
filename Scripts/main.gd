extends Node3D

@onready var overview_cam: Camera3D = $OverviewCam
@onready var player: CharacterBody3D = $Player
@onready var zombie_manager: Node3D = $ZombieManager
@onready var queue_points: Node3D = $QueuePoints
@onready var spawn_points: Node3D = $SpawnPoints
@onready var leave_points: Node3D = $LeavePoints
@onready var zombie_spawn_timer: Timer = $Timers/ZombieSpawnTimer
@onready var lemonade_stand: CSGBox3D = $LemonadeStand
@onready var end_day_screen: Control = $EndDayScreen
@onready var s_texture: TextureRect = $EndDayScreen/sTexture
@onready var display_s_timer: Timer = $EndDayScreen/DisplaySTimer
@onready var money_earned_label: Label = $EndDayScreen/MoneyEarnedLabel
@onready var display_money_earned_timer: Timer = $EndDayScreen/DisplayMoneyEarnedTimer

@export_category("Spawn Variables")
@export var zombie: PackedScene
@export var zombie_spawn_timer_wait_time: float = 15.0
@export var lowest_spawn_time: float = 3.0

# Populate Spawn arrays
var tool_manager: ToolManager
var spawn_points_array: Array = []
var queue_points_array: Array[QueuePoint] = []
var leave_points_array: Array[Marker3D] = []
var zombies_spawned: int = 0
var max_zombies_to_spawn: int = 0
var zombie_array: Array[Zombie] = []
var spawn_timer_increased: bool = false

# Day/Night variables
@export_category("Day/Night Variables")
@export_range(6.0, 360.0) var max_time_in_day: float = 180.0
var time_left_in_day: float = 0.0
var is_time_running: bool = false
var hours
var minutes
# Start and end times in minutes since midnight
const START_TIME = 7 * 60  # 07:00
const END_TIME = 19 * 60   # 19:00
const TOTAL_GAME_MINUTES = END_TIME - START_TIME

signal day_has_ended()


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
	
	# Spawn zombie to queue position
	zombie_spawn_timer.wait_time = zombie_spawn_timer_wait_time
	max_zombies_to_spawn = queue_points_array.size()
	print("Max zombies to spawn: ", str(max_zombies_to_spawn))
	
	#Initialise day/night variables
	time_left_in_day = max_time_in_day
	is_time_running = true
	
	# Initialise UI
	end_day_screen.set_visible(false)
	
	# Connect signals
	tool_manager.drink_served.connect(serve_zombie_at_front_of_queue)
	day_has_ended.connect(player.end_day)


func _process(delta: float) -> void:
	if is_time_running:
		pass_time_and_update_game_clock(delta)
		decrease_spawn_time_throughout_day() # Decreases the spawn time every hour
		if time_left_in_day <= 0.0:
			end_day()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		toggle_debug_cam()

func toggle_debug_cam() -> void:
	if overview_cam.is_current():
			player.get_node("CameraPivot/SmoothCamera").set_current(true)
	else:
		overview_cam.set_current(true)


func pass_time_and_update_game_clock(delta: float) -> void:
	time_left_in_day -= delta
	if time_left_in_day <= 0.0:
		is_time_running = false
		time_left_in_day = 0.0 # End of day
	
	# Calculate the elapsed fraction of the game day
	var elapsed_fraction = (max_time_in_day - time_left_in_day) / max_time_in_day
	
	# Calculate the current in-game time in minutes since midnight
	var current_game_minutes = START_TIME + elapsed_fraction * TOTAL_GAME_MINUTES
	
	# Convert to hours and minutes
	hours = int(current_game_minutes) / 60
	minutes = int(current_game_minutes) % 60
	
	# Update the labels
	player.day_timer_label_minutes.text = "%02d" % minutes
	player.day_timer_label_hours.text = "%02d" % hours


func decrease_spawn_time_throughout_day() -> void:
	if minutes == 0.0 and !spawn_timer_increased:
		spawn_timer_increased = true
		zombie_spawn_timer.wait_time -= 1
		print("New spawn delay: ", str(zombie_spawn_timer.wait_time))
	elif minutes > 1.0 and spawn_timer_increased:
		spawn_timer_increased = false
		print("Spawn timer ready to be increased again. Spawn time is now: ", str(zombie_spawn_timer.wait_time))


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
	
	# Connect payment signal with player
	zombie_instance.pay_player.connect(player.get_paid_and_update_UI)
	zombie_instance.is_at_front_of_queue.connect(tool_manager.set_can_serve_zombie.bind(true)) # Prevents game-breaking bug where you serve an empty space
	zombie_instance.is_leaving_front_of_queue.connect(tool_manager.set_can_serve_zombie.bind(false))
	day_has_ended.connect(zombie_instance.end_day)


func serve_zombie_at_front_of_queue(ingredients_in_drink: Array[GameManager.LemonadeState]) -> void:
	if queue_points_array[0].occupying_zombie:
		queue_points_array[0].occupying_zombie.be_served_drink(ingredients_in_drink)
		shuffle_zombies_forward(queue_points_array[0].occupying_zombie)


func shuffle_zombies_forward(served_zombie: Zombie) -> void:
	zombie_array.erase(served_zombie) # Remove zombie at front of queue from pool of moving candidates
	zombies_spawned -= 1
	
	for each_zombie in zombie_array:
		for point in queue_points_array:
			if !point.is_occupied:
				print(each_zombie.name, ": is moving to: ", str(point.name))
				each_zombie.queue_point.is_occupied = false
				each_zombie.set_queue_point_location(point)
				point.is_occupied = true # Will need to remember to set this to false once zombie leaves
				break
		each_zombie.is_moving_to_queue_point = true


func end_day() -> void:
	day_has_ended.emit()
	display_s_timer.start()
	display_money_earned_timer.start()
	s_texture.set_visible(false)
	money_earned_label.set_visible(false)
	end_day_screen.set_visible(true)


func _on_display_s_timer_timeout() -> void:
	s_texture.set_visible(true)


func _on_display_money_earned_timer_timeout() -> void:
	money_earned_label.text = "$%.2f" % player.money_made
	money_earned_label.set_visible(true)
