extends Node3D

@export var drop_scene: PackedScene
@export var base_spawn_rate := 0.5 # Slower when barely tilted
var time_accum := 0.0

const MIN_ANGLE := 30.0  # Degrees to start dripping
const MAX_ANGLE := 100.0 # Degrees for max drip speed
const MAX_RATE := 0.05   # Fastest drip rate (when fully tilted)
const MIN_RATE := 0.5    # Slowest drip rate (just past threshold)

func _process(delta):
	var tilt_angle = get_tilt_angle()

	# Only start spawning after minimum tilt angle
	if tilt_angle < MIN_ANGLE:
		return

	# Normalize angle to a 0.0 - 1.0 factor
	var factor = clamp((tilt_angle - MIN_ANGLE) / (MAX_ANGLE - MIN_ANGLE), 0.0, 1.0)
	var spawn_rate = lerp(MIN_RATE, MAX_RATE, factor)

	time_accum += delta
	if time_accum >= spawn_rate:
		time_accum = 0
		spawn_drop()

func get_tilt_angle() -> float:
	var drip_direction = -global_transform.basis.y.normalized()  # or .z/.x depending on your bottle orientation
	var angle_radians = drip_direction.angle_to(Vector3.DOWN)
	return rad_to_deg(angle_radians)

func spawn_drop():
	var drop = drop_scene.instantiate()

	# Add to the scene root to avoid inheriting parent scale
	get_tree().current_scene.add_child(drop)

	# Compute tilt and scale
	var tilt_angle = get_tilt_angle()
	var factor = clamp((tilt_angle - MIN_ANGLE) / (MAX_ANGLE - MIN_ANGLE), 0.0, 1.0)
	var scale_factor = lerp(0.01, 1.0, factor)

	# Set transform first
	drop.global_transform = Transform3D(
		Basis(),
		global_transform.origin + Vector3(
			randf_range(-0.05, 0.05),
			0.0,
			randf_range(-0.05, 0.05)
		)
	)

	# Then apply scale
	drop.scale = Vector3.ONE * scale_factor
