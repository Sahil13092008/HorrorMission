extends StaticBody3D

@export_multiline var note_content: String = "find me bhangarh"
@export var prompt_text: String = "Read Note"

func _ready():
	add_to_group("interactable")
	set_meta("prompt", prompt_text)

func interact(player):
	if player.has_method("show_note"):
		player.show_note(note_content)
