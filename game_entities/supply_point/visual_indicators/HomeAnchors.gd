extends "res://game_entities/supply_point/visual_indicators/AnchorsSuper.gd"

var stock_indicator_pool : Array = []
var stock_indicators : Array = []
var cant_consume_animator : AnimationPlayer

func _ready():
	cant_consume_animator = get_node("AnimationPlayer")
	for indicator in get_children():
		if indicator is TextureRect:
			indicator.visible = false
			stock_indicators.append(indicator)
	for i in range(0, 20):
		stock_indicator_pool.append(load("res://game_entities/supply_point/visual_indicators/unit_stock_sprites/stock_item_%02d.png" % i))

func update_stock_indicators(stock_level : int):
	var current_stock_level := stock_level / stock_indicator_value
	for i in range(0, stock_indicators.size()):
		if i < current_stock_level:
			if stock_indicators[i].visible == false:
				stock_indicators[i].texture = stock_indicator_pool[randi() % stock_indicator_pool.size() - 1]
				stock_indicators[i].visible = true
		else:
			stock_indicators[i].visible = false

func get_indicator_count() -> int:
	var indicators = 0
	for indicator in get_children():
		if indicator is TextureRect:
			indicators += 1
	return indicators

func do_cant_consume() -> void:
	if !cant_consume_animator.is_playing():
		cant_consume_animator.play("no_consume")
