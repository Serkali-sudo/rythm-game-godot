extends Control

@onready var song_container = $VBoxContainer/SongContainer

var songs = [
	{"name": "Under Neon Skies", "path": "res://assets/music/under_neon_skies.mp3"},
	{"name": "Neon Air", "path": "res://assets/music/neon_air.mp3"},
	{"name": "Neon Bomb", "path": "res://assets/music/neon_bomb.mp3"},
	{"name": "Neon Tick", "path": "res://assets/music/neon_tick.mp3"},
]

func _ready():
	for song in songs:
		var btn = Button.new()
		btn.text = song["name"]
		btn.custom_minimum_size = Vector2(400, 80)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_song_selected.bind(song["path"]))
		song_container.add_child(btn)

func _on_song_selected(path: String):
	GameData.selected_song = path
	get_tree().change_scene_to_file("res://scenes/main.tscn")
