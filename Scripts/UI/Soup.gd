extends Interactable

@onready var soup_node: MeshInstance3D = $SoupBased
@onready var collision_soup_node: CollisionShape3D = $CollisionShape3D
@onready var cylinder_mesh: CylinderMesh = soup_node.mesh as CylinderMesh
@onready var col_cylinder_mesh: CylinderShape3D = collision_soup_node.shape as CylinderShape3D
@onready var tween: Tween

var contents_dict := {}  # e.g. { "Salt": { "amount": 200, "unit": "g" } }

var total_solid := 0.0
var total_liquid := 0.0
var mixed_color := Color(0, 0, 0)




@export var MAX_RADIUS := 0.85
@export var RADIUS_INCREMENT := 0.01
@export var Y_POSITION_START := 0.0
@export var Y_POSITION_END := 0.163
@export var RADIUS_THRESHOLD_FOR_Y := 0.605

@export var item: Node3D 
var selected = false
var player

func _ready():
	tween = create_tween()
	await get_tree().process_frame  # Wait one frame

	# Make the mesh unique to this instance
	if soup_node.mesh:
		soup_node.mesh = soup_node.mesh.duplicate()

	# Make the collision shape unique
	if collision_soup_node.shape:
		collision_soup_node.shape = collision_soup_node.shape.duplicate()

	# Reassign after duplication
	cylinder_mesh = soup_node.mesh as CylinderMesh
	col_cylinder_mesh = collision_soup_node.shape as CylinderShape3D

	player = get_tree().get_first_node_in_group("Player")
	if item == null:
		item = $"."  # fallback to self


func interact(body):
	if not selected and body.has_method("pick_up_object"):
		body.pick_up_object(item)
		set_interactable(false)
		
func set_interactable(value: bool):
	selected = not value

	set_process_input(value)
	set_physics_process(value)

func increase_soup():
	var current_radius = cylinder_mesh.top_radius
	var target_radius = clamp(current_radius + RADIUS_INCREMENT, 0.0, MAX_RADIUS)
	var current_radius2 = col_cylinder_mesh.radius
	var target_radius2 = clamp(current_radius2 + RADIUS_INCREMENT, 0.0, MAX_RADIUS)

	# Animate radius manually with tween_method
	tween.kill()  # stop any previous animations
	tween = create_tween()

	tween.tween_method(self._update_radius, current_radius, target_radius, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(self._update_radius, current_radius2, target_radius2, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_radius(value: float):
	cylinder_mesh.top_radius = value
	cylinder_mesh.bottom_radius = value
	col_cylinder_mesh.radius = value

	# Smooth Y offset based on radius progression
	var new_y = Y_POSITION_START
	if value > RADIUS_THRESHOLD_FOR_Y:
		var percent = (value - RADIUS_THRESHOLD_FOR_Y) / (MAX_RADIUS - RADIUS_THRESHOLD_FOR_Y)
		new_y = lerp(Y_POSITION_START, Y_POSITION_END, percent)

	var transform = soup_node.transform
	transform.origin.y = new_y
	soup_node.transform = transform
	collision_soup_node.transform = transform

func _on_body_entered(body):
	if body.name.ends_with("Drop"):
		var name = body.name.replace("Drop", "")
		var amount = body.mass_qt if body.has_method("get_mass") else 100.0

		var is_liquid = name in ["CoconutMilk", "Milk", "Oil", "Water"]
		var unit = "ml" if is_liquid else "g"

		if is_liquid:
			total_liquid += amount
		else:
			total_solid += amount

		# Get color from drop material
		# Get color from drop material
		var mesh = body.get_node_or_null("MeshInstance3D")
		var color = Color(1.0, 1.0, 1.0)  # fallback white
		if mesh and mesh.mesh.material.albedo_color:
			color = mesh.mesh.material.albedo_color
			print(color)

		# Update content tracking
		if not contents_dict.has(name):
			contents_dict[name] = { "amount": amount, "unit": unit, "color": color }
		else:
			contents_dict[name]["amount"] += amount
			# blend the color into average
			var old_amt = contents_dict[name]["amount"] - amount
			var total_amt = contents_dict[name]["amount"]
			contents_dict[name]["color"] = contents_dict[name]["color"].lerp(color, amount / total_amt)

		# Update soup visual
		update_soup_color()

		if is_liquid:
			increase_soup()
		body.queue_free()

		print_contents()


func print_contents():
	print("🍲 Soup Contents:")
	for key in contents_dict.keys():
		var content = contents_dict[key]
		var unit = content["unit"]
		var amount = content["amount"]
		var percent = (amount / (total_liquid if unit == "ml" else total_solid)) * 100.0
		print("%s: %.2f%% (%.2f%s)" % [key, percent, amount, unit])
		
		
func update_soup_color():
	var total_weight = total_liquid + total_solid
	if total_weight == 0:
		print("🛑 No contents to blend.")
		return

	var blended_color = Color(0, 0, 0)
	for key in contents_dict.keys():
		var content = contents_dict[key]
		var weight = content["amount"]
		var color = content["color"]
		blended_color += color * (weight / total_weight)

	# Clamp color components to avoid overflow
	blended_color.r = clamp(blended_color.r, 0.0, 1.0)
	blended_color.g = clamp(blended_color.g, 0.0, 1.0)
	blended_color.b = clamp(blended_color.b, 0.0, 1.0)

	# Always override with a new material
	var new_mat := StandardMaterial3D.new()
	new_mat.albedo_color = blended_color
	new_mat.flags_unshaded = true  # Optional: force clean color rendering

	cylinder_mesh.material = new_mat
