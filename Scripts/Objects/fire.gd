extends Node3D

var fire_is_on: bool = false:
	set(value):
		fire_is_on = value
		update_fire_state()

@onready var area = $Area3D
@onready var fire_node = $Fire
var original_fire_scale: Vector3
var bodies_in_area := []

func _ready():
	original_fire_scale = fire_node.scale
	set_process(true)

func _process(delta):
	var target_scale: Vector3 = original_fire_scale if fire_is_on else Vector3.ZERO
	var speed := 5.0  # Adjust for faster/slower smooth scale
	fire_node.scale = fire_node.scale.lerp(target_scale, delta * speed)

func _on_area_3d_body_entered(body):
	if not body is RigidBody3D:
		return

	if "on_fire_stove" in body:
		if not bodies_in_area.has(body):
			bodies_in_area.append(body)

		if fire_is_on:
			body.on_fire_stove = true

func _on_area_3d_body_exited(body):
	if not body is RigidBody3D:
		return

	if "on_fire_stove" in body:
		body.on_fire_stove = false
		bodies_in_area.erase(body)

func update_fire_state():
	for body in bodies_in_area:
		if not is_instance_valid(body):
			continue

		if "on_fire_stove" in body:
			body.on_fire_stove = fire_is_on
