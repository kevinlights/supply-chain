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
	stock_in.set_text(str(sp.stock_in))
	stock_out.set_text(str(abs(sp.stock_out)))
	waste.set_text(str(sp.waste))
	opening_stock.set_text(str(sp.opening_stock))
	closing_stock.set_text(str(sp.closing_stock))
	ticks_max.set_text(str(sp.ticks_at_max))
	ticks_min.set_text(str(sp.ticks_at_min))

	if sp.is_producing:
		get_node("Row2/TicksWOProd").visible = true
		get_node("Row2/Efficiency").visible = false
		ticks_wo_prod.set_text(str(sp.ticks_no_produce))
		get_node("Row1/StockIn/Title").set_text("Stock\nProduced")
	else:
		efficiency.set_text("0" if sp.stock_in == 0 else str(sp.transit_time / sp.stock_in))

	if sp.is_consuming:
		get_node("Row1/StockOut/Title").set_text("Stock\nConsumed")
		get_node("Row2/TicksWOCons").visible = true
		ticks_wo_cons.set_text(str(sp.ticks_no_consume))


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
