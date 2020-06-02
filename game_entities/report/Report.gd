extends Control

var report_section = preload("res://game_entities/report/SP_report.tscn")
var chart_section = preload("res://game_entities/report/Chart.tscn")
var sections := []

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true

# Check to see if the player wants to close the report
func _process(_delta : float) -> void:
	if Input.is_action_just_released("ui_select") ||  Input.is_action_just_released("ui_accept") ||  Input.is_action_just_released("ui_cancel"):
		close()

# Unpause the game and remove the report
func close() -> void:
	get_tree().paused = false
	get_parent().set_process(true)
	queue_free()


# Build a given supply point's entry in the report
func make_section(supply_point) -> void:
	var section = report_section.instance()
	var report_area = get_node("FiguresSheet/HBoxContainer/VBoxContainer/")
	
	report_area.add_child(section)
	section.write_values(supply_point)
	sections.push_back(section)

func clear_charts():
	get_node("ChartsSheet/HBoxContainer/VBoxContainer/Title").set_text("Mouse over a supply point name to\nsee historic data")
	var old_charts = []
	var chart_page = get_node("ChartsSheet/HBoxContainer/VBoxContainer")
	for child in chart_page.get_children():
		if child is HBoxContainer:
			old_charts.append(child)
	for old_chart in old_charts:
		chart_page.remove_child(old_chart)

func setup_charts(supply_point):
	get_node("ChartsSheet/HBoxContainer/VBoxContainer/Title").set_text("Historic Data for " + supply_point.sp_name.capitalize())
	setup_chart(supply_point.historic_stock, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)
	setup_chart(supply_point.historic_time, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)
	if !supply_point.is_producing:
		setup_chart(supply_point.historic_misc, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)

func setup_chart(dataset, offset, is_producing, is_consuming):
	var chart = chart_section.instance()
	chart.set_data(dataset.duplicate(), offset, is_producing, is_consuming)
	get_node("ChartsSheet/HBoxContainer/VBoxContainer").add_child(chart)
