extends TextureRect

var stock_indicator_value : float = 1.0
var is_animation_paused = false

func update_stock_indicators(_stock_level : int):
	return

func set_indicator_value(newValue : float):
	stock_indicator_value = newValue

func set_animation_paused(newValue : bool):
	is_animation_paused = newValue
