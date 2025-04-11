extends Area3D

@onready var soup_node: MeshInstance3D = $"../SoupBased"
@onready var collision_soup_node: CollisionShape3D = $"../CollisionShape3D"
@onready var cylinder_mesh: CylinderMesh = soup_node.mesh as CylinderMesh
@onready var col_cylinder_mesh: CylinderShape3D = collision_soup_node.shape as CylinderShape3D
@onready var tween: Tween

const MAX_RADIUS := 0.85
const RADIUS_INCREMENT := 0.05
const Y_POSITION_START := 0.0
const Y_POSITION_END := 0.163
const RADIUS_THRESHOLD_FOR_Y := 0.605

func _ready():
	tween = create_tween()

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
	if body.name == "OilDrop":
		increase_soup()
		body.queue_free()
