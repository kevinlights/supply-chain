extends TextureRect

var stock_indicator_value : float = 1.0
var is_animation_paused = false
var roll_particle = preload("res://game_entities/supply_point/visual_indicators/roll_particle.png")
var box_particle = preload("res://game_entities/supply_point/visual_indicators/box_particle.png")

func update_stock_indicators(_stock_level : int):
	return

func set_indicator_value(newValue : float):
	stock_indicator_value = newValue

func get_indicator_value() -> float:
	return stock_indicator_value

func get_particle_value() -> float:
	return stock_indicator_value

func set_animation_paused(newValue : bool):
	is_animation_paused = newValue

func get_indicator_count() -> int:
	return get_child_count()

func do_cant_consume() -> void:
	pass
