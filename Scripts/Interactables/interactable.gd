class_name Interactable extends Area3D


@export var ToolName: GameManager.ToolType

signal interacted_with()


func interact() -> void:
	interacted_with.emit()
