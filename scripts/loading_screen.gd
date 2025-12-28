extends Control

@onready var progress_bar = $ProgressBar
@onready var status_label = $Label

var target_scene_path = ""
var loading_status = 0
var progress = []

func _ready():
	target_scene_path = GameData.target_scene_path
	if target_scene_path == "":
		status_label.text = "Error: No target scene!"
		return
		
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta):
	if target_scene_path == "":
		return
		
	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if loading_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		progress_bar.value = progress[0] * 100
		status_label.text = "Loading... " + str(int(progress[0] * 100)) + "%"
	elif loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		progress_bar.value = 100
		status_label.text = "Done!"
		set_process(false)
		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)
	elif loading_status == ResourceLoader.THREAD_LOAD_FAILED:
		status_label.text = "Loading Failed!"
		set_process(false)
