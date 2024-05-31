extends CharacterBody3D

@onready var animated_mesh: Node3D = $AnimatedMesh

var animation_player: AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player = animated_mesh.get_node("AnimationPlayer")
	animation_player.play("Zombie_Biting0")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
