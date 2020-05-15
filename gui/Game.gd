extends HBoxContainer

var supply_point_scene = preload("res://game_entities/supply_point/SupplyPoint.tscn")
var newspaper_scene = preload("res://game_entities/newspaper/Newspaper.tscn")

var menu_node : CenterContainer

# Simulation requires a manufacturer, a warehouse, and a consumer which are
# defined as supply points
var sp_list := []
var event_list := {}
var current_event_list := []
var supply_point_list := {
							"manufacturer": {},
							"warehouse": {"transit_size": 100},
							"store": {"transit_size": 40},
							"home": {"max_level": 100, "initial_level": 0, "initial_demand": 40}
						}
var event_frequency := 20.0
var next_event_time := 5.0
var report_frequency := 60.0 * 5.0
var next_report_time := report_frequency

# Bring up menu if player hits ESC
func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.scancode == KEY_ESCAPE:
		if is_instance_valid(menu_node):
			menu_node.show_menu()
		else:
			printerr("Unable to show menu")
			get_tree().quit()

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

	setup_downstreams(sp_list)
	add_supply_points(sp_list)
	load_events("json/events.json")

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

func load_events(path):
	event_list = read_json(path)

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

func add_event(event : Dictionary) -> void:
	print("Adding event ", event["headline"])
	event = event.duplicate()

	var newspaper = newspaper_scene.instance()
	newspaper.set_event(event)
	get_parent().add_child(newspaper)

	if event["time"] > 0:
		current_event_list.push_back(event)

	var target : Control
	if "supply_point" in event:
		for sp in sp_list:
			if sp.sp_name == event["supply_point"]:
				target = sp
	if !is_instance_valid(target):
		target = sp_list[randi() % sp_list.size()]
	event["target"] = target

	if "min_demand_offset" in event:
		event["target"].adjust_min_demand_offset(event["min_demand_offset"])

	if "max_demand_offset" in event:
		event["target"].adjust_max_demand_offset(event["max_demand_offset"])

	if "max_stock_level_offset" in event:
		event["target"].adjust_max_stock_level_offset(event["max_stock_level_offset"])

	if "consume_produce_frequency_offset" in event:
		event["target"].adjust_consume_produce_frequency_multiplier(event["consume_produce_frequency_offset"])

	if "adjust_stock_level" in event:
		event["target"].adjust_stock(event["adjust_stock_level"])
	#TODO: Add more event effects

func remove_event(event : Dictionary) -> void:
	print("Removing event ", event["headline"])

	if "min_demand_offset" in event:
		event["target"].adjust_min_demand_offset(-event["min_demand_offset"])

	if "max_demand_offset" in event:
		event["target"].adjust_max_demand_offset(-event["max_demand_offset"])

	if "max_stock_level_offset" in event:
		event["target"].adjust_max_stock_level_offset(-event["max_stock_level_offset"])

	if "consume_produce_frequency_offset" in event:
		event["target"].adjust_consume_produce_frequency_multiplier(-event["consume_produce_frequency_offset"])

	if "adjust_stock_level" in event:
		event["target"].adjust_stock(-event["adjust_stock_level"])
	#TODO: Add more event effects

	current_event_list.erase(event)

func _process(delta : float):
	next_event_time -= delta
	if next_event_time <= 0:
		next_event_time += event_frequency
		add_event(get_random_event())

	var expired_events := []
	for event in current_event_list:
		event["time"] -= delta
		if event["time"] <= 0:
			expired_events.push_back(event)
	for event in expired_events:
		remove_event(event)
	
	next_report_time -= delta
	if next_report_time <= 0:
		next_report_time += report_frequency
		# IOU one report
