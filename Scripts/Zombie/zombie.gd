class_name Zombie extends CharacterBody3D

const CROSS = preload("res://Assets/Textures/ZombieUI/cross.png")
const TICK = preload("res://Assets/Textures/ZombieUI/tick.png")
@onready var ingredient_request_ui: Control = $IngredientRequestUI
@onready var ice_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/IceTick
@onready var sugar_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/SugarTick
@onready var lemon_tick: TextureRect = $IngredientRequestUI/Panel/GridContainer/LemonTick
@onready var time_until_money_ticks_down: Timer = $TimeUntilMoneyTicksDown


@export var walk_speed: float = 5.0
@export var max_reward: float = 0.5
@export var lowest_reward: float = 0.1

var queue_point: QueuePoint = null
var queue_point_location: Vector3 = Vector3.ZERO
var queue_point_index: int = 0
var is_moving_to_queue_point: bool = false
var is_moving_to_leave_point: bool = false
var point_to_leave: Vector3 = Vector3.ZERO

var requested_ingredient_list: Array[GameManager.LemonadeState] = []
var requested_ingredient_list_dict = {}

var is_losing_money: bool = false
var final_reward: float = 0.0

signal pay_player(amount_to_pay: float, perfect_order: bool)
signal is_at_front_of_queue
signal is_leaving_front_of_queue


func _ready() -> void:
	# Create ingredient list (Note first two options always have to be true
	requested_ingredient_list.append(GameManager.LemonadeState.EMPTY)
	requested_ingredient_list.append(GameManager.LemonadeState.LEMONADE)
	create_ingredient_request(GameManager.LemonadeState.ICE)
	create_ingredient_request(GameManager.LemonadeState.SUGAR)
	create_ingredient_request(GameManager.LemonadeState.LEMON)

	print("Requested ingredients: ", str(requested_ingredient_list))
	
	#Initialise recipe dictionary
	for ingredient in requested_ingredient_list:
		requested_ingredient_list_dict[ingredient] = false
	
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
		print(name, ": Max reward: ", str(final_reward))


func move_to_queue_point_and_display_recipe() -> void:
	var direction_to_travel = (queue_point_location - global_position).normalized()
	velocity = direction_to_travel * walk_speed
		
	move_and_slide()
		
	if global_position.distance_squared_to(queue_point_location) < 0.01:
		is_moving_to_queue_point = false
		if queue_point_index == 0:
			is_at_front_of_queue.emit()
			display_recipe_request()
			time_until_money_ticks_down.start()


func move_to_leave_point_and_disappear() -> void:
	var direction_to_travel = (point_to_leave - global_position).normalized()
	velocity = direction_to_travel * walk_speed
	
	move_and_slide()
	
	if global_position.distance_squared_to(point_to_leave) < 0.01:
		is_moving_to_leave_point = false
		print(name, ": leaving map")
		queue_free()


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
		else:
			pay_player.emit(final_reward, false)
	else:
		print("Drink NOT correct, no money received")
	
	queue_point.is_occupied = false
	is_moving_to_queue_point = false
	is_moving_to_leave_point = true
	is_leaving_front_of_queue.emit()
	ingredient_request_ui.set_visible(false)
	
	is_losing_money = false
	if !time_until_money_ticks_down.is_stopped():
		time_until_money_ticks_down.stop()


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


func _on_time_until_money_ticks_down_timeout() -> void:
	is_losing_money = true
