extends RayCast3D

var current_collider: Node = null
@onready var prompt = $Prompt
@onready var outline_material = preload("res://Assets/Outline/outline_material.tres")

var original_override_materials := {}


func _process(delta):
	prompt.text = ""
	var collider = get_collider()

	# Remove outline if the ray no longer hits the same collider
	if current_collider and current_collider != collider:
		_remove_outline(current_collider)
		current_collider = null

	# If hitting something interactable
	if is_colliding() and collider is Interactable:
		prompt.text = collider.get_prompt()

		# Add outline only if it's a new object
		if current_collider != collider:
			_add_outline(collider)
			current_collider = collider

		if Input.is_action_just_pressed("F") and collider.prompt_input == "F":
			collider.interact(owner)
			
		if Input.is_action_just_pressed("C") and collider.prompt_input == "C":
			collider.interact(owner)
	else:
		# Remove outline if no longer colliding
		if current_collider:
			_remove_outline(current_collider)
			current_collider = null




func _add_outline(node: Node):
	if not node:
		return
	_apply_outline_recursive(node)
	_set_depth_test_recursive(node, false)

func _remove_outline(node: Node):
	if not node:
		return
	_apply_outline_recursive(node, true)
	_set_depth_test_recursive(node, true)

func _apply_outline_recursive(node: Node, remove := false):
	if node is MeshInstance3D:
		node.material_overlay = null if remove else outline_material
	
	for child in node.get_children():
		if child is Node:
			_apply_outline_recursive(child, remove)

func _set_depth_test_recursive(node: Node, enable_depth_test: bool):
	if node is MeshInstance3D and node.mesh:
		for surface_index in node.mesh.get_surface_count():
			if enable_depth_test:
				# Restore original override, not just set to null
				var key = str(node.get_instance_id()) + "_" + str(surface_index)
				if original_override_materials.has(key):
					node.set_surface_override_material(surface_index, original_override_materials[key])
				continue

			# Save existing override before changing
			var key = str(node.get_instance_id()) + "_" + str(surface_index)
			if not original_override_materials.has(key):
				original_override_materials[key] = node.get_surface_override_material(surface_index)

			var base_material: Material = node.get_surface_override_material(surface_index)
			if base_material == null:
				base_material = node.mesh.surface_get_material(surface_index)

			if base_material and base_material is StandardMaterial3D:
				var override_material: StandardMaterial3D = base_material.duplicate() as StandardMaterial3D
				override_material.resource_local_to_scene = true
				override_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
				node.set_surface_override_material(surface_index, override_material)
			elif base_material and base_material.has_property("no_depth_test"):
				var override_material: Material = base_material.duplicate()
				override_material.resource_local_to_scene = true
				override_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
				node.set_surface_override_material(surface_index, override_material)

	for child in node.get_children():
		_set_depth_test_recursive(child, enable_depth_test)

	if enable_depth_test:
		_cleanup_override_backup(node)

func _cleanup_override_backup(node: Node):
	if node is MeshInstance3D and node.mesh:
		for surface_index in node.mesh.get_surface_count():
			var key = str(node.get_instance_id()) + "_" + str(surface_index)
			original_override_materials.erase(key)

	for child in node.get_children():
		_cleanup_override_backup(child)
