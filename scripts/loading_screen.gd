extends Control

var path: String

var scene_ready := false
var scene_resource

var timer := 0.0
var min_load_time := 0.6

@onready var bar = $ProgressBar


func _ready() -> void:
	path = Global.get_next_scene()

	print("Loading scene:", path)

	if path == "":
		push_error("Loading screen: next_scene is empty!")
		return

	var err = ResourceLoader.load_threaded_request(path)

	if err != OK:
		push_error("Failed to start threaded load: " + path)


func _process(delta: float) -> void:
	if path == "":
		return

	timer += delta

	var progress := []
	var status = ResourceLoader.load_threaded_get_status(path, progress)

	# Update progress bar (if available)
	if progress.size() > 0:
		var p = progress[0] * 100.0
		bar.value = lerp(bar.value, max(bar.value, bar.value), 0.2)
		bar.value = max(bar.value, p)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass

		ResourceLoader.THREAD_LOAD_LOADED:
			scene_resource = ResourceLoader.load_threaded_get(path)
			scene_ready = true

		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + path)

	# Only switch when BOTH conditions are met
	if scene_ready and timer >= min_load_time:
		get_tree().change_scene_to_packed(scene_resource)
