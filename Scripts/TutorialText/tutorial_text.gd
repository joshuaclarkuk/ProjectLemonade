extends PanelContainer

@onready var tutorial_text: Label = $TutorialText

const OPENING_TEXT = preload("res://Scripts/TutorialText/opening_text.tres")

var is_displaying_text: bool = false
var current_text_resource: TutorialTextRes = null
var current_text_index: int = 0


func _ready() -> void:
	set_visible(false)
	var display_opening_text_tween = create_tween()
	display_opening_text_tween.tween_callback(display_tutorial_text.bind(OPENING_TEXT)).set_delay(3.0)


func display_tutorial_text(text_resource: TutorialTextRes) -> void:
	current_text_resource = text_resource
	is_displaying_text = true
	set_visible(true)
	tutorial_text.text = text_resource.text_to_display[current_text_index]
	var tween = create_tween()
	tween.tween_callback(hide_tutorial_text).set_delay(text_resource.time_to_display)


func hide_tutorial_text() -> void:
	if !current_text_resource: return
	
	if current_text_resource.text_to_display.size() - 1 > current_text_index:
		current_text_index += 1
		display_tutorial_text(current_text_resource)
	else:
		is_displaying_text = false
		set_visible(false)
		current_text_resource = null
		current_text_index = 0
