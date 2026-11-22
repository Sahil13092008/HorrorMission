extends Area3D

func _ready():
    # Connect the signal when a body (player) enters the trigger area
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    # Simple check: if the entering body is named "Player"
    if body.name == "Player":
        # Load the police station interior scene
        get_tree().call_deferred("change_scene_to_file", "res://scenes/police_station.tscn")
