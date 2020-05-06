extends TextureRect

var stock_indicator_pool : Array
var stock_indicator_value : float = 1.0

func _ready():
	for indicator in get_children():
		indicator.visible = false
	for i in range(0, 4):
		stock_indicator_pool.append(load("res://game_entities/supply_point/visual_indicators/unit_stock_sprites/stock_item_%02d.png" % i))

func update_stock_indicators(stock_level : int):
	var current_stock_level := stock_level / stock_indicator_value
	for i in range(0, get_child_count()):
		if i < current_stock_level:
			if get_child(i).visible == false:
				get_child(i).texture = stock_indicator_pool[randi() % stock_indicator_pool.size() - 1]
				get_child(i).visible = true
		else:
			get_child(i).visible = false

func set_indicator_value(newValue : float):
	stock_indicator_value = newValue
