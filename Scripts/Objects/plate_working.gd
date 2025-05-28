extends Interactable

@export var item: Node3D 
var selected = false
var player

@onready var area = $FoodCheck
var bodies_in_area := []

func _ready():
	await get_tree().process_frame  # Wait one frame
	player = get_tree().get_first_node_in_group("Player")
	if item == null:
		item = $"."  # fallback to self if item not assigned


func interact(body):
	if not selected and body.has_method("pick_up_object"):
		var success: bool = await body.pick_up_object(item)

		if success:
			set_interactable(false)

		
func set_interactable(value: bool):
	selected = not value

	set_process_input(value)
	set_physics_process(value)

	# Freeze/unfreeze physics if item is RigidBody3D
	if item is RigidBody3D:
		if value:
			item.freeze = false
		else:
			item.freeze = true  # optional, helps in some cases


func _on_interacted(body):
	var check = Inventory.add_to_state(prompt_message, 1)  # Pass item.name as the key
	if check:  # If inventory is not full
		item.queue_free()


func _on_area_3d_body_entered(body):
	if not body is RigidBody3D:
		return

	if "on_fire" in body:
		if not bodies_in_area.has(body):
			bodies_in_area.append(body)
			var ingredient_name = body.get_prompt_message()
			print(ingredient_name)
			IngredientTracker.add_finished_ingredient(ingredient_name)


func _on_area_3d_body_exited(body):
	if not body is RigidBody3D:
		return

	if "on_fire" in body:
		bodies_in_area.erase(body)
