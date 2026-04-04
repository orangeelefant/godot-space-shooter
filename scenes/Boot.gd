extends Node


func _ready() -> void:
	# Short delay then go to main menu
	get_tree().create_timer(0.2).timeout.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
