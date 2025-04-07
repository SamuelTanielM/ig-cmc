extends PanelContainer

var main_scene = preload("res://Scenes/main.tscn")

func _on_b_play_pressed():
	get_tree().change_scene_to_packed(main_scene)
