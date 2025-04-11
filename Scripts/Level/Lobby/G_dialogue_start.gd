extends Node3D

@onready var Player: CharacterBody3D = $Player
@onready var NPC: CharacterBody3D = $Sun

func _on_body_entered(body):
	if(body == Player):
		Dialogic.signal_event.connect(_on_dialogic_signal)
		Dialogic.start("Lobby_Start")
	pass # Replace with function body.
	
func _on_dialogic_signal(argument: String):
	if argument == "freeze":
		Player.freeze()
	if argument == "unfreeze":
		Player.unfreeze()
	if argument == "start":
		NPC.position = Vector3(-16.99,-0.282,1.433)
		Player.position = Vector3(0,0,0)
		$Sun/Area3D.queue_free()
		
	if argument == "level1":
		get_tree().change_scene_to_file("res://Scenes/Level/Level1.tscn")
		Dialogic.end_timeline()
