extends Interactable

@export var item: Node3D 
var selected = false
var player

@export var on_fire: bool = false
var fire_intensity := 0.0  # Goes from 0 to 1

var overlay_material := StandardMaterial3D.new()

var original_colors := {}  # Dictionary to store: key = material ref, value = original color


func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if item == null:
		item = $"."  # fallback to self

	for mesh in get_tree().get_nodes_in_group("mesh_group_fire_overlay_" + str(self.get_instance_id())):
		if mesh is MeshInstance3D:
			var surface_count = mesh.get_surface_override_material_count()
			for i in range(surface_count):
				var mat = mesh.get_active_material(i)
				if mat is StandardMaterial3D:
					var mat_instance = mat.duplicate() as StandardMaterial3D
					mat_instance.resource_local_to_scene = true
					mat_instance.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat_instance.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					mat_instance.flags_transparent = true
					mesh.set_surface_override_material(i, mat_instance)

					# Store original albedo color
					original_colors[mat_instance] = mat_instance.albedo_color


func _process(delta):
	if on_fire:
		fire_intensity = min(fire_intensity + delta * (1.0 / 90.0), 1.0)

		var burn_target_color = Color(0.4, 0.2, 0.05, 1.0)


		# Apply burn color
		for mesh in get_tree().get_nodes_in_group("mesh_group_fire_overlay_" + str(self.get_instance_id())):
			var surface_count: int = mesh.get_surface_override_material_count()
			for i in range(surface_count):
				var mat: Material = mesh.get_surface_override_material(i)
				if mat is StandardMaterial3D:
					if not original_colors.has(mat):
						original_colors[mat] = mat.albedo_color  # Save original color
					var from_color = original_colors[mat]
					var to_color = burn_target_color
					var current_color = from_color.lerp(to_color, fire_intensity)
					(mat as StandardMaterial3D).albedo_color = current_color


	elif fire_intensity > 0.0:
		# Optional: slowly cool down (optional fade out)
		fire_intensity = max(fire_intensity - delta * 0.5, 0.0)
	#else:
		## Optional: restore original material if not on fire and intensity is 0
		#for mesh in get_tree().get_nodes_in_group("mesh_group_fire_overlay_" + str(self.get_instance_id())):
			#var surface_count: int = mesh.get_surface_override_material_count()
			#for i in range(surface_count):
				#var mat: Material = mesh.get_surface_override_material(i)
				#if mat is StandardMaterial3D:
					#if original_colors.has(mat):
						#(mat as StandardMaterial3D).albedo_color = original_colors[mat]



func _enter_tree():
	# Organize MeshInstance3D nodes into a unique group so they can be tracked
	var meshes = get_children_recursive()
	for child in meshes:
		if child is MeshInstance3D:
			child.add_to_group("mesh_group_fire_overlay_" + str(self.get_instance_id()))


func get_children_recursive(node: Node = self) -> Array:
	var list := []
	for child in node.get_children():
		if child is Node:
			list.append(child)
			list += get_children_recursive(child)
	return list


func interact(body):
	if not selected and body.has_method("pick_up_object"):
		var success: bool = await body.pick_up_object_sliced(item)

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

func _on_interacted(body):
	var check = Inventory.add_to_state(prompt_message, 1)  # Pass item.name as the key
	if check:  # If inventory is not full
		item.queue_free()
