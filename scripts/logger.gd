extends Node

# 日志级别枚举
enum LogLevel {DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, CRITICAL = 4}

# 配置项
var _current_level = LogLevel.DEBUG  # 当前日志级别
var _log_to_console = true           # 是否输出到控制台
var _log_to_file = false             # 是否输出到文件
var _log_file_path = "user://game_log.txt"  # 日志文件路径
var _max_log_file_size = 1024 * 1024 # 最大日志文件大小（1MB）

# 日志级别名称
var _level_names = {
    LogLevel.DEBUG: "调试",
    LogLevel.INFO: "信息",
    LogLevel.WARNING: "警告",
    LogLevel.ERROR: "错误",
    LogLevel.CRITICAL: "致命"
}

# 日志级别颜色（控制台输出时使用）
var _level_colors = {
    LogLevel.DEBUG: "808080",    # 灰色
    LogLevel.INFO: "FFFFFF",     # 白色
    LogLevel.WARNING: "FFFF00",  # 黄色
    LogLevel.ERROR: "FF0000",    # 红色
    LogLevel.CRITICAL: "FF00FF"  # 洋红色
}

# 初始化
func _ready():
	print("日志系统已初始化")
	# 创建日志文件目录（如果需要）
	if _log_to_file:
		var dir = DirAccess.open("user://")
		if dir == null:
			print("错误: 无法访问用户目录")
			_log_to_file = false
	
	# 根据是否为调试构建设置默认日志级别
	if OS.is_debug_build():
		set_level(LogLevel.DEBUG)
		info("调试模式已启用，日志级别设置为DEBUG")
	else:
		set_level(LogLevel.INFO)
		info("发布模式已启用，日志级别设置为INFO")

# 记录日志
func _log(level, message, source = ""):
	# 检查是否应该记录此级别的日志
	if level < _current_level:
		return
		
	# 格式化日志条目
	var datetime = Time.get_datetime_dict_from_system()
	var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	var level_str = _level_names[level]
	var color_code = _level_colors[level]
	
	# 如果没有提供来源，尝试获取调用者信息
	if source.is_empty():
		var stack = get_stack()
		if stack.size() > 2:  # 跳过_log和具体日志方法
			source = stack[2]["source"].get_file()
			
	# 完整日志条目
	var log_entry = "[%s] [%s] %s: %s" % [time_str, level_str, source, message]
	
	# 输出到控制台
	if _log_to_console:
		if OS.has_feature("editor") || OS.has_feature("standalone"):
			# 编辑器或独立应用中，简单打印
			print(log_entry)
		else:
			# 网页或其他环境，可能支持彩色输出
			var colored_entry = "[color=#%s]%s[/color]" % [color_code, log_entry]
			print(colored_entry)
	
	# 输出到文件
	if _log_to_file:
		_write_to_log_file(log_entry)

# 写入日志文件
func _write_to_log_file(log_entry):
	var file = FileAccess.open(_log_file_path, FileAccess.READ_WRITE)
	if file == null:
		# 文件可能不存在，尝试创建
		file = FileAccess.open(_log_file_path, FileAccess.WRITE)
		if file == null:
			print("错误: 无法创建日志文件")
			_log_to_file = false
			return
	
	# 检查文件大小
	if file.get_length() > _max_log_file_size:
		file.close()
		# 创建新文件
		file = FileAccess.open(_log_file_path, FileAccess.WRITE)
		if file:
			file.store_line("=== 日志文件已重置 (达到最大大小) ===")
		else:
			print("错误: 无法重置日志文件")
			return
	
	# 将文件指针移到末尾
	file.seek_end()
	
	# 写入日志条目
	file.store_line(log_entry)
	file.close()

# 各级别日志记录方法
func debug(message, source = ""):
	_log(LogLevel.DEBUG, message, source)
	
func info(message, source = ""):
	_log(LogLevel.INFO, message, source)
	
func warning(message, source = ""):
	_log(LogLevel.WARNING, message, source)
	
func error(message, source = ""):
	_log(LogLevel.ERROR, message, source)
	
func critical(message, source = ""):
	_log(LogLevel.CRITICAL, message, source)

# 配置方法
func set_level(level):
	if level >= LogLevel.DEBUG and level <= LogLevel.CRITICAL:
		_current_level = level
		# 使用print而不是info，避免在设置级别时可能的递归调用
		print("日志级别已设置为: " + _level_names[level])

func enable_console_output(enable = true):
	_log_to_console = enable
	info("控制台日志输出已" + ("启用" if enable else "禁用"))
	
func enable_file_output(enable = true):
	var old_state = _log_to_file
	_log_to_file = enable
	
	if enable and !old_state:
		info("日志现在将记录到文件: " + _log_file_path)
	elif !enable and old_state:
		info("日志文件记录已禁用")
		
func set_log_file_path(path):
	_log_file_path = path
	if _log_to_file:
		info("日志文件路径已更改为: " + path)

# 获取当前日志级别
func get_current_level():
	return _current_level

# 获取日志级别名称
func get_level_name(level):
	if _level_names.has(level):
		return _level_names[level]
	return "未知" 