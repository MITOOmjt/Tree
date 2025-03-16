extends Control

# 按钮动画参数
var button_animation_time: float = 0.0
var button_animation_speed: float = 2.0
var button_original_position: Vector2

func _ready():
	# 确保"开始游戏"按钮连接到点击事件
	$StartButton.pressed.connect(_on_start_button_pressed)
	
	# 保存按钮原始位置用于动画
	button_original_position = $StartButton.position

func _process(delta):
	# 给标题和按钮添加简单的浮动动画
	button_animation_time += delta * button_animation_speed
	$StartButton.position.y = button_original_position.y + sin(button_animation_time) * 5.0
	
	# 让标题也有轻微的动画
	$TitleLabel.modulate.a = 0.8 + sin(button_animation_time * 0.5) * 0.2

# 当开始按钮被点击时，切换到主场景
func _on_start_button_pressed():
	# 添加简单的过渡效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(Callable(self, "_change_scene"))

# 场景切换函数
func _change_scene():
	get_tree().change_scene_to_file("res://scene/main.tscn") 