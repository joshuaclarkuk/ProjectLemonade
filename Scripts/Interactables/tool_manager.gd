extends Node3D

enum LemonadeState {
	EMPTY,
	ICE,
	LEMONADE,
	SUGAR,
	LEMON
}

@onready var glasses: Interactable = $Glasses
@onready var serving_stand: Interactable = $ServingStand
@onready var ice: Interactable = $Ice
@onready var bin: Interactable = $Bin
@onready var jug: Interactable = $Jug
@onready var sugar: Interactable = $Sugar
@onready var lemons: Interactable = $Lemons

var serving_stand_empty: bool = true



func _ready() -> void:
	glasses.interacted_with.connect(handle_glasses)
	serving_stand.interacted_with.connect(handle_serving_stand)
	ice.interacted_with.connect(handle_ice)
	bin.interacted_with.connect(handle_bin)
	jug.interacted_with.connect(handle_jug)
	sugar.interacted_with.connect(handle_sugar)
	lemons.interacted_with.connect(handle_lemons)


func handle_glasses() -> void:
	print("Interacted with: Glasses")


func handle_serving_stand() -> void:
	print("Interacted with: Serving Stand")


func handle_ice() -> void:
	print("Interacted with: Ice")


func handle_bin() -> void:
	print("Interacted with: Bin")


func handle_jug() -> void:
	print("Interacted with: Jug")


func handle_sugar() -> void:
	print("Interacted with: Sugar")


func handle_lemons() -> void:
	print("Interacted with: Lemons")
