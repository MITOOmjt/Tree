# AI助手行为指南

这个文档定义了AI助手在本项目中应该遵循的行为规范。

## 文件管理警告

在以下情况下，AI助手应主动提醒用户：

1. **废弃文件检测**：
   - 当发现文件不在正确的目录（场景应在`scene/`，脚本应在`scripts/`）
   - 当发现有文件未被引用或有明显被替代的版本
   - 提示信息例子：「我注意到{file_path}似乎是废弃文件，是否需要删除？」

2. **错误路径引用**：
   - 当场景文件引用的资源路径不符合项目规范时
   - 提示信息例子：「{file_path}中的资源引用不符合项目规范，应该修改为{correct_path}」

3. **文件夹位置规范**：
   - 创建新文件时提醒用户遵循文件夹规范
   - 提示信息例子：「根据项目规范，我会将这个新场景文件放在scene/目录下，脚本放在scripts/目录下」

4. **项目结构警告**：
   - 警惕项目中存在多个相同名称的文件位于不同目录（如`/scripts`和`/treegame/scripts`）
   - 确认对哪个文件的修改会实际影响游戏运行
   - 提示信息例子：「注意：发现多个{file_name}文件，请确认您要修改的是{correct_path}而非{wrong_path}」

5. **项目结构清理**：
   - 发现重复文件时，主动建议用户进行清理
   - 删除废弃或未被引用的副本文件
   - 确保所有引用指向唯一且正确的文件路径
   - 提示信息例子：「项目中存在多个{file_name}文件，建议保留{primary_file}并删除{duplicate_files}，然后更新所有引用」

## 文件唯一性和标准化

为防止项目中出现重复文件，AI助手应遵循以下原则：

1. **文件位置唯一性**：
   - 每个脚本和场景文件在项目中应当只有一个版本
   - 脚本文件仅存放在`scripts/`目录下
   - 场景文件仅存放在`scene/`目录下
   - 确保不会在`treegame/scripts/`和`scripts/`等不同目录下创建同名文件

2. **文件迁移建议**：
   - 发现文件位于错误目录时，建议用户将其移动到正确位置
   - 移动文件后，确保更新所有引用该文件的地方
   - 移动文件前，确保备份或提交当前更改
   - 提示信息例子：「建议将{wrong_path}移动到{correct_path}，并更新所有引用该文件的地方」

## 代码审查

AI助手在帮助用户编写或修改代码时，应主动检查：

1. 变量和函数命名是否符合规范
2. 缩进是否使用4个空格
3. 代码是否注释清晰
4. 确保所有变量和函数在使用前已正确声明
5. 检查资源preload路径是否正确（应使用`res://scene/`或`res://scripts/`开头）

## UI设计和交互指南

1. **UI组件设计**：
   - 按钮应具有清晰的视觉反馈（悬停效果、点击状态）
   - 文本标签应使用适当的字体大小和颜色，确保可读性
   - 面板和容器应有合适的边距和间距
   - 提示信息例子：「按钮应该添加悬停效果以提高用户体验」

2. **UI交互模式**：
   - 可折叠UI应具有明确的打开/关闭控件
   - 避免UI元素自动隐藏或突然消失，除非是预期行为
   - 为交互操作提供适当的视觉和文本反馈
   - 提示信息例子：「建议为这个UI面板添加可折叠功能和明确的关闭按钮」

3. **输入处理**：
   - 确保UI元素正确捕获和处理输入事件
   - 防止点击穿透问题，避免UI点击影响下层游戏世界
   - 正确处理信号连接和断开连接
   - 提示信息例子：「这个UI面板需要防止点击穿透到游戏世界」

4. **PopupPanel特殊处理**：
   - 当使用PopupPanel时，注意处理其自动隐藏行为
   - 如需保持面板可见，应实现防止自动关闭的机制
   - 提示信息例子：「为防止PopupPanel自动关闭，需要实现自定义的popup_hide处理」

## 响应风格

1. 回答应该简洁明了
2. 给出具体建议而非笼统的指导
3. 所有回复使用中文

## 项目特定规则

针对树游戏项目的特殊规则：

1. 场景和对应脚本应保持同名(不含扩展名)
2. 树木相关的逻辑应遵循现有的direct_tree.gd实现方式
3. 金币系统的修改应通过Global单例进行
4. 鸟的生成应保持在树的子节点下 
5. 每次产生改动后，都需要在对话里提醒我是否要git上传
6. **注意Godot 4.3语法特性**：
   - 信号连接语法：使用 `node.signal_name.connect(callable)` 而非旧版的 `node.connect("signal_name", callable)`
   - 信号断开连接：使用 `node.disconnect("signal_name", Callable(self, "method_name"))` 
   - 示例：
	 ```gdscript
	 # 正确的Godot 4.3连接方式
	 button.pressed.connect(_on_button_pressed)
	 
	 # 错误的旧版连接方式
	 button.connect("pressed", _on_button_pressed)
	 ```
7. **脚本版本检查**：
   - 修改脚本前，确认Godot项目使用的是哪个版本的脚本文件
   - 在修复语法错误或解析错误时，优先考虑完全重写文件而不是局部修改
   - 提示信息例子：「我注意到脚本解析错误可能是由不完整的编辑导致的，建议重写整个脚本文件」

8. **Git仓库结构注意事项**：
   - 确认修改的文件是否在Git仓库内，某些文件可能位于仓库外
   - 如果修改了仓库外的文件，提醒用户这些更改不会被Git跟踪
   - 提示信息例子：「注意：您修改的文件{file_path}不在Git仓库内，这些更改不会被Git跟踪」

9. **资源路径标准化**：
   - 所有场景文件应位于`res://scene/`目录下
   - 所有脚本文件应位于`res://scripts/`目录下
   - 所有预加载资源路径应以`res://scene/`或`res://scripts/`开头
   - 提示信息例子：「资源路径应使用标准格式，如`res://scene/flower.tscn`而非`res://flower.tscn`」

10. **GameConfig单例使用规范**：
   - 生成物的费用、花朵和树木的金币产出配置应通过GameConfig单例进行管理
   - 脚本中应使用_load_config()函数从GameConfig加载配置
   - 不要在不同脚本中硬编码金币费用或产出值
   - 生成物的放置位置Y轴偏移量应通过GameConfig的placement_offset参数管理
   - 修改生成物的Y轴偏移量应通过GameConfig.set_placement_offset(type, offset)方法
   - 提示信息例子：「生成物费用应从GameConfig加载，而非直接在脚本中设置固定值」
   - 提示信息例子：「要调整树木的放置Y轴偏移，请使用game_config.set_placement_offset(GeneratorType.TREE, -50)」

11. **金币系统的修改和配置**：
   - 金币消耗和获取应通过GameConfig中定义的配置进行管理
   - 修改生成物费用时，应修改game_config.gd中的generator_templates字典
   - 修改金币产出时，应修改game_config.gd中的generation字典中的相应值
   - 提示信息例子：「要修改树的生成费用，请更新GameConfig.get_generator_template(GeneratorType.TREE).base_cost的值」

12. **能力系统实现规范**：
   - 所有生成物脚本必须在每次触发奖励前重新计算最新的效果值
   - 使用GameConfig提供的通用方法calculate_generator_reward来获取当前奖励值
   - 不要在生成物脚本中缓存能力效果值，应在每次需要时实时计算
   - 提示信息例子：「在_give_hover_reward函数中应调用game_config.calculate_generator_reward()获取最新奖励值」

13. **能力升级处理**：
   - 升级能力后必须调用background_manager.refresh_generators_config()刷新所有生成物的配置
   - 但所有生成物仍需在其产出奖励函数中实时重新计算效果值，以防止刷新失败
   - 提示信息例子：「升级能力后，确保触发refresh_generators_config()并且所有产出函数都重新计算奖励值」
   
14. **新增能力类型规范**：
   - 新增能力类型应在GameConfig的generator_templates对应生成物的abilities字典中定义
   - 每个能力必须包含level、base_cost、growth_factor、effect_per_level和max_level字段
   - 新增能力类型的效果计算必须遵循标准公式：1 + (level - 1) * effect_per_level
   - 提示信息例子：「新增"range"能力应在generator_templates中遵循现有能力的定义格式，并确保效果计算一致」

15. **效果计算调试**：
   - 修改能力相关代码时，应添加足够的调试输出，包括基础值、效果乘数和最终计算结果
   - 提供明确的日志信息，包括能力名称、当前等级、调整前后的值等
   - 提示信息例子：「添加调试输出，打印"从GameConfig加载花效率乘数:{multiplier}，基础值:{base}，最终奖励:{reward}"」

16. **生成物放置位置配置**：
   - 生成物的Y轴偏移配置应统一从GameConfig中的placement_offset参数获取
   - 不要在生成物脚本或background_manager中硬编码位置偏移值
   - 添加新生成物类型时，必须在其template中包含placement_offset参数
   - 任何位置调整操作应通过修改GameConfig中的配置而非修改渲染代码
   - 提示信息例子：「要调整所有花朵的Y轴位置，应修改GameConfig中的placement_offset参数，而非在生成代码中添加硬编码偏移」

17. **结构化日志系统使用规范**：
   - 所有脚本必须在顶部添加 `@onready var _logger = get_node("/root/Logger")` 以获取Logger单例
   - 不要使用print函数输出调试信息，应该使用结构化日志系统
   - 按照日志级别使用不同方法：_logger.debug(), _logger.info(), _logger.warning(), _logger.error()
   - 日志输出应包含必要的上下文信息，便于调试
   - 提示信息例子：「使用_logger.debug("从GameConfig加载金币产出量: %s", coin_amount)代替print语句」

18. **Ghibli风格主题应用规范**：
   - 所有UI元素应使用GhibliTheme单例提供的方法应用一致的视觉风格
   - 对于按钮：使用GhibliTheme.apply_button_theme(button, variant, font_size)
   - 对于标签：使用GhibliTheme.apply_label_theme(label, variant, font_size)
   - 对于面板：使用GhibliTheme.apply_panel_theme(panel)
   - 提示信息例子：「新UI元素应使用GhibliTheme.apply_button_theme(upgrade_button, "green", 15)应用主题样式」

19. **图像资源使用规范**：
   - 游戏中的视觉元素应优先使用resource目录下的图像资源而非硬编码的形状
   - 鸟类元素应使用resource/bird.png
   - 树木元素应使用resource/tree.png
   - 背景元素应使用resource/bg.png
   - 使用Sprite2D节点代替Polygon2D节点，并配合适当的碰撞形状
   - 提示信息例子：「使用Sprite2D显示resource/tree.png替代Polygon2D绘制的树形状」
   - 提示信息例子：「确保碰撞区域大小与视觉图像相匹配，避免点击检测问题」

20. **点击区域处理规范**：
   - 对于可点击的游戏元素，应使用Area2D和CollisionShape2D组件处理点击交互
   - 不要使用自定义的点击检测算法，除非有特殊需求
   - 点击事件应使用Area2D的input_event信号处理而非_input函数
   - 提示信息例子：「将点击检测从自定义三角形算法改为使用标准的Area2D和CollisionShape2D」

21. **图像资源替换检查清单**：
   - 在替换游戏中的图像资源时，必须执行以下检查以确保功能正常：
     1. **碰撞形状检查**：调整CollisionShape2D大小以适应新图像
     2. **信号连接验证**：确认所有信号仍然正确连接
     3. **输入处理确认**：验证input_pickable属性为true（对于可交互元素）
     4. **缩放比例调整**：根据新图像调整scale属性，保持适当的视觉大小
     5. **位置偏移验证**：确认position属性设置正确，与旧图像保持一致的参考点
     6. **Z轴顺序检查**：确保z_index设置正确，维持正确的渲染顺序
     7. **调试输出添加**：在替换后添加临时调试日志，验证交互功能
   - 提示信息例子：「在替换树木图像后，请务必检查碰撞形状大小、信号连接和输入处理是否正常工作」
   - 提示信息例子：「在提交前，测试鼠标点击功能是否在新图像上正常工作」

## 项目技术规范

### GDScript

### 游戏配置管理

- 游戏配置通过单例`GameConfig`集中管理，避免在各个脚本中硬编码参数值
- 添加新实体时，应在GameConfig.generator_templates中添加对应的模板配置
- 修改生成物费用时，应修改对应模板的base_cost和growth_factor值
- 提示信息例子：「要修改树的生成费用，请更新GameConfig.get_generator_template(GeneratorType.TREE).base_cost的值」
- 修改金币产出时，应修改对应模板的generation字典中的相应值

### 金币系统规则

- 所有涉及金币获取或消耗的实体必须通过调用`Global.add_coins()`或`Global.remove_coins()`来修改金币数量
- 所有实体必须在_ready()函数中调用_load_config()来从GameConfig加载配置参数
- 调试金币变化时应使用print语句打印相关信息，例如："树产生X金币，当前总金币：Y"
