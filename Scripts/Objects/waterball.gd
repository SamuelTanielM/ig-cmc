extends RigidBody3D

@export var lifetime := 3.0
@export var mass_qt : float = 1
var time_alive := 0.0

# Store original sizes so we can scale from them
var start_radius := 0.0
var start_height := 0.0
var start_collision_radius := 0.0

func _ready():
	# Cache starting sizes
	var sphere_mesh = $MeshInstance3D.mesh as SphereMesh
	start_radius = sphere_mesh.radius
	start_height = sphere_mesh.height

	var sphere_shape = $CollisionShape3D.shape as SphereShape3D
	start_collision_radius = sphere_shape.radius

func _physics_process(delta):
	time_alive += delta

	var t = clamp(time_alive / lifetime, 0.0, 1.0)
	var scale_factor = 1.0 - t # Shrinks from 1.0 to 0.0

	# Scale the visual mesh
	var mesh = $MeshInstance3D.mesh as SphereMesh
	mesh.radius = start_radius * scale_factor
	mesh.height = start_height * scale_factor

	# Scale the collision shape
	var shape = $CollisionShape3D.shape as SphereShape3D
	shape.radius = start_collision_radius * scale_factor

	# Clean up when time's up
	if time_alive > lifetime or mesh.radius <= 0.01:
		queue_free()
