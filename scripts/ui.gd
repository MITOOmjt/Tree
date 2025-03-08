extends CanvasLayer

@onready var coins_label = $Control/Panel/CoinsLabel
@onready var message_label = $Control/MessagePanel/MessageLabel

var default_message = "点击树生成鸟 (花费10金币)"
var message_timer: Timer

func _ready():
	print("UI初始化")
	# 连接到全局金币变化信号
	Global.coins_changed.connect(_on_coins_changed)
	
	# 连接到消息总线
	MessageBus.get_instance().show_message.connect(show_message)
	
	# 初始化显示
	update_coins_display(Global.get_coins())
	
	# 初始化消息
	show_message(default_message)
	
	# 创建定时器用于清除消息
	message_timer = Timer.new()
	message_timer.name = "MessageTimer"
	message_timer.wait_time = 3.0
	message_timer.one_shot = true
	add_child(message_timer)
	message_timer.timeout.connect(_on_message_timer_timeout)

func _on_coins_changed(amount):
	update_coins_display(amount)
	
func update_coins_display(amount):
	coins_label.text = "金币: " + str(amount)
	
func show_message(text, duration = 0):
	message_label.text = text
	
	# 如果指定了持续时间，设置定时器
	if duration > 0:
		message_timer.wait_time = duration
		message_timer.start()
	
func _on_message_timer_timeout():
	# 恢复默认消息
	message_label.text = default_message 