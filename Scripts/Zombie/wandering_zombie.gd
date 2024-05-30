extends CharacterBody3D

@onready var animated_mesh: Node3D = $AnimatedMesh

var animation_player: AnimationPlayer
var is_walking_left: bool = false
var direction: Vector3 = Vector3.ZERO
var speed = 0.2


func _ready() -> void:
	# Get reference to animator
	animation_player = animated_mesh.get_node("AnimationPlayer")
	speed = randf_range(0.2, 0.5)
	set_walk_direction()


func _physics_process(delta: float) -> void:
	if global_position.x <= -35.0:
		global_position.x = -30.0
		set_walk_direction()
	if global_position.x >= 35.0:
		global_position.x = 30.0
		set_walk_direction()
	
	if is_walking_left:
		direction = (Vector3(-1.0, 0.0, 0.0))
		look_at(transform.origin + velocity, Vector3.UP)
	else:
		direction = (Vector3(1.0, 0, 0.0))
		look_at(transform.origin + velocity, Vector3.UP)
		
	if direction:
		animation_player.play("Zombie_Walk0", -1, speed * 5)
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


func set_walk_direction() -> void:
	var walk_direction_choice: int = randi_range(0, 1)
	if walk_direction_choice == 0:
		is_walking_left = true
		
	else:
		is_walking_left = false
		
