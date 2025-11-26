# SMParser.gd - StepMania file parser
class_name SMParser

var sm_data = {}
var charts = {}  # Dictionary of difficulty -> chart data

func parse_file(file_path: String) -> bool:
	# Convert uid:// path to actual file path if needed
	var actual_path = file_path
	if file_path.begins_with("uid://"):
		actual_path = ResourceUID.get_id_path(ResourceUID.text_to_id(file_path))
		print("Converted uid path to: ", actual_path)
	
	# Store the actual path for later use (like loading audio)
	sm_data["file_path"] = actual_path
	
	var file = FileAccess.open(actual_path, FileAccess.READ)
	
	if file == null:
		push_error("Could not open file: " + actual_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	parse_content(content)
	return sm_data.size() > 0

func parse_content(content: String) -> void:
	var lines = content.split("\n")
	
	# Parse metadata
	for line in lines:
		line = line.strip_edges()
		
		if line.begins_with("#TITLE:"):
			sm_data["title"] = line.substr(7, line.length() - 8)
		elif line.begins_with("#ARTIST:"):
			sm_data["artist"] = line.substr(8, line.length() - 9)
		elif line.begins_with("#MUSIC:"):
			sm_data["music"] = line.substr(7, line.length() - 8)
		elif line.begins_with("#OFFSET:"):
			sm_data["offset"] = float(line.substr(8, line.length() - 9))
		elif line.begins_with("#BPMS:"):
			parse_bpms(line.substr(6, line.length() - 7))
		elif line.begins_with("#STOPS:"):
			sm_data["stops"] = line.substr(7, line.length() - 8)
	
	# Parse all charts
	parse_all_charts(content)
	
	print("Parsed SM File:")
	print("  Title: ", sm_data.get("title", "Unknown"))
	print("  Artist: ", sm_data.get("artist", "Unknown"))
	print("  Music: ", sm_data.get("music", "Unknown"))
	print("  BPM: ", sm_data.get("bpm", 0))
	print("  Offset: ", sm_data.get("offset", 0))
	print("  Charts found: ", charts.keys())

func parse_bpms(bpm_string: String) -> void:
	# Parse BPM changes (format: beat=bpm,beat=bpm,...)
	var bpm_changes = []
	var pairs = bpm_string.split(",")
	
	for pair in pairs:
		var parts = pair.split("=")
		if parts.size() == 2:
			bpm_changes.append({
				"beat": float(parts[0]),
				"bpm": float(parts[1])
			})
	
	sm_data["bpm_changes"] = bpm_changes
	# Store the initial BPM
	if bpm_changes.size() > 0:
		sm_data["bpm"] = bpm_changes[0]["bpm"]

func parse_all_charts(content: String) -> void:
	var chart_sections = content.split("#NOTES:")
	
	for i in range(chart_sections.size()):
		var chart_section = chart_sections[i]
		if chart_section.strip_edges() == "":
			continue
		
		var chart_data = parse_single_chart(chart_section)
		if not chart_data.is_empty():
			var difficulty = chart_data["difficulty"]
			charts[difficulty] = chart_data

func parse_single_chart(chart_section: String) -> Dictionary:
	var chart_lines = chart_section.split("\n")
	var chart_type = ""
	var difficulty = ""
	var rating = 0
	var measures = []
	var measure_buffer = ""
	
	# Skip empty lines at the start
	var line_offset = 0
	for i in range(chart_lines.size()):
		if chart_lines[i].strip_edges() != "":
			line_offset = i
			break
	
	for i in range(chart_lines.size()):
		var line = chart_lines[i].strip_edges()
		
		if line.ends_with(":"):
			line = line.substr(0, line.length() - 1)
		
		# Adjust index based on offset
		var adjusted_index = i - line_offset
		
		# Line 0 (after offset): chart type (dance-single, dance-double, etc.)
		if adjusted_index == 0:
			chart_type = line
		# Line 2 (after offset): difficulty
		elif adjusted_index == 2:
			difficulty = line.to_lower()
		# Line 3 (after offset): rating
		elif adjusted_index == 3:
			rating = int(line) if line.is_valid_int() else 0
		# Lines 5+ (after offset): note data
		elif adjusted_index > 4:
			if line.length() == 4 and is_note_line(line):
				measure_buffer += line + "\n"
			elif line == "," or line == ";":
				if measure_buffer != "":
					var measure_lines = measure_buffer.split("\n", false)
					measures.append(measure_lines)
					measure_buffer = ""
				if line == ";":
					break
	
	# Check for dance-single (with or without colon)
	var is_dance_single = (chart_type == "dance-single" or chart_type == "dance-single:")
	
	if is_dance_single and measures.size() > 0:
		return {
			"difficulty": difficulty,
			"rating": rating,
			"measures": measures
		}
	
	# Return empty dict if not valid
	return {}

func is_note_line(line: String) -> bool:
	for c in line:
		if c not in "01234MLFK":
			return false
	return true

func get_chart(difficulty: String = "medium") -> Array:
	# Return the measures array directly, or empty array if not found
	if charts.has(difficulty):
		return charts[difficulty].get("measures", [])
	
	# Fallback chain with warnings
	var fallbacks = ["medium", "hard", "easy", "beginner"]
	for fallback in fallbacks:
		if fallback != difficulty and charts.has(fallback):
			push_warning("Difficulty '" + difficulty + "' not found, using '" + fallback + "' instead")
			return charts[fallback].get("measures", [])
	
	# If still nothing, use first available
	if charts.size() > 0:
		var first_key = charts.keys()[0]
		push_warning("Difficulty '" + difficulty + "' not found, using '" + first_key + "' instead")
		return charts[first_key].get("measures", [])
	
	push_error("No charts found in file!")
	return []

func get_chart_info(difficulty: String = "medium") -> Dictionary:
	# Return full chart info including rating
	if charts.has(difficulty):
		return charts[difficulty]
	elif charts.has("medium"):
		return charts["medium"]
	elif charts.has("hard"):
		return charts["hard"]
	elif charts.has("easy"):
		return charts["easy"]
	elif charts.size() > 0:
		return charts[charts.keys()[0]]
	return {}

func get_note_at_beat(measures: Array, beat: float) -> String:
	if measures.is_empty():
		return ""
	
	var measure_index = int(beat / 4.0)
	
	if measure_index >= measures.size():
		return ""
	
	var measure = measures[measure_index]
	var beat_in_measure = fmod(beat, 4.0)
	var notes_per_beat = float(measure.size()) / 4.0
	var note_index = int(beat_in_measure * notes_per_beat)
	
	if note_index >= 0 and note_index < measure.size():
		return measure[note_index]
	
	return ""

func get_all_notes_in_range(measures: Array, start_beat: float, end_beat: float) -> Array:
	# Returns array of {beat: float, notes: String}
	var result = []
	
	if measures.is_empty():
		return result
	
	var start_measure = int(start_beat / 4.0)
	var end_measure = int(end_beat / 4.0)
	
	for m in range(start_measure, min(end_measure + 1, measures.size())):
		var measure = measures[m]
		var notes_per_beat = float(measure.size()) / 4.0
		
		for i in range(measure.size()):
			var note_beat = float(m * 4) + (float(i) / notes_per_beat)
			
			if note_beat >= start_beat and note_beat <= end_beat:
				var note_line = measure[i]
				if note_line != "0000":  # Only include lines with notes
					result.append({
						"beat": note_beat,
						"notes": note_line
					})
	
	return result

func load_audio(sm_file_path: String = "") -> AudioStream:
	# Use the stored path from parse_file if not provided
	var actual_path = sm_file_path
	if actual_path == "":
		actual_path = sm_data.get("file_path", "")
	
	# Convert uid:// path to actual file path if needed
	if actual_path.begins_with("uid://"):
		actual_path = ResourceUID.get_id_path(ResourceUID.text_to_id(actual_path))
	
	if actual_path == "":
		push_error("No file path available. Did you call parse_file first?")
		return null
	
	var dir_path = actual_path.get_base_dir()
	var music_file = sm_data.get("music", "")
	
	if music_file == "":
		push_error("No music file specified in .sm file")
		return null
	
	print("Looking for audio in: ", dir_path)
	print("Audio filename: ", music_file)
	
	# Try different audio formats
	var extensions = ["", ".ogg", ".mp3"]  # Try exact filename first
	var base_name = music_file.get_basename()
	
	for ext in extensions:
		var audio_path = ""
		if ext == "":
			audio_path = dir_path + "/" + music_file
		else:
			audio_path = dir_path + "/" + base_name + ext
		
		print("Trying: ", audio_path)
		
		if FileAccess.file_exists(audio_path):
			if audio_path.ends_with(".ogg"):
				var stream = AudioStreamOggVorbis.load_from_file(audio_path)
				if stream:
					print("✓ Loaded audio: ", audio_path)
					return stream
			elif audio_path.ends_with(".mp3"):
				var file = FileAccess.open(audio_path, FileAccess.READ)
				if file:
					var stream = AudioStreamMP3.new()
					stream.data = file.get_buffer(file.get_length())
					file.close()
					print("✓ Loaded audio: ", audio_path)
					return stream
	
	push_error("Could not find audio file: " + music_file + " in " + dir_path)
	return null
