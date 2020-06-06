extends Control

enum BadChange {UP, DOWN, NONE}
var sp : HBoxContainer
var title : Label
var stock_in : RichTextLabel
var stock_out : RichTextLabel
var waste : RichTextLabel
var opening_stock : RichTextLabel
var closing_stock : RichTextLabel
var ticks_max : RichTextLabel
var ticks_min : RichTextLabel
var ticks_wo_prod : RichTextLabel
var ticks_wo_cons : RichTextLabel
var efficiency : RichTextLabel
var charts_button : TextureButton
var bad_prefix := "[color=red]"
var bad_suffix := "[/color]"


# Link up nodes that are going to get values
func _ready():
	setup_nodes()
	charts_button.connect("pressed", get_parent().get_parent().get_parent().get_parent(), "setup_charts", [sp])


# Take dict originally from supply point and populate report values
func write_values(supply_point : HBoxContainer) -> void:
	if !is_instance_valid(title):
		setup_nodes()

	sp = supply_point
	title.set_text(sp.sp_name.capitalize())

	var check = false
	if sp.historic_stock["stock_in"].size() > 0:
		check = true

	stock_in.set_bbcode("[right]" + get_value_string(sp.stock_in, check, sp.historic_stock["stock_in"]))
	stock_out.set_bbcode("[right]" + get_value_string(abs(sp.stock_out), check, sp.historic_stock["stock_out"]))
	waste.set_bbcode("[right]" + get_value_string(sp.waste, check, sp.historic_stock["waste"], BadChange.UP))
	opening_stock.set_bbcode("[right]" + get_value_string(sp.opening_stock, check, sp.historic_stock["opening_stock"]))
	closing_stock.set_bbcode("[right]" + get_value_string(sp.closing_stock, check, sp.historic_stock["closing_stock"]))
	ticks_max.set_bbcode("[right]" + get_value_string(sp.ticks_at_max, check, sp.historic_time["time_full"], BadChange.UP))
	ticks_min.set_bbcode("[right]" + get_value_string(sp.ticks_at_min, check, sp.historic_time["time_empty"], BadChange.UP))

	if sp.is_producing:
		get_node("Row2/TicksWOProd").visible = true
		get_node("Row2/Efficiency").visible = false
		ticks_wo_prod.set_bbcode("[right]" + get_value_string(sp.ticks_no_produce, check, sp.historic_time["unable_to_produce"], BadChange.UP))
		get_node("Row1/StockIn/Title").set_text("Stock\nProduced")
	else:
		efficiency.set_bbcode("[right]" + get_value_string(0.0 if sp.stock_in == 0 else sp.transit_time / sp.stock_in, check, sp.historic_misc["transit_efficiency"], BadChange.DOWN))

	if sp.is_consuming:
		get_node("Row1/StockOut/Title").set_text("Stock\nConsumed")
		get_node("Row2/TicksWOCons").visible = true
		ticks_wo_cons.set_bbcode("[right]" + get_value_string(sp.ticks_no_consume, check, sp.historic_time["unable_to_consume"], BadChange.UP))

func get_value_string(value, check, history, bad = BadChange.NONE):
	return get_formatted_value(value, bad) + get_rise_fall(check, value, history, bad)

func get_formatted_value(value, bad):
	var return_string
	if value is int:
		return_string = str(value)
	else:
		return_string = "%.2f" % value
	if value > 0:
		if bad == BadChange.UP:
			return_string = bad_prefix + return_string + bad_suffix
	else:
		if bad == BadChange.DOWN:
			return_string = bad_prefix + return_string + bad_suffix
	return return_string

func get_rise_fall(check, value, history, bad = BadChange.NONE):
	var return_string = ""
	if check:
		var last_value = abs(history[history.size() - 1])
		if value > last_value:
			return_string += "▲"
			if bad == BadChange.UP:
				return_string = bad_prefix + return_string + bad_suffix
		elif value < last_value:
			return_string += "▼"
			if bad == BadChange.DOWN:
				return_string = bad_prefix + return_string + bad_suffix
	return return_string


# Helper to assign labels to variables
func setup_nodes() -> void:
	charts_button = get_node("Row0/HistoricButton")
	title = get_node("Row0/SP_name")
	stock_in = get_node("Row1/StockIn/Value")
	stock_out = get_node("Row1/StockOut/Value")
	waste = get_node("Row1/Waste/Value")
	opening_stock = get_node("Row1/OpeningStock/Value")
	closing_stock = get_node("Row1/ClosingStock/Value")
	ticks_max = get_node("Row2/TicksMax/Value")
	ticks_min = get_node("Row2/TicksMin/Value")
	ticks_wo_prod = get_node("Row2/TicksWOProd/Value")
	ticks_wo_cons = get_node("Row2/TicksWOCons/Value")
	efficiency = get_node("Row2/Efficiency/Value")
