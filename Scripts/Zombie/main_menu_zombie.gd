extends CharacterBody3D

@onready var animated_mesh = $AnimatedMesh

var animation_player: AnimationPlayer


func _ready():
	animation_player = animated_mesh.get_node("AnimationPlayer")
	animation_player.play("Zombie_Idle")
