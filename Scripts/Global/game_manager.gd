extends Node

enum ToolType {
	ICE_CUBES,
	LEMONADE_JUG,
	GLASSES,
	BIN,
	SUGAR,
	SERVING_STAND,
	LEMONS
}

enum LemonadeState {
	NOT_STARTED,
	EMPTY,
	LEMONADE,
	ICE,
	SUGAR,
	LEMON
}

var player: Player
var player_camera: Camera3D

var is_mouse_inverted: bool = false


func set_player(new_player: Player) -> void:
	player = new_player


func set_camera(new_camera: Camera3D) -> void:
	player_camera = new_camera
