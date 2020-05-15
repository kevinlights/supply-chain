extends TextureRect

var stock_indicator_pool : Array
var stock_indicator_value : float = 1.0

var conveyor_tweens : Array = []
var stock_indicators : Array = []

func _ready():
	for indicator in get_children():
		if indicator is TextureRect:
			indicator.visible = false
			stock_indicators.push_back(indicator)

	var conveyor_time = 3.0
	var conveyor_count = 4
	var item_count = 5
	var item_gap = 0.5
	var conveyor_gap = item_gap * item_count

	for i in range(conveyor_count):
		var start = 0.0
		var end = 1.0
		if i == 0 || i == 3:
			start = 1.0
			end = 0.0
		if i == 2:
			item_gap = item_gap * 3
			conveyor_time = conveyor_time * 1.5
		conveyor_tweens.push_back(Tween.new())
		add_child(conveyor_tweens.back())
		conveyor_tweens.back().interpolate_property(get_node("Conveyor" + str(i + 1) + "/PathFollow2D"), "unit_offset", start, end, conveyor_time, Tween.TRANS_LINEAR, Tween.EASE_IN, conveyor_gap * i)
		conveyor_tweens.back().set_repeat(true)
		conveyor_tweens.back().start()

		for j in range(item_count):
			var temp = get_node("Conveyor" + str(i + 1) + "/PathFollow2D").duplicate()
			get_node("Conveyor" + str(i + 1)).add_child(temp)
			conveyor_tweens.back().interpolate_property(temp, "unit_offset", start, end, conveyor_time, Tween.TRANS_LINEAR, Tween.EASE_IN, conveyor_gap * i + item_gap * j)


func update_stock_indicators(stock_level : int):
	var current_stock_level := stock_level / stock_indicator_value
	for i in range(0, stock_indicators.size()):
		if i < current_stock_level:
			if stock_indicators[i].visible == false:
				stock_indicators[i].visible = true
		else:
			stock_indicators[i].visible = false

func set_indicator_value(newValue : float):
	stock_indicator_value = newValue
