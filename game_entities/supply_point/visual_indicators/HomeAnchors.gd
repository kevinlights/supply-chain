extends "res://game_entities/supply_point/visual_indicators/AnchorsSuper.gd"

var stock_indicator_pool : Array = []
var stock_indicators : Array = []
var consumption_animator : AnimationPlayer

func _ready() -> void:
	if stock_indicators.size() == 0:
		setup_stock_indicators()
	for i in range(0, 20):
		stock_indicator_pool.append(load("res://game_entities/supply_point/visual_indicators/unit_stock_sprites/stock_item_%02d.png" % i))
	consumption_animator = get_node("ConsumptionAnimator")

func update_stock_indicators(stock_level : int) -> void:
	var current_stock_level := stock_level / stock_indicator_value
	if stock_indicators.size() == 0:
		setup_stock_indicators()
	for i in range(0, stock_indicators.size()):
		if i < current_stock_level:
			if stock_indicators[i].visible == false:
				stock_indicators[i].texture = stock_indicator_pool[randi() % stock_indicator_pool.size() - 1]
				stock_indicators[i].visible = true
		else:
			stock_indicators[i].visible = false

func setup_stock_indicators() -> void:
	for indicator in get_children():
		if indicator is TextureRect:
			indicator.visible = false
			stock_indicators.append(indicator)

func get_indicator_count() -> int:
	if stock_indicators.size() == 0:
		setup_stock_indicators()
	return stock_indicators.size()

func do_cant_consume() -> void:
	if !consumption_animator.is_playing():
		consumption_animator.play("no_consume")
