@tool
extends EditorImportPlugin

func _get_importer_name():
	return "stepmania.sm"

func _get_visible_name():
	return "StepMania Chart"

func _get_recognized_extensions():
	return ["sm"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Resource"

func _get_preset_count():
	return 1

func _get_preset_name(_preset):
	return "Default"

func _get_import_options(_path, _preset):
	return []

func _get_option_visibility(_path, _option, _options):
	return true

func _get_priority():
	return 1.0

func _get_import_order():
	return 0

func _import(source_file, save_path, _options, _platform_variants, _gen_files):
	# Read the .sm file
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	
	var content = file.get_as_text()
	file.close()
	
	# Create a simple resource to store the content
	var resource = Resource.new()
	resource.set_meta("sm_content", content)
	resource.set_meta("sm_path", source_file)
	
	# Save as a resource
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(resource, filename)
