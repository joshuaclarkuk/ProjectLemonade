extends Control

@onready var black_fade_screen: TextureRect = $BlackFadeScreen
@onready var tick_box_texture: TextureRect = $VBoxContainer/ToggleInvertedBox/TickBoxTexture

const CROSS = preload("res://Assets/Textures/ZombieUI/cross.png")
const TICK = preload("res://Assets/Textures/ZombieUI/tick.png")

var is_inverted: bool = false


func _ready() -> void:
	tick_box_texture.texture = CROSS


func _on_start_game_button_pressed() -> void:
	black_fade_screen.modulate.a = 0.0
	black_fade_screen.set_visible(true)
	var fade_tween = create_tween()
	fade_tween.tween_property(black_fade_screen, "modulate:a", 1.0, 1.0)
	fade_tween.tween_callback(go_to_level).set_delay(1.0)


func _on_toggle_inverted_button_pressed() -> void:
	is_inverted = !is_inverted
	GameManager.set_is_mouse_inverted(is_inverted)
	if is_inverted:
		tick_box_texture.texture = TICK
	else:
		tick_box_texture.texture = CROSS


func _on_quit_game_button_pressed() -> void:
	black_fade_screen.modulate.a = 0.0
	black_fade_screen.set_visible(true)
	var fade_tween = create_tween()
	fade_tween.tween_property(black_fade_screen, "modulate:a", 1.0, 1.0)
	fade_tween.tween_callback(quit_game)


func go_to_level() -> void:
	get_tree().change_scene_to_file("res://Levels/main.tscn")


func quit_game() -> void:
	get_tree().quit()
