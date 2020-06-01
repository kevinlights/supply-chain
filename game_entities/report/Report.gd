extends Control

var report_section = preload("res://game_entities/report/SP_report.tscn")
var sections := []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Check to see if the player wants to close the report
func _process(_delta):
	if Input.is_action_just_released("ui_select") ||  Input.is_action_just_released("ui_accept") ||  Input.is_action_just_released("ui_cancel"):
		queue_free()

# Build a given supply point's entry in the report
func make_section(dict) -> void:
	var section = report_section.instance()
	var report_area = get_node("RightSheet/VBoxContainer/VBoxContainer/")
	
	report_area.add_child(section)
	section.write_values(dict)
	sections.push_back(section)
