extends Area3D

# This will be used to check if the player messes up the note.
func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body is RigidBody3D:
		print("Iceberg Hit, Player lost a heart.")
		get_parent().call_deferred("queue_free")
		# Change bike speed temporarily by adding seconds to timer. - RhythmGameManager
