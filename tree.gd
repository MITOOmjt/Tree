extends Node2D

var bird_scene = preload("res://bird.tscn")

func _ready():
	# Godot 4.3的信号连接方式，使用Area2D的input_event信号
	$TreeShape.input_event.connect(_on_tree_input)

func _on_tree_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var bird = bird_scene.instantiate()
		add_child(bird)
		# 在点击位置生成鸟
		bird.position = get_local_mouse_position() 