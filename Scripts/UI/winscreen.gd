extends PanelContainer

var level_1 = preload("res://Scenes/Level/Level1.tscn")
var menu = preload("res://Scenes/UI/menu.tscn")

func _on_b_play_pressed():
	get_tree().change_scene_to_packed(level_1)
	IngredientTracker.reset_all()


func _on_bsettings_pressed():
	get_tree().change_scene_to_packed(menu)
