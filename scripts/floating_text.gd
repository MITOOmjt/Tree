extends Node2D

var text = "+1"
var font_size = 24
var color = Color(1, 0.9, 0.1, 1)  # 金币色（黄色）
var duration = 1.2  # 动画持续时间稍微延长

# 粒子效果相关变量
var particle_count = 5  # 生成的粒子数量
var particles = []  # 存储粒子信息的数组
var max_distance = 120.0  # 粒子最大移动距离

func _ready():
	# 生成随机的初始方向和移动距离
	randomize()
	
	# 创建主文本动画（弹跳效果）
	var main_tween = create_tween()
	# 先快速向上弹起
	main_tween.tween_property(self, "position:y", position.y - 30, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 然后缓慢继续上升并淡出
	main_tween.tween_property(self, "position:y", position.y - 60, duration - 0.3).set_ease(Tween.EASE_IN)
	main_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), duration - 0.3).set_ease(Tween.EASE_IN)
	main_tween.tween_callback(Callable(self, "queue_free"))
	
	# 初始弹出效果
	scale = Vector2(0.5, 0.5)
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_property(self, "scale", Vector2(1, 1), 0.1)
	
	# 生成粒子效果
	create_particles()

# 创建四散的小粒子效果
func create_particles():
	for i in range(particle_count):
		# 随机角度和距离
		var angle = randf_range(0, 2 * PI)
		var distance = randf_range(50.0, max_distance)
		
		# 计算目标位置（相对于当前位置）
		var target_pos = Vector2(cos(angle) * distance, sin(angle) * distance)
		
		# 随机颜色（金色到橙色的渐变）
		var particle_color = color.lerp(Color(1, 0.6, 0.1, 1), randf())
		
		# 创建粒子
		var particle = {
			"pos": Vector2.ZERO,  # 初始位置（相对于自身）
			"target": target_pos,  # 目标位置
			"size": randf_range(5, 10),  # 随机大小
			"color": particle_color,
			"alpha": 1.0
		}
		
		particles.append(particle)
		
		# 创建粒子动画
		var p_tween = create_tween()
		var particle_ref = particles[i]  # 获取引用以传递给闭包
		
		# 使用闭包更新粒子位置
		p_tween.tween_method(
			func(progress): 
				# 使用弹性函数计算位置
				var pos_progress = _elastic_out(progress)
				particle_ref["pos"] = particle_ref["target"] * pos_progress
				# 线性淡出
				particle_ref["alpha"] = 1.0 - progress
				# 强制重绘
				queue_redraw(),
			0.0, 1.0, duration
		)

# 弹性缓动函数（比Tween.TRANS_ELASTIC更可控）
func _elastic_out(t):
	var p = 0.3
	return pow(2, -10 * t) * sin((t - p / 4) * (2 * PI) / p) + 1

func _draw():
	# 绘制主文本
	var text_size = Vector2(font_size * 0.6 * text.length(), font_size)
	
	# 绘制阴影
	draw_string(
		ThemeDB.fallback_font, 
		Vector2(-text_size.x / 2 + 2, font_size / 2 + 2),  # 右下偏移
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color(0, 0, 0, 0.5 * modulate.a)  # 半透明黑色，跟随主体透明度
	)
	
	# 绘制文本
	draw_string(
		ThemeDB.fallback_font, 
		Vector2(-text_size.x / 2, font_size / 2),  # 居中
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		color
	)
	
	# 绘制粒子
	for particle in particles:
		# 绘制圆形粒子
		var particle_color = particle["color"]
		particle_color.a = particle["alpha"] * modulate.a  # 应用粒子的alpha和主体的alpha
		draw_circle(particle["pos"], particle["size"], particle_color)
		
		# 绘制小拖尾
		var tail_pos = particle["pos"] - particle["target"].normalized() * 5
		var tail_color = particle_color
		tail_color.a *= 0.5
		draw_circle(tail_pos, particle["size"] * 0.6, tail_color) 
