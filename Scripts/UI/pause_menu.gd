extends Control

var is_game_paused: bool = false


func _ready() -> void:
	set_visible(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if !is_game_paused:
			toggle_pause(true)


func toggle_pause(is_paused: bool) -> void:
	is_game_paused = is_paused
	set_visible(is_paused)
	get_tree().paused = is_paused
	
	if is_game_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_button_pressed() -> void:
	toggle_pause(false)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
