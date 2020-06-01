extends Control

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

# Link up nodes that are going to get values
func _ready():
	setup_nodes()

# Take dict originally from supply point and populate report values
func write_values(dict) -> void:
	if !is_instance_valid(title):
		setup_nodes()

	title.set_text(dict["name"])
	stock_in.set_text(str(dict["stock_in"]))
	stock_out.set_text(str(dict["stock_out"]))
	waste.set_text(str(dict["waste"]))
	opening_stock.set_text(str(dict["opening"]))
	closing_stock.set_text(str(dict["closing"]))
	ticks_max.set_text(str(dict["max"]))
	ticks_min.set_text(str(dict["min"]))
	efficiency.set_text(str(dict["efficiency"]))
	if dict["is_prod"]:
		get_node("ColorRect/VBoxContainer/Row2/TicksWOProd").visible = true
		ticks_wo_prod.set_text(str(dict["no_produce"]))
	if dict["is_cons"]:
		get_node("ColorRect/VBoxContainer/Row2/TicksWOCons").visible = true
		ticks_wo_cons.set_text(str(dict["no_consume"]))

# Helper to assign labels to variables
func setup_nodes() -> void:
	title = get_node("ColorRect/VBoxContainer/SP_name")
	stock_in = get_node("ColorRect/VBoxContainer/Row1/StockIn/Value")
	stock_out = get_node("ColorRect/VBoxContainer/Row1/StockOut/Value")
	waste = get_node("ColorRect/VBoxContainer/Row1/Waste/Value")
	opening_stock = get_node("ColorRect/VBoxContainer/Row1/OpeningStock/Value")
	closing_stock = get_node("ColorRect/VBoxContainer/Row1/ClosingStock/Value")
	ticks_max = get_node("ColorRect/VBoxContainer/Row2/TicksMax/Value")
	ticks_min = get_node("ColorRect/VBoxContainer/Row2/TicksMin/Value")
	ticks_wo_prod = get_node("ColorRect/VBoxContainer/Row2/TicksWOProd/Value")
	ticks_wo_cons = get_node("ColorRect/VBoxContainer/Row2/TicksWOCons/Value")
	efficiency = get_node("ColorRect/VBoxContainer/Row2/Efficiency/Value")
