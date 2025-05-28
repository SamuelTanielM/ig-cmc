extends PanelContainer

var level_1 = preload("res://Scenes/Level/main.tscn")

func _on_b_play_pressed():
	get_tree().change_scene_to_packed(level_1)
