class_name Zombie extends CharacterBody3D

@export var walk_speed: float = 5.0

var queue_point: QueuePoint = null
var queue_point_location: Vector3 = Vector3.ZERO
var is_moving_to_queue_point: bool = false

var requested_ingredient_list: Array[GameManager.LemonadeState] = []


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if is_moving_to_queue_point:
		var direction_to_travel = (queue_point_location - global_position).normalized()
		velocity = direction_to_travel * walk_speed
	
		move_and_slide()
		
		if global_position.distance_squared_to(queue_point_location) < 0.01:
			is_moving_to_queue_point = false


func set_queue_point_location(point: QueuePoint) -> void:
	queue_point = point
	queue_point_location = point.global_position


func set_is_moving_to_queue_point(is_moving: bool) -> void:
	is_moving_to_queue_point = is_moving
