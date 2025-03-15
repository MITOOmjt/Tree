extends Node

# 消息信号
signal show_message(text, duration)

# 单例模式
var _instance = null

func _init():
	if _instance != null:
		push_error("MessageBus已经存在!")
	_instance = self

static func get_instance() -> Node:
	return Engine.get_main_loop().root.get_node("/root/MessageBus") 
