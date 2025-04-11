extends Interactable

@export var item: Node3D
@export var fire: Node3D  # Let user assign manually in the editor

@onready var switch = $Switch
var player

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")

	# Fallback if fire wasn't assigned in the editor
	if fire == null:
		fire = $"../Fire"

	if item == null:
		item = $"."

func interact(body):
	print("test")
	if "fire_is_on" in fire:
		print("test")
		fire.fire_is_on = !fire.fire_is_on

		# Toggle switch Y rotation between 0 and -90 degrees
		var current_y = wrapf(switch.rotation.y, -PI, PI)
		var target_y = deg_to_rad(0 if abs(current_y + PI / 2) < 0.1 else -90)
		switch.rotation.y = target_y
