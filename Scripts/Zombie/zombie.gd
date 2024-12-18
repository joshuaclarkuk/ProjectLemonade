class_name Zombie extends CharacterBody3D

const CROSS = preload("res://Assets/Textures/ZombieUI/cross.png")
const TICK = preload("res://Assets/Textures/ZombieUI/tick.png")

# Zombie audio
const TOM_ZOMBIE_ANGRY = preload("res://Assets/SFX/Zombie/Tom/Tom Zombie angry.ogg")
const TOM_ZOMBIE_ECSTATIC = preload("res://Assets/SFX/Zombie/Tom/Tom Zombie ecstatic.ogg")
const TOM_ZOMBIE_HAPPY = preload("res://Assets/SFX/Zombie/Tom/Tom Zombie happy.ogg")
const TOM_ZOMBIE_NORMAL = preload("res://Assets/SFX/Zombie/Tom/Tom Zombie normal.ogg")

@onready var ingredient_request_ui: Control = $IngredientRequestUI
@onready var ice_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/IceTick
@onready var sugar_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/SugarTick
@onready var lemon_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/LemonTick
@onready var time_until_money_ticks_down: Timer = $TimeUntilMoneyTicksDown
@onready var wait_in_queue_timer: Timer = $WaitInQueueTimer
@onready var wait_in_queue_panel: PanelContainer = $WaitInQueueUI/WaitInQueuePanel
@onready var wait_in_queue_radial: TextureProgressBar = $WaitInQueueUI/WaitInQueuePanel/WaitInQueueRadial
@onready var boo_audio: AudioStreamPlayer = $BooAudio
@onready var fart_component: Node3D = $FartComponent
@onready var animated_mesh: Node3D = $AnimatedMesh
@onready var zombie_noise_audio: AudioStreamPlayer3D = $ZombieNoiseAudio

@export var walk_speed: float = 5.0
@export var max_reward: float = 0.5
@export var lowest_reward: float = 0.1

var character_collider: CollisionShape3D
var animation_player: AnimationPlayer

var queue_point: QueuePoint = null
var queue_point_location: Vector3 = Vector3.ZERO
var queue_point_index: int = 0
var is_moving_to_queue_point: bool = false
var is_moving_to_leave_point: bool = false
var point_to_leave: Vector3 = Vector3.ZERO

var requested_ingredient_list: Array[GameManager.LemonadeState] = []
var requested_ingredient_list_dict = {}

# Zombie sound arrays
var zombie_normal_sound_array: Array[AudioStream] = []
var zombie_happy_sound_array: Array[AudioStream] = []
var zombie_ecstatic_sound_array: Array[AudioStream] = []
var zombie_angry_sound_array: Array[AudioStream] = []

var is_losing_money: bool = false
var final_reward: float = 0.0
var day_is_ended: bool = false

signal pay_player(amount_to_pay: float, perfect_order: bool)
signal correct_drink_served
signal mistake_made
signal is_at_front_of_queue
signal is_leaving_front_of_queue
signal issue_fear_signal


func _ready() -> void:
	# Get references
	character_collider = get_node("Collider")
	animation_player = animated_mesh.get_node("AnimationPlayer")
	
	# Create ingredient list (Note first two options always have to be true
	requested_ingredient_list.append(GameManager.LemonadeState.EMPTY)
	requested_ingredient_list.append(GameManager.LemonadeState.LEMONADE)
	create_ingredient_request(GameManager.LemonadeState.ICE)
	create_ingredient_request(GameManager.LemonadeState.SUGAR)
	create_ingredient_request(GameManager.LemonadeState.LEMON)

	print("Requested ingredients: ", str(requested_ingredient_list))
	
	# Load audio
	zombie_normal_sound_array.append(TOM_ZOMBIE_NORMAL)
	zombie_happy_sound_array.append(TOM_ZOMBIE_ECSTATIC)
	zombie_ecstatic_sound_array.append(TOM_ZOMBIE_HAPPY)
	zombie_angry_sound_array.append(TOM_ZOMBIE_ANGRY)
	
	# Initialise recipe dictionary
	for ingredient in requested_ingredient_list:
		requested_ingredient_list_dict[ingredient] = false
	
	# Initialise UI elements
	wait_in_queue_radial.set_visible(false)
	ingredient_request_ui.set_visible(false)
	final_reward = max_reward


func _physics_process(delta: float) -> void:
	if is_moving_to_queue_point:
		move_to_queue_point_and_display_recipe()
	
	if is_moving_to_leave_point:
		move_to_leave_point_and_disappear()
	
	# Run countdown timer when being served
	if is_losing_money:
		final_reward -= 0.1 * delta # Removes ten cents every second
		if final_reward < lowest_reward:
			final_reward = lowest_reward
	
	# Update patience timer radial
	if !wait_in_queue_timer.is_stopped():
		wait_in_queue_radial.value = wait_in_queue_timer.time_left
		update_radial_timer_position()


func move_to_queue_point_and_display_recipe() -> void:
	if !wait_in_queue_timer.is_stopped():
		wait_in_queue_timer.stop()
		wait_in_queue_radial.set_visible(false)
	
	var direction_to_travel = (queue_point_location - global_position).normalized()
	animation_player.play("Zombie_Run")
	look_at_target(direction_to_travel)
	velocity = direction_to_travel * walk_speed
		
	move_and_slide()
		
	if global_position.distance_squared_to(queue_point_location) < 0.01:
		is_moving_to_queue_point = false
		animation_player.play("Zombie_Idle")
		look_at_target(Vector3(0.1, 1.0, 7.0))
		if queue_point_index == 0:
			is_at_front_of_queue.emit()
			display_recipe_request()
			time_until_money_ticks_down.start()
			play_zombie_noise(zombie_normal_sound_array)
		# Queue Timer Stuff
		else:
			if !day_is_ended:
				wait_in_queue_timer.start()
				wait_in_queue_radial.set_visible(true)


func move_to_leave_point_and_disappear() -> void:
	var direction_to_travel = (point_to_leave - global_position).normalized()
	animation_player.play("Zombie_Run")
	look_at_target(direction_to_travel)
	velocity = direction_to_travel * walk_speed
	
	move_and_slide()
	
	if global_position.distance_squared_to(point_to_leave) < 0.01:
		is_moving_to_leave_point = false
		print(name, ": leaving map")
		queue_free()


func look_at_target(direction: Vector3) -> void:
	var adjusted_direction = direction
	adjusted_direction.y = 0.0
	look_at(global_position + adjusted_direction, Vector3.UP)


func create_ingredient_request(state_to_add_if_true: GameManager.LemonadeState) -> void:
	var wants_ingredient = true
	if randi() % 2:
		wants_ingredient = false
	if wants_ingredient:
		requested_ingredient_list.append(state_to_add_if_true)


func set_queue_point_location(point: QueuePoint) -> void:
	queue_point = point
	queue_point_location = point.global_position
	queue_point_index = point.queue_point_index
	print(name, ": QPI: ", str(queue_point_index))
	point.occupying_zombie = self
	print(point.name, " is occupied by: ", self.name)


func be_served_drink(ingredients_in_drink: Array[GameManager.LemonadeState]) -> void:
		var all_ingredients_correct = true
		# ABSOLUTELY NOT SURE HOW THIS IS GOING TO WORK
		# Reset the dictionary to all false values before checking to stop repeat checks
		for key in requested_ingredient_list_dict.keys():
			requested_ingredient_list_dict[key] = false
			
		# Check each ingredient in the drink against the requested list
		for ingredient_in_drink in ingredients_in_drink:
			if ingredient_in_drink in requested_ingredient_list_dict:
				requested_ingredient_list_dict[ingredient_in_drink] = true
				print(str(requested_ingredient_list_dict[ingredient_in_drink]), ": changed to TRUE")
			else:
				print(name, ": Ingredient: ", str(ingredient_in_drink), " should not be in drink")
				all_ingredients_correct = false
				drink_and_move_on(false)
				return # Exit early since there is an extra ingredient
		
		# Check if any requested ingredients are still false
		for dict_ingredient in requested_ingredient_list_dict.keys():
			if not requested_ingredient_list_dict[dict_ingredient]:
				printerr(name, ": Ingredient not found: ", dict_ingredient)
				all_ingredients_correct = false
				drink_and_move_on(false)
				return  # Exit early since an ingredient is missing

		# If no issues were found, all ingredients are correct
		if all_ingredients_correct:
			drink_and_move_on(true)


func drink_and_move_on(drink_correct: bool) -> void:
	if drink_correct:
		print("Drink correct, ", str("$%.2f" % final_reward), " awarded")
		if final_reward == max_reward:
			pay_player.emit(final_reward, true)
			correct_drink_served.emit()
			play_zombie_noise(zombie_ecstatic_sound_array)
		else:
			pay_player.emit(final_reward, false)
			correct_drink_served.emit()
			play_zombie_noise(zombie_happy_sound_array)
	else:
		print("Drink NOT correct, ", name, ": emitted fear signal")
		issue_fear_signal.emit()
		mistake_made.emit()
		var random_boo_pitch = randi_range(0.8, 1.2)
		boo_audio.pitch_scale = random_boo_pitch
		boo_audio.play()
		play_zombie_noise(zombie_angry_sound_array)
	
	queue_point.is_occupied = false
	is_moving_to_queue_point = false
	is_moving_to_leave_point = true
	is_leaving_front_of_queue.emit()
	ingredient_request_ui.set_visible(false)
	
	is_losing_money = false
	if !time_until_money_ticks_down.is_stopped():
		time_until_money_ticks_down.stop()


func play_zombie_noise(sound_array: Array) -> void:
	zombie_noise_audio.pitch_scale = 1 # Need to reset this for some reason otherwise it gets lower and lower
	var random_pitch = randf_range(0.6, 1.0)
	zombie_noise_audio.pitch_scale = random_pitch
	zombie_noise_audio.stream = sound_array[randi_range(0, sound_array.size() - 1)]
	zombie_noise_audio.play()


func display_recipe_request() -> void:
	assign_tick_or_cross(GameManager.LemonadeState.ICE, ice_tick)
	assign_tick_or_cross(GameManager.LemonadeState.SUGAR, sugar_tick)
	assign_tick_or_cross(GameManager.LemonadeState.LEMON, lemon_tick)
	
	ingredient_request_ui.set_visible(true)


func assign_tick_or_cross(ingredient: GameManager.LemonadeState, tick_texture: TextureRect) -> void:
	if requested_ingredient_list.has(ingredient):
		tick_texture.texture = TICK
	else:
		tick_texture.texture = CROSS


func update_radial_timer_position() -> void:
	var panel_size = Vector2(wait_in_queue_panel.get_size().x / 2, wait_in_queue_panel.get_size().y)
	#var height_of_zombie_head: Vector3 = Vector3(global_position + Vector3(0.0, character_collider.get_shape().get_height(), 0.0))
	var height_of_zombie_head: Vector3 = Vector3(global_position + Vector3(0.0, 0.0, 0.0))
	wait_in_queue_panel.set_position(GameManager.player_camera.unproject_position(height_of_zombie_head) - panel_size)


func _on_time_until_money_ticks_down_timeout() -> void:
	is_losing_money = true


func _on_wait_in_queue_timer_timeout() -> void:
	if !day_is_ended:
		issue_fear_signal.emit()
		print(name, ": emitted fear signal")
		wait_in_queue_timer.start()


func end_day() -> void:
	day_is_ended = true
	if !wait_in_queue_timer.is_stopped():
		wait_in_queue_timer.stop()
	
	fart_component.fart_timer.stop()
	
	wait_in_queue_radial.set_visible(false)
	
	if ingredient_request_ui.is_visible():
		ingredient_request_ui.set_visible(false)
	set_physics_process(false)
