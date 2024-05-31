extends Node3D

@onready var move_timer: Timer = $MoveTimer
@onready var car_audio: AudioStreamPlayer3D = $CarAudio

@export var movement_speed: float = 3.0

var starting_volume: float = -80.0
var running_volume: float = 0.0
var is_moving: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var time_to_wait = randf_range(20.0, 40.0)
	move_timer.wait_time = time_to_wait
	move_timer.start()
	car_audio.volume_db = -80.0


func _process(delta: float) -> void:
	if is_moving:
		global_position.x -= movement_speed * delta
	
	if global_position.x <= -120.0:
		queue_free()


func _on_move_timer_timeout() -> void:
	is_moving = true
	var tween = create_tween()
	tween.tween_property(car_audio, "volume_db", running_volume, 2.0)
