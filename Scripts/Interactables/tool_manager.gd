class_name ToolManager extends Node3D

@onready var glasses: Interactable = $Glasses
@onready var serving_stand: Interactable = $ServingStand
@onready var ice: Interactable = $Ice
@onready var bin: Interactable = $Bin
@onready var jug: Interactable = $Jug
@onready var sugar: Interactable = $Sugar
@onready var lemons: Interactable = $Lemons
@onready var glass_real: CSGCylinder3D = $Glasses/GlassReal
@onready var cup_holder: CSGCylinder3D = $ServingStand/Mesh/CupHolder
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pop_audio: AudioStreamPlayer = $AudioPlayers/PopAudio
@onready var glass_audio: AudioStreamPlayer3D = $AudioPlayers/GlassAudio
@onready var spill_audio: AudioStreamPlayer3D = $AudioPlayers/SpillAudio

var serving_stand_empty: bool = true
var can_serve_zombie: bool = false
var glass_real_original_position: Vector3 = Vector3.ZERO
var current_lemonade_state: int = 0
var ingredients_in_glass: Array[GameManager.LemonadeState] = []
# Glass colours
var stage_1_colour_value: float = 0.2
var stage_2_colour_value: float = 0.4
var stage_3_colour_value: float = 0.6
var stage_4_colour_value: float = 0.8
var stage_5_colour_value: float = 1.0

signal drink_served(ingredients_served)
signal mistake_made
signal binned_drink


func _ready() -> void:
	# Connect signals from tools to tool manager
	glasses.interacted_with.connect(handle_glasses)
	serving_stand.interacted_with.connect(handle_serving_stand)
	ice.interacted_with.connect(handle_ice)
	bin.interacted_with.connect(handle_bin)
	jug.interacted_with.connect(handle_jug)
	sugar.interacted_with.connect(handle_sugar)
	lemons.interacted_with.connect(handle_lemons)
	
	# Initialise "real" glass
	glass_real_original_position = glass_real.global_position
	
	# Set first state
	current_lemonade_state = GameManager.LemonadeState.NOT_STARTED


func handle_glasses() -> void:
		if serving_stand_empty:
			pop_audio.play()
			glass_audio.play()
			var position_to_place_glass = cup_holder.global_position
			position_to_place_glass.y += 0.1 # Adding half the height of mesh so it sits correctly
			glass_real.global_position = position_to_place_glass
			serving_stand_empty = false
			update_glass_state(GameManager.LemonadeState.EMPTY, stage_1_colour_value)
		else:
			spill_drink()


func handle_jug() -> void:
	if !serving_stand_empty:
		if !animation_player.is_playing():
			animation_player.play("pour_from_jug")
		print("Lemonade added")
		update_glass_state(GameManager.LemonadeState.LEMONADE, stage_2_colour_value)
	else:
		print("Serving Stand empty. Grab a glass!")


func handle_ice() -> void:
	if !serving_stand_empty:
		if !animation_player.is_playing():
			animation_player.play("get_ice")
		print("Ice added")
		update_glass_state(GameManager.LemonadeState.ICE, stage_3_colour_value)
	else:
		print("Serving Stand empty. Grab a glass!")


func handle_sugar() -> void:
	if !serving_stand_empty:
		if !animation_player.is_playing():
			animation_player.play("pour_sugar")
		print("Sugar added")
		update_glass_state(GameManager.LemonadeState.SUGAR, stage_4_colour_value)
	else:
		print("Serving Stand empty. Grab a glass!")


func handle_lemons() -> void:
	if !serving_stand_empty:
		if !animation_player.is_playing():
			animation_player.play("slice_lemons")
		print("Lemon slices added")
		update_glass_state(GameManager.LemonadeState.LEMON, stage_5_colour_value)
	else:
		print("Serving Stand empty. Grab a glass!")


func handle_serving_stand() -> void:
	if serving_stand_empty:
		print("Serving Stand empty. Grab a glass!")
	else:
		serve_drink()


func handle_bin() -> void:
	if serving_stand_empty: return
	
	if !animation_player.is_playing():
		animation_player.play("use_bin")
	print("Binned drink. Start again")
	binned_drink.emit()
	reset_drink()


func serve_drink() -> void:
	if can_serve_zombie:
		print("DRINK SERVED")
		drink_served.emit(ingredients_in_glass)
		# Handle zombie code here
		print("Drink contained: ", str(ingredients_in_glass))
		# Reset values
		reset_drink()


func spill_drink() -> void:
	print("DRINK SPILLED")
	spill_audio.play()
	mistake_made.emit()
	# Play spilled animation
	reset_drink()


func update_glass_state(lemonade_state: GameManager.LemonadeState, glass_colour: float) -> void:
	glass_real.get_material_override().albedo_color = Color(glass_colour, glass_colour, glass_colour)
	current_lemonade_state = lemonade_state
	if !ingredients_in_glass.has(lemonade_state):
		ingredients_in_glass.append(lemonade_state)
	else:
		print("Ingredient already added, drink ruined!")
		spill_drink() # Spill if same ingredient added twice


func reset_drink() -> void:
	glass_real.global_position = glass_real_original_position
	serving_stand_empty = true
	current_lemonade_state = GameManager.LemonadeState.NOT_STARTED
	ingredients_in_glass.clear()


func set_can_serve_zombie(can_serve: bool) -> void:
	can_serve_zombie = can_serve
	print("Can serve zombie: ", str(can_serve_zombie))
