extends HBoxContainer

var supply_point_scene = preload("res://game_entities/supply_point/SupplyPoint.tscn")
var newspaper_scene = preload("res://game_entities/newspaper/Newspaper.tscn")
var report_scene = preload("res://game_entities/report/Report.tscn")
var event_editor_scene = preload("res://gui/EventEditor.tscn")
var events_file = "res://json/events.json"
var papers_file = "res://json/newspapers.json"

var menu_node : CenterContainer

# Simulation requires a manufacturer, a warehouse, and a consumer which are
# defined as supply points
var start_stocked = false
var auto_stop_production = false
var prevent_transit_waste = false
var sp_list := []
var event_list := {}
var paper_list := {}
var current_event_list := []
var supply_point_list := {
							"manufacturer": {"max_level": 100, "initial_demand": 85},
							"warehouse": {"transit_size": 100, "initial_demand": 50},
							"store": {"transit_size": 40, "initial_demand": 50},
							"home": {"max_level": 50, "initial_level": 0, "initial_demand": 60}
						}

#TODO: Add more event effects
var event_prop_list := {
					"internal_name":
						{
							"required": true,
							"type": TYPE_STRING,
							"default": ""
						},
					"supply_point":
						{
							"required": true,
							"type": TYPE_STRING,
							"default": "generic",
							"validate_func" : "check_sp_name"
							#TODO: Add support for a "values" array that causes a dropdown to be used
						},
					"time":
						{
							"required": true,
							"type": TYPE_REAL,
							"default": 0
						},
					"headline":
						{
							"type": TYPE_STRING,
							"default": "A funny thing happened today"
						},
					"subheading":
						{
							"type": TYPE_STRING,
							"default": "No, really. It was hilarious."
						},
					"image":
						{
							"type": TYPE_STRING,
							"default": "test.png",
							"prefix": "res://game_entities/newspaper/images/",
							"validate_func" : "check_image"
						},
					"min_demand_offset":
						{
							"func": "adjust_min_demand_offset",
							"type": TYPE_INT,
							"default": 1
						},
					"max_demand_offset":
						{
							"func": "adjust_max_demand_offset",
							"type": TYPE_INT,
							"default": -1
						},
					"max_stock_level_offset":
						{
							"func": "adjust_max_stock_level_offset",
							"type": TYPE_INT,
							"default": -10
						},
					"consume_produce_frequency_multiplier":
						{
							"func": "adjust_consume_produce_frequency_multiplier",
							"type": TYPE_REAL,
							"default": 0.5
						},
					"adjust_stock_level":
						{
							"func": "adjust_stock",
							"type": TYPE_INT,
							"default": -5
						},
					"consume_produce_pause":
						{
							"func": "pause_consume_produce",
							"type": TYPE_BOOL,
							"default": true
						},
					"skip_producing_supply_points":
						{
							"type": TYPE_BOOL,
							"default": true
						},
					"skip_consuming_supply_points":
						{
							"type": TYPE_BOOL,
							"default": true
						},
					"ignore_supply_point":
						{
							"type": TYPE_STRING,
							"default": "generic",
							"validate_func" : "check_sp_name"
						},
					"transit_vehicle_pause":
						{
							"func": "pause_transit_vehicles",
							"type": TYPE_BOOL,
							"default": true
						},
					"transit_vehicle_crash":
						{
							"func": "set_next_vehicle_crash",
							"type": TYPE_BOOL,
							"default": true
						},
					"transit_vehicle_speed_multiplier_offset":
						{
							"func": "adjust_transit_speed_multiplier",
							"type": TYPE_REAL,
							"default": 0.5
						},
					}

var event_frequency := 60.0 * 1.0
var next_event_time := event_frequency + 30.0 #Plus 30 sec to move us off the minute boundary and avoid clashes with reports
var report_frequency := 60.0 * 4.0
var next_report_time := report_frequency / 2
var skip_events := false
var skip_reports := false


# Bring up menu if player hits ESC
func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if event.scancode == KEY_ESCAPE:
			if is_instance_valid(menu_node):
				menu_node.show_menu()
				get_tree().set_input_as_handled()
			else:
				printerr("Unable to show menu")
				get_tree().set_input_as_handled()
				get_tree().quit()
		elif event.scancode == KEY_E:
			get_parent().add_child(event_editor_scene.instance())
		elif event.scancode == KEY_R:
			if Input.is_key_pressed(KEY_SHIFT):
				for sp in sp_list:
					sp.make_report()
			generate_report()

# Called when the node enters the scene tree for the first time.
func _ready():
	for sp in supply_point_list:
		sp_list.push_back(supply_point_scene.instance())
		sp_list.back().init(sp)
		if "transit_size" in supply_point_list[sp]:
			sp_list.back().set_transit_size(supply_point_list[sp]["transit_size"])
		if "max_level" in supply_point_list[sp]:
			sp_list.back().set_max_stock_level(supply_point_list[sp]["max_level"])
		if "initial_level" in supply_point_list[sp]:
			sp_list.back().set_stock_level(supply_point_list[sp]["initial_level"])
		if "initial_demand" in supply_point_list[sp]:
			sp_list.back().update_demand(supply_point_list[sp]["initial_demand"])
		if start_stocked:
			sp_list.back().adjust_stock(sp_list.back().max_stock_level / 2)

	setup_downstreams(sp_list)
	add_supply_points(sp_list)
	load_events(events_file)
	load_papers(papers_file)
	set_auto_stop_production(auto_stop_production)
	set_prevent_transit_waste(prevent_transit_waste)

# Iterates over each supply point and connects it to the destination for its cargo and sets first entry as producer and final entry as consumer
func setup_downstreams(list : Array) -> void:
	var last : int = list.size() - 1

	for i in range(0, list.size()):
		if i == last:
			break
		list[i].set_downstream(list[i + 1])
	list[0].set_is_producing(true)
	list[last].set_is_consuming(true)

# Adds supply points to game
func add_supply_points(list: Array) -> void:
	for sp in list:
		add_child(sp)

func set_auto_stop_production(value : bool) -> void:
	auto_stop_production = value
	for sp in sp_list:
		if sp.is_producing:
			sp.set_auto_stop_production(auto_stop_production)

func set_prevent_transit_waste(value : bool) -> void:
	prevent_transit_waste = value
	for sp in sp_list:
		sp.set_prevent_transit_waste(prevent_transit_waste)

# A helper function to read in json files for the event list
func read_json(path):
	var file = File.new()
	if not file.file_exists(path):
		printerr("ERROR: Unable to open resource ", path)
	file.open(path, file.READ)
	var text = file.get_as_text()
	file.close()
	var parse = JSON.parse(text)
	if parse.error == OK:
		return parse.result
	else:
		printerr("Error reading ", path, " at line " + str(parse.error_line) + ": " + parse.error_string)
		return null

func write_json(path, data):
	var file = File.new()
	if file.open(path, File.WRITE) != OK:
		printerr("Unable to open ", path, " for writing")
		return false
	file.store_string(to_json(data))
	file.close()

# Populates event list
func load_events(path):
	event_list = read_json(path)

func load_papers(path):
	paper_list = read_json(path)

# Draws first event from a shuffled list of events in event_list
func get_random_event():
	var candidates = []
	for event_type in event_list:
		if event_type in supply_point_list || event_type == "generic":
			for item in event_list[event_type]:
				candidates.push_back(item)
	candidates.shuffle()
	if candidates.size() > 0:
		return candidates[0]
	else:
		return {
					"time": 0,
					"headline": "Business as usual",
					"image": "test.png",
				}

# Produces a given event's effects in the game
func add_event(event : Dictionary) -> void:
	if "internal_name" in event:
		print("Adding event ", event["internal_name"])
	else:
		print("Adding unnamed event ", event)
	event = event.duplicate()
	
	if event["time"] > 0:
		current_event_list.push_back(event)

	var target : Control
	if "supply_point" in event:
		for sp in sp_list:
			if sp.sp_name == event["supply_point"]:
				target = sp
	if !is_instance_valid(target):
		var target_list = sp_list.duplicate()
		target_list.shuffle()
		var target_index = 0
		var found_target = false
		while !found_target:
			target = target_list[target_index]
			found_target = true
			if "skip_producing_supply_points" in event && event["skip_producing_supply_points"] == true:
				if target.is_producing:
					found_target = false
			if "skip_consuming_supply_points" in event && event["skip_consuming_supply_points"] == true:
				if target.is_consuming:
					found_target = false
			if "ignore_supply_point" in event:
				if event["ignore_supply_point"] == target.sp_name:
					found_target = false
			target_index += 1
	print("Using target ", target.sp_name)
	event["target"] = target

	for effect in event_prop_list:
		if effect in event:
			if "func" in event_prop_list[effect]:
				event["target"].call(event_prop_list[effect]["func"], event[effect])

	if "headline" in event:
		event["headline"] = event["headline"].replace("{supply_point}", target.sp_name)
		if "subheading" in event:
			event["subheading"] = event["subheading"].replace("{supply_point}", target.sp_name)

		var newspaper = newspaper_scene.instance()
		newspaper.set_event(event)
		newspaper.set_title(paper_list["titles"][randi() % paper_list["titles"].size()])
		newspaper.set_date(paper_list["dates"][randi() % paper_list["dates"].size()])
		get_parent().add_child(newspaper)


# Removes the effects of the given event
func remove_event(event : Dictionary) -> void:
	if "internal_name" in event:
		print("Removing event ", event["internal_name"])
	else:
		print("Removing unnamed event ", event)

	for effect in event_prop_list:
		if effect in event:
			if "func" in event_prop_list[effect]:
				if event_prop_list[effect]["type"] in [TYPE_INT, TYPE_REAL]:
					event["target"].call(event_prop_list[effect]["func"], -event[effect])
				if event_prop_list[effect]["type"] in [TYPE_BOOL]:
					event["target"].call(event_prop_list[effect]["func"], !event[effect])

	current_event_list.erase(event)

# Helper to generate a report. Currently prints values to output.
func generate_report() -> void:
	var report = report_scene.instance()
	for sp in sp_list:
		report.make_section(sp)
		#sp.make_report() #We do this in _process now so that this function is non-destructive to the underlying data
	get_parent().add_child(report)

# Count down time to next event and next report and trigger them if enough time has passed
func _process(delta : float):
	var displaying_event = false
	next_event_time -= delta
	if next_event_time <= 0:
		next_event_time += event_frequency
		if !skip_events:
			add_event(get_random_event())
			displaying_event = true

	var expired_events := []
	for event in current_event_list:
		event["time"] -= delta
		if event["time"] <= 0:
			expired_events.push_back(event)
	for event in expired_events:
		remove_event(event)
	
	next_report_time -= delta
	if next_report_time <= 0 && !displaying_event:
		next_report_time += report_frequency
		generate_report()
		#Process historic data outside of showing reports so that report generation is non-destructive
		for sp in sp_list:
			sp.make_report()
