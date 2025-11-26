# Wave Rider Global
extends Node

# Track/Map data
@export var current_track_index: int = 0
@export var available_tracks: Array[String] = []

# Game state
var current_hearts: int = 3
var max_hearts: int = 3
var current_combo: int = 0
var is_game_active: bool = false
var game_failed: bool = false

# References
var current_track_component: Node = null
var current_bike_controller: Node = null

# Signals
signal track_loaded(track_path: String)
signal game_started()
signal game_paused()
signal game_resumed()
signal heart_lost(hearts_remaining: int)
signal hearts_reset()
signal combo_milestone_reached(combo_count: int)
signal game_over()

func _ready():
	# Initialize default tracks if none set
	if available_tracks.is_empty():
		available_tracks = [
			"res://tracks/track_01.tscn",
			"res://tracks/track_02.tscn",
			"res://tracks/track_03.tscn"
		]
	
	print("GameManager initialized. Starting hearts: ", current_hearts)

# Load a specific track by index
func load_track(track_index: int) -> void:
	if track_index < 0 or track_index >= available_tracks.size():
		push_error("Invalid track index: " + str(track_index))
		return
	
	current_track_index = track_index
	var track_path = available_tracks[track_index]
	
	var track_scene = load(track_path)
	if track_scene:
		get_tree().change_scene_to_packed(track_scene)
		track_loaded.emit(track_path)
	else:
		push_error("Failed to load track: " + track_path)

# Load next track in sequence
func load_next_track() -> void:
	var next_index = (current_track_index + 1) % available_tracks.size()
	load_track(next_index)

# Start the current game session
func start_game() -> void:
	is_game_active = true
	game_failed = false
	current_hearts = max_hearts
	current_combo = 0
	
	print("Game started! Hearts set to: ", current_hearts)
	game_started.emit()
	hearts_reset.emit()

# Pause the game
func pause_game() -> void:
	is_game_active = false
	game_paused.emit()

# Resume the game
func resume_game() -> void:
	is_game_active = true
	game_resumed.emit()

# Handle game failure
func fail_game() -> void:
	is_game_active = false
	game_failed = true
	
	print("Game failed!")
	game_over.emit()
	
	if current_bike_controller and current_bike_controller.has_method("stop_bike"):
		current_bike_controller.stop_bike()

# Handle losing a heart
func lose_heart() -> void:
	if current_hearts > 0:
		current_hearts -= 1
		print("GameManager: Heart lost! Remaining: ", current_hearts)
		heart_lost.emit(current_hearts)
		
		if current_hearts <= 0:
			fail_game()

# Add a heart (for power-ups, etc)
func add_heart() -> void:
	if current_hearts < max_hearts:
		current_hearts += 1
		print("GameManager: Heart gained! Current: ", current_hearts)
		hearts_reset.emit()

# Reset hearts to max
func reset_hearts() -> void:
	current_hearts = max_hearts
	print("GameManager: Hearts reset to max: ", max_hearts)
	hearts_reset.emit()

# Handle combo counting
func increment_combo() -> void:
	current_combo += 1
	
	if current_combo % 10 == 0:
		combo_milestone_reached.emit(current_combo)

# Reset combo
func reset_combo() -> void:
	current_combo = 0

# Register components (called by components on _ready)
func register_track_component(component: Node) -> void:
	current_track_component = component

func register_bike_controller(controller: Node) -> void:
	current_bike_controller = controller

# Get current game state info
func get_game_state() -> Dictionary:
	return {
		"hearts": current_hearts,
		"max_hearts": max_hearts,
		"combo": current_combo,
		"is_active": is_game_active,
		"has_failed": game_failed
	}
