extends Node3D

@onready var label = $Control/Label
@onready var finish_button = $Control/FinishButton
@onready var audio_checkpoint = $AudioCheckpoint
@onready var time_label = $Control/Time

var required_ingredients = ["Garlic", "Shallots", "Turmeric", "Lime Leaf", "Chicken"]

# Track whether steps were previously completed
var step2_done := false
var step3_done := false
var step4_done := false

# Time tracking (in seconds)
var start_hour := 9
var start_minute := 0
var start_second := 0
var elapsed_time := 0.0

func _ready():
	finish_button.visible = false
	_update_time_label()  # Initialize time display

func _process(delta):
	# Update elapsed time
	elapsed_time += delta

	_update_time_label()

	var step2_ready := IngredientTracker.has_all(required_ingredients)
	var step3_ready := IngredientTracker.has_all_cooked(required_ingredients)
	var step4_ready := IngredientTracker.has_all_finished(required_ingredients)

	var text := "--- \nFinish All Checkpoints To Win!\n1. Click 2, and follow the recipe\n\nCheckpoint:\n"

	# Step 2
	if step2_ready:
		text += "2. Prepare the ingredients ✅\n"
		if not step2_done:
			audio_checkpoint.play()
			step2_done = true
	else:
		text += "2. Prepare the ingredients\n"
		step2_done = false  # Optional reset if step becomes incomplete

	# Step 3
	if step2_ready and step3_ready:
		text += "3. Cooking ✅\n"
		if not step3_done:
			audio_checkpoint.play()
			step3_done = true
	else:
		text += "3. Cooking\n"
		step3_done = false  # Optional reset

	# Step 4
	if step3_ready and step4_ready:
		text += "4. Finishing Touch ✅"
		if not step4_done:
			audio_checkpoint.play()
			step4_done = true
	else:
		text += "4. Finishing Touch"
		step4_done = false  # Optional reset

	# Show Finish button if all steps complete
	finish_button.visible = step2_ready and step3_ready and step4_ready

	label.text = text

func _update_time_label():
	var total_seconds = start_hour * 3600 + start_minute * 60 + start_second + int(elapsed_time)
	var hour = (total_seconds / 3600) % 24
	var minute = (total_seconds / 60) % 60
	var second = total_seconds % 60
	time_label.text = "%02d:%02d:%02d" % [hour, minute, second]

func _on_finish_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/win_screen.tscn")
