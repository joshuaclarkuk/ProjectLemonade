class_name SplashScreen extends Control

# Splash Screens
@onready var blank_splash: TextureRect = $BlankSplash
@onready var godot_splash: TextureRect = $GodotSplash
@onready var waiting_games_splash: TextureRect = $WaitingGamesSplash
@onready var black_splash: TextureRect = $BlackSplash

#Timers
@onready var black_timer: Timer = $BlackSplash/BlackTimer
@onready var waiting_timer: Timer = $WaitingGamesSplash/WaitingTimer
@onready var godot_timer: Timer = $GodotSplash/GodotTimer
@onready var final_timer: Timer = $FinalTimer

@onready var crowd_audio_player: AudioStreamPlayer = $CrowdAudioPlayer
@onready var splash_music: AudioStreamPlayer = $SplashMusic

@export var fade_time: float = 1.0


func _ready() -> void:
	blank_splash.set_visible(true)
	black_splash.set_visible(true)
	godot_splash.set_visible(false)
	waiting_games_splash.set_visible(true)
	black_timer.start()
	splash_music.play()
	
	crowd_audio_player.volume_db = -60.0
	var tween = create_tween()
	tween.tween_property(crowd_audio_player, "volume_db", -16.0, 0.8)


func _on_black_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(black_splash, "modulate:a", 0.0, fade_time)
	tween.connect("finished", start_waiting_splash_fade)


func start_waiting_splash_fade() -> void:
	waiting_timer.start()


func _on_waiting_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(waiting_games_splash, "modulate:a", 0.0, fade_time)
	tween.connect("finished", start_godot_splash_fade_in)

func start_godot_splash_fade_in() -> void:
	godot_splash.modulate.a = 0.0
	godot_splash.set_visible(true)
	var tween = create_tween()
	tween.tween_property(godot_splash, "modulate:a", 1.0, fade_time)
	tween.connect("finished", start_godot_splash_fade_out)

func start_godot_splash_fade_out() -> void:
	godot_timer.start()


func _on_godot_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(godot_splash, "modulate:a", 0.0, fade_time)
	tween.connect("finished", fade_black_screen_back_in)


func fade_black_screen_back_in() -> void:
	var tween = create_tween()
	tween.tween_property(black_splash, "modulate:a", 1.0, fade_time)
	tween.connect("finished", go_to_main_menu)
	var audio_tween = create_tween()
	audio_tween.tween_property(crowd_audio_player, "volume_db", -80.0, 4.0)


func go_to_main_menu() -> void:
	final_timer.start()


func _on_final_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Levels/main_menu.tscn")
