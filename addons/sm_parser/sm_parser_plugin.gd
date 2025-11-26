@tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	# Add the custom import plugin
	import_plugin = preload("sm_import_plugin.gd").new()
	add_import_plugin(import_plugin)
	
	print("StepMania Parser plugin enabled!")

func _exit_tree():
	# Remove the import plugin
	remove_import_plugin(import_plugin)
	import_plugin = null
	
	print("StepMania Parser plugin disabled!")
