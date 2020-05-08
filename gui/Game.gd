extends HBoxContainer

var supply_point_scene = preload("res://game_entities/supply_point/SupplyPoint.tscn")

var menu_node : CenterContainer

# Simulation requires a manufacturer, a warehouse, and a consumer which are
# defined as supply points
var sp_list := []

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
	# Instantiate the manufacturer, warehouse and home
	sp_list.push_back(supply_point_scene.instance())
	sp_list.back().init("Manufacturer")

	sp_list.push_back(supply_point_scene.instance())
	sp_list.back().init("Warehouse")
	sp_list.back().set_transit_size(100)

	sp_list.push_back(supply_point_scene.instance())
	sp_list.back().init("Store")
	sp_list.back().set_transit_size(40)

	sp_list.push_back(supply_point_scene.instance())
	sp_list.back().init("Home", 100, 0, 40)
	# sp_list.back().set_demand_factor(0.5)

	setup_downstreams(sp_list)
	add_supply_points(sp_list)

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
