extends Control

var sp : HBoxContainer
var title : Label
var stock_in : Label
var stock_out : Label
var waste : Label
var opening_stock : Label
var closing_stock : Label
var ticks_max : Label
var ticks_min : Label
var ticks_wo_prod : Label
var ticks_wo_cons : Label
var efficiency : Label
var charts_button : TextureButton

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

	stock_in.set_text(str(sp.stock_in) + get_rise_fall(check, sp.stock_in, sp.historic_stock["stock_in"]))
	stock_out.set_text(str(abs(sp.stock_out)) + get_rise_fall(check, abs(sp.stock_out), sp.historic_stock["stock_out"]))
	waste.set_text(str(sp.waste) + get_rise_fall(check, sp.waste, sp.historic_stock["waste"]))
	opening_stock.set_text(str(sp.opening_stock) + get_rise_fall(check, sp.opening_stock, sp.historic_stock["opening_stock"]))
	closing_stock.set_text(str(sp.closing_stock) + get_rise_fall(check, sp.closing_stock, sp.historic_stock["closing_stock"]))
	ticks_max.set_text(str(sp.ticks_at_max) + get_rise_fall(check, sp.ticks_at_max, sp.historic_time["time_full"]))
	ticks_min.set_text(str(sp.ticks_at_min) + get_rise_fall(check, sp.ticks_at_min, sp.historic_time["time_empty"]))

	if sp.is_producing:
		get_node("Row2/TicksWOProd").visible = true
		get_node("Row2/Efficiency").visible = false
		ticks_wo_prod.set_text(str(sp.ticks_no_produce) + get_rise_fall(check, sp.ticks_no_produce, sp.historic_time["unable_to_produce"]))
		get_node("Row1/StockIn/Title").set_text("Stock\nProduced")
	else:
		efficiency.set_text(("0" if sp.stock_in == 0 else str(sp.transit_time / sp.stock_in)) + get_rise_fall(check, 0 if sp.stock_in == 0 else sp.transit_time / sp.stock_in, sp.historic_misc["transit_efficiency"]))

	if sp.is_consuming:
		get_node("Row1/StockOut/Title").set_text("Stock\nConsumed")
		get_node("Row2/TicksWOCons").visible = true
		ticks_wo_cons.set_text(str(sp.ticks_no_consume) + get_rise_fall(check, sp.ticks_no_consume, sp.historic_time["unable_to_consume"]))

func get_rise_fall(check, value, history):
	if check:
		var last_value = abs(history[history.size() - 1])
		if value > last_value:
			return "▲"
		elif value < last_value:
			return "▼"
		else:
			return ""
	return ""


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
