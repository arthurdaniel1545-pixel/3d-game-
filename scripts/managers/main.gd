extends Node

func _ready() -> void:
	# Entry point: go to main menu
	call_deferred("_go_to_menu")

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
