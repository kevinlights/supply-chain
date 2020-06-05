extends Control

var report_section = preload("res://game_entities/report/SP_report.tscn")
var chart_section = preload("res://game_entities/report/Chart.tscn")
var sections := []

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	get_parent().set_process(false)
	connect("gui_input", self, "handle_input")

func _process(_delta : float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()

# Check to see if the player wants to close the report
func handle_input(event : InputEvent) -> void:
	if event is InputEventKey || event is InputEventMouseButton || event is InputEventJoypadButton:
		if event.is_action("ui_select") ||  event.is_action("ui_accept"):
			close()
			get_tree().set_input_as_handled()

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
	get_node("ChartsSheet/HBoxContainer/VBoxContainer/Title").set_bbcode("Historic Data")
	var old_charts = []
	var chart_page = get_node("ChartsSheet/HBoxContainer/VBoxContainer")
	for child in chart_page.get_children():
		if child is HBoxContainer:
			old_charts.append(child)
	for old_chart in old_charts:
		chart_page.remove_child(old_chart)

func setup_charts(supply_point):
	clear_charts()
	get_node("ChartsSheet/HBoxContainer/VBoxContainer/Title").set_bbcode("Historic Data for [u]" + supply_point.sp_name.capitalize() + "[/u]")
	setup_chart(supply_point.historic_stock, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)
	setup_chart(supply_point.historic_time, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)
	if !supply_point.is_producing:
		setup_chart(supply_point.historic_misc, supply_point.historic_datum_count, supply_point.is_producing, supply_point.is_consuming)

func setup_chart(dataset, offset, is_producing, is_consuming):
	var chart = chart_section.instance()
	chart.set_data(dataset.duplicate(), offset, is_producing, is_consuming)
	get_node("ChartsSheet/HBoxContainer/VBoxContainer").add_child(chart)
