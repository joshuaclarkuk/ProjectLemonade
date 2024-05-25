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

var is_mouse_inverted: bool = false
