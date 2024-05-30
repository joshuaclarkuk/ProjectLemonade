extends Node3D

@onready var fart_timer: Timer = $FartTimer
@onready var fart_audio: AudioStreamPlayer3D = $FartAudio
@onready var fart_particles: GPUParticles3D = $FartParticles

const FART_7 = preload("res://Assets/SFX/Zombie/Farts/Fart7.wav")
const FART_17 = preload("res://Assets/SFX/Zombie/Farts/Fart17.wav")
const FART_54 = preload("res://Assets/SFX/Zombie/Farts/Fart54.wav")
const FART_68 = preload("res://Assets/SFX/Zombie/Farts/Fart68.wav")
const LONG_FART = preload("res://Assets/SFX/Zombie/Farts/LongFart.wav")
const MED_FART = preload("res://Assets/SFX/Zombie/Farts/MedFart.wav")
const SHORT_FART = preload("res://Assets/SFX/Zombie/Farts/ShortFart.wav")

var fart_array: Array[AudioStream] = []
var has_already_farted: bool = false


func _ready() -> void:
	# Populate fart array
	fart_array.append(FART_7)
	fart_array.append(FART_17)
	fart_array.append(FART_54)
	fart_array.append(FART_68)
	fart_array.append(LONG_FART)
	fart_array.append(MED_FART)
	fart_array.append(SHORT_FART)
	
	fart_timer.wait_time = randi_range(10.0, 120.0)
	print("Fart timer wait time: ", str(fart_timer.wait_time))
	
	fart_timer.start()


func _on_fart_timer_timeout() -> void:
	if !has_already_farted:
		fart()


func fart() -> void:
	has_already_farted = true
	fart_particles.restart()
	var random_fart_index = randi_range(0, fart_array.size() - 1)
	var random_fart_pitch = randi_range(0.8, 1.2)
	fart_audio.stream = fart_array[random_fart_index]
	fart_audio.pitch_scale = random_fart_pitch
	fart_audio.play()
	var new_wait_time = randi_range(10.0, 120.0)
	fart_timer.wait_time = new_wait_time
	fart_timer.start()
