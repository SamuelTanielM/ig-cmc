extends CharacterBody3D

@export var speed: float = 10.0
@export var sprint_speed: float = 15.0
@export var crouch_speed: float = 5.0
@export var acceleration: float = 5.0
@export var gravity: float = 9.8
@export var jump_power: float = 5.0
@export var mouse_sensitivity: float = 0.005
@export var sprint_double_tap_time: float = 0.3
@export var fov_default: float = 75.0
@export var fov_sprint: float = 100.0
@export var fov_crouch: float = 50.0
@export var fov_smoothness: float = 5.0

var pickedObject
var slicedPickedObject
var can_pickup = true
var slicedPickedObject_original_parent: Node = null

var camera_x_rotation: float = 0.0
var last_forward_press_time: float = 0.0
var is_sprinting: bool = false
var is_crouching: bool = false
var frozen = false
var slicer_mode_enabled = false
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.005

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var slicer = $Head/Camera3D/Slicer



var meshSlicer = MeshSlicer.new()
var cross_section_material = preload("res://Assets/AddonsAssets/cross_section_material.tres")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_child(meshSlicer)

func _input(event):
	# Toggle slicer mode
	
	if event.is_action_pressed("F") and pickedObject:
		pickedObject.reparent(get_tree().current_scene)
		pickedObject.set_interactable(true) 
		pickedObject = null
		can_pickup = false
		start_pickup_cooldown() 
	
	if event.is_action_pressed("F") and slicedPickedObject:
		if is_instance_valid(slicedPickedObject_original_parent):
			slicedPickedObject.reparent(slicedPickedObject_original_parent)  # ⬅️ Restore original parent
		else:
			slicedPickedObject.reparent(get_tree().current_scene)  # fallback

		slicedPickedObject.set_interactable(true)
		slicedPickedObject = null
		slicedPickedObject_original_parent = null
		can_pickup = false
		start_pickup_cooldown()
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			slicer_mode_enabled = !slicer_mode_enabled
			slicer.visible = !slicer.visible  # show slicer
		if event.keycode == KEY_2:
			$Dialogue.visible = !$Dialogue.visible  # show slicer

	# rotate camera when right mouse is pressed
	if Input.is_action_pressed("right_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_pressed("scroll_up"):
		slicer.rotate_z(0.1)
		$Head/Camera3D/CarryObject.rotate_z(0.1)
	if Input.is_action_pressed("scroll_down"):
		slicer.rotate_z(-0.1)
		$Head/Camera3D/CarryObject.rotate_z(-0.1)
	# rotate slicer only if enabled
	#if slicer_mode_enabled:
		#if Input.is_action_pressed("scroll_up"):
			#slicer.rotate_z(0.1)
		#if Input.is_action_pressed("scroll_down"):
			#slicer.rotate_z(-0.1)


func _physics_process(delta):
	if pickedObject:
		pickedObject.global_transform = $Head/Camera3D/CarryObject.global_transform
	
	if slicedPickedObject:
		slicedPickedObject.global_transform = $Head/Camera3D/CarryObject.global_transform

	if frozen:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var movement_vector = Vector3.ZERO
	var target_speed = speed
	var target_fov = fov_default

	if Input.is_action_just_pressed("W"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_forward_press_time < sprint_double_tap_time:
			is_sprinting = true
		else:
			is_sprinting = false
		last_forward_press_time = current_time

	if !Input.is_action_pressed("W"):
		is_sprinting = false

	if Input.is_action_pressed("Shift"):
		is_crouching = true
		is_sprinting = false
	else:
		is_crouching = false

	if is_sprinting:
		target_speed = sprint_speed
		target_fov = fov_sprint
	elif is_crouching:
		target_speed = crouch_speed
		target_fov = fov_crouch

	camera.fov = lerp(camera.fov, target_fov, fov_smoothness * delta)

	if is_crouching and check_near_edge():
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
	else:
		if Input.is_action_pressed("D"):
			movement_vector -= head.basis.z
		if Input.is_action_pressed("A"):
			movement_vector += head.basis.z
		if Input.is_action_pressed("W"):
			movement_vector -= head.basis.x
		if Input.is_action_pressed("S"):
			movement_vector += head.basis.x

		movement_vector = movement_vector.normalized()
		velocity.x = lerp(velocity.x, movement_vector.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, movement_vector.z * target_speed, acceleration * delta)

		if not is_on_floor():
			velocity.y -= gravity * delta
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_power

	move_and_slide()

	# Slice interaction
	if slicer_mode_enabled and Input.is_action_just_pressed("left_mouse"):
		for body in $Head/Camera3D/Slicer/Area3D.get_overlapping_bodies():
			if body is RigidBody3D and body.get_parent().get_parent().name == "RigidBodys":

				var meshinstance = body.find_child("MeshInstance3D", true, false)
				var T = Transform3D.IDENTITY
				T.origin = meshinstance.to_local(slicer.global_transform.origin)
				T.basis.x = meshinstance.to_local(slicer.global_transform.basis.x + body.global_position)
				T.basis.y = meshinstance.to_local(slicer.global_transform.basis.y + body.global_position)
				T.basis.z = meshinstance.to_local(slicer.global_transform.basis.z + body.global_position)

				var collision = body.get_node("CollisionShape3D")
				var meshes = meshSlicer.slice_mesh(T, meshinstance.mesh, cross_section_material)
				meshinstance.mesh = meshes[0]

				if meshes[0].get_faces().size() > 2:
					collision.shape = meshes[0].create_convex_shape()

				body.center_of_mass_mode = 1
				body.center_of_mass = body.to_local(meshinstance.to_global(calculate_center_of_mass(meshes[0])))

				var volume1 = calculate_mesh_volume(meshes[0])
				var volume2 = calculate_mesh_volume(meshes[1])
				var total_volume = volume1 + volume2
				body.mass *= (volume1 / total_volume)

				var body2 = body.duplicate()
				body.get_parent().add_child(body2)  # ⬅️ Now we place it in the same container (Duckie or Donut)

				var mi2 = body2.get_node("MeshInstance3D")
				var col2 = body2.get_node("CollisionShape3D")
				mi2.mesh = meshes[1]
				body2.mass = body.mass * (volume2 / total_volume)
				if meshes[1].get_faces().size() > 2:
					col2.shape = meshes[1].create_convex_shape()

	
func spawn_item(item_name):
	var item_path = find_item_scene(item_name)
	if item_path != "":
		var item_scene = load(item_path)
		var item_instance = item_scene.instantiate()
		if camera:
			var forward = -camera.global_transform.basis.z.normalized()
			item_instance.global_transform.origin = camera.global_transform.origin + (forward * 2.0) + Vector3(0, -0.5, 0)
			get_parent().add_child(item_instance)
		else:
			print("Error: Camera3D not found!")
	else:
		print("Error: Could not find item:", item_name)

func find_item_scene(item_name) -> String:
	var base_path = "res://Scenes/Objects/"
	var directories = get_directories_recursive(base_path)
	for dir in directories:
		var item_path = dir + "/" + item_name + ".tscn"
		if ResourceLoader.exists(item_path):
			return item_path
	print("Item not found:", item_name)
	return ""

func get_directories_recursive(path: String) -> Array:
	var dir = DirAccess.open(path)
	var directories = [path]
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				directories.append_array(get_directories_recursive(path + file_name + "/"))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Error: Could not open directory", path)
	return directories

func check_near_edge() -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin
	var check_distance = 0.5
	var ray_length = 1.5

	var directions = [
		Vector3(0, 0, 0),  # Center
		Vector3(check_distance, 0, 0),
		Vector3(-check_distance, 0, 0),
		Vector3(0, 0, check_distance),
		Vector3(0, 0, -check_distance)
	]

	for dir in directions:
		var start = origin + dir
		var end = start + Vector3(0, -ray_length, 0)
		
		var ray_params = PhysicsRayQueryParameters3D.new()
		ray_params.from = start
		ray_params.to = end
		ray_params.exclude = [self]
		ray_params.collision_mask = 1  # Adjust to match your floor's layer

		var result = space_state.intersect_ray(ray_params)
		if result.is_empty():
			return true  # No ground detected below = near edge

	return false  # Ground detected under all points = not near edge

func pick_up_object(object) -> bool:
	if not can_pickup:
		print("Can't pick up yet! Still in cooldown.")
		return false
	
	print("Picking up object:", object.name)
	object.reparent(self)
	object.global_position = $Head/Camera3D/CarryObject.global_position
	
	await get_tree().create_timer(0.1).timeout
	pickedObject = object
	print("Picked up:", pickedObject.name)
	return true
	
func pick_up_object_sliced(object) -> bool:
	if not can_pickup:
		print("Can't pick up yet! Still in cooldown.")
		return false

	print("Picking up object:", object.name)
	slicedPickedObject_original_parent = object.get_parent()  # ⬅️ Store original parent
	object.reparent(self)
	object.global_position = $Head/Camera3D/CarryObject.global_position

	await get_tree().create_timer(0.1).timeout
	slicedPickedObject = object
	print("Picked up:", slicedPickedObject.name)
	return true



func start_pickup_cooldown():
	print("Starting pickup cooldown...")
	await get_tree().create_timer(0.2).timeout
	can_pickup = true
	print("Pickup cooldown ended.")

				
func calculate_center_of_mass(mesh:ArrayMesh):
	#Not sure how well this work
	var meshVolume = 0
	var temp = Vector3(0,0,0)
	for i in range(len(mesh.get_faces())/3):
		var v1 = mesh.get_faces()[i]
		var v2 = mesh.get_faces()[i+1]
		var v3 = mesh.get_faces()[i+2]
		var center = (v1 + v2 + v3) / 3
		var volume = (Geometry3D.get_closest_point_to_segment_uncapped(v3,v1,v2).distance_to(v3)*v1.distance_to(v2))/2
		meshVolume += volume
		temp += center * volume
	
	if meshVolume == 0:
		return Vector3.ZERO
	return temp / meshVolume

func calculate_mesh_volume(mesh: ArrayMesh) -> float:
	var volume = 0.0
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		for i in range(0, vertices.size(), 3):
			var v1 = vertices[i]
			var v2 = vertices[i + 1]
			var v3 = vertices[i + 2]
			volume += abs(v1.dot(v2.cross(v3))) / 6.0
	return volume


func freeze():
	frozen = true
	velocity = Vector3.ZERO  # Stops movement immediately

func unfreeze():
	frozen = false
