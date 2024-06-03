extends Node3D

const LEMONADE_SONG = preload("res://Assets/Music/Lemonade Song.ogg")
const MAIN_LOOP = preload("res://Assets/Music/MainLoop.wav")
const CROSS = preload("res://Assets/Textures/ZombieUI/cross.png")
const TICK = preload("res://Assets/Textures/ZombieUI/tick.png")

@onready var bgm_player: AudioStreamPlayer = $AudioPlayers/BGMPlayer
@onready var black_fade_screen: TextureRect = $MenuUI/BlackFadeScreen
@onready var tick_box_texture: TextureRect = $MenuUI/ToggleInvertedBox/TickBoxTexture
@onready var menu_ui: Control = $MenuUI
@onready var credits_ui: Control = $CreditsUI


func _ready() -> void:
	switch_audio(MAIN_LOOP)
	
	menu_ui.set_visible(true)
	credits_ui.set_visible(false)
	
	if GameManager.is_mouse_inverted:
		tick_box_texture.texture = TICK
	else:
		tick_box_texture.texture = CROSS


func _on_start_game_button_pressed() -> void:
	black_fade_screen.modulate.a = 0.0
	black_fade_screen.set_visible(true)
	var fade_tween = create_tween()
	fade_tween.tween_property(black_fade_screen, "modulate:a", 1.0, 1.0)
	fade_tween.tween_callback(go_to_level).set_delay(1.0)


func _on_toggle_inverted_button_pressed() -> void:
	GameManager.is_mouse_inverted = !GameManager.is_mouse_inverted
	if GameManager.is_mouse_inverted:
		tick_box_texture.texture = TICK
	else:
		tick_box_texture.texture = CROSS


func _on_quit_game_button_pressed() -> void:
	black_fade_screen.modulate.a = 0.0
	black_fade_screen.set_visible(true)
	var fade_tween = create_tween()
	fade_tween.tween_property(black_fade_screen, "modulate:a", 1.0, 1.0)
	fade_tween.tween_callback(quit_game)

func switch_audio(audio: Resource) -> void:
	bgm_player.stop()
	bgm_player.stream = audio
	bgm_player.play()


func _on_credits_button_pressed() -> void:
	menu_ui.set_visible(false)
	credits_ui.set_visible(true)
	switch_audio(LEMONADE_SONG)


func _on_return_to_menu_button_pressed() -> void:
	credits_ui.set_visible(false)
	menu_ui.set_visible(true)
	switch_audio(MAIN_LOOP)


func go_to_level() -> void:
	get_tree().change_scene_to_file("res://Levels/main.tscn")


func quit_game() -> void:
	get_tree().quit()





