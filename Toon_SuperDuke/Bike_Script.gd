class_name BikeControllerComponent
extends RigidBody3D


# Movement settings
@export_group("Movement")
@onready var bike_node: RigidBody3D = $"." # Reference to actual bike Node3D
@export var move_speed: float = 10.0
@export var lane_switch_speed: float = 5.0
@export var tilt_speed: float = 3.0
@export var max_tilt: float = 15.0

# Lane markers
@export_group("Lane Markers")
@export var lane_marker: Marker3D  # Alternate lane
@export var default_marker: Marker3D  # Default/center lane

# State
var target_marker: Marker3D = null
var current_tilt: float = 0.0
var is_switching_lane: bool = false
var is_stopped: bool = false

func _ready():
	# Register with global manager
	WaveRiderManager.register_bike_controller(self)
	# Set default target
	if default_marker:
		target_marker = default_marker
	
	# Auto-find bike if not set
	if not bike_node:
		bike_node = get_parent() as Node3D
		if not bike_node:
			push_error("BikeControllerComponent: No bike_node set and parent is not Node3D!")

func _physics_process(delta: float) -> void:
	if is_stopped or not bike_node:
		return
	
	# Forward movement
	bike_node.global_translate(Vector3(0, 0, move_speed * delta))
	
	## Lane switching input
	#if Input.is_action_pressed("ui_accept") and lane_marker:
		#if not is_switching_lane:
			#is_switching_lane = true
			#target_marker = lane_marker
	#elif is_switching_lane:
		#is_switching_lane = false
		#target_marker = default_marker
	
	# Move toward target marker
	if target_marker:
		var current_z = bike_node.global_position.z
		var target_pos = target_marker.global_position
		target_pos.z = current_z
		
		var new_pos = bike_node.global_position.lerp(target_pos, delta * lane_switch_speed)
		new_pos.z = current_z
		bike_node.global_position = new_pos
		
		# Calculate tilt
		var movement_dir = target_pos.x - bike_node.global_position.x
		var target_tilt = clamp(movement_dir * 5.0, -max_tilt, max_tilt)
		current_tilt = lerp(current_tilt, target_tilt, delta * tilt_speed)
	else:
		current_tilt = lerp(current_tilt, 0.0, delta * tilt_speed)
	
	# Apply tilt
	bike_node.rotation.z = deg_to_rad(current_tilt)

# Stop the bike completely
func stop_bike() -> void:
	is_stopped = true
	move_speed = 0.0
	#self.global_position.z = IceHole.global_position.z
	#IceHole.visible = true
	#get_node("/root/)

# Resume bike movement
func resume_bike() -> void:
	is_stopped = false

# Force return to default lane
func force_return_to_default() -> void:
	is_switching_lane = false
	if default_marker:
		target_marker = default_marker

# Check current lane
func is_in_alternate_lane() -> bool:
	return is_switching_lane
