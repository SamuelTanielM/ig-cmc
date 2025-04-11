extends Interactable

@export var item: Node3D 
var selected = false
var player

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

	# Set collision layers/masks
	if item.has_method("set_collision_layer"):
		item.set_collision_layer(1 if value else 0)

	if item.has_method("set_collision_mask"):
		item.set_collision_mask(1 if value else 0)

	# Disable CollisionShape3D if needed
	var collision_shape = item.get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.has_method("set_disabled"):
		collision_shape.set_disabled(not value)

#
#
#func _on_interacted(body):
	#var check = Inventory.add_to_state(prompt_message, 1)  # Pass item.name as the key
	#if check:  # If inventory is not full
		#item.queue_free()
