extends StaticBody3D

@export var character_name: String = "Sahil"
@export var prompt_action: String = "Talk to"
@export_multiline var dialogue_before: String = ""
@export_multiline var dialogue_after: String = ""

var has_event_occurred: bool = false

func _ready():
	add_to_group("interactable")
	set_meta("prompt", prompt_action + " " + character_name)

func set_post_event_state(occurred: bool):
	has_event_occurred = occurred

func interact(player):
	if player.has_method("show_popup"):
		var text = dialogue_after if has_event_occurred else dialogue_before
		player.show_popup("[" + character_name.to_upper() + "]", text)
