extends HBoxContainer

var transit_vehicle_scene = preload("res://game_entities/TransitVehicle.tscn")

var sp_name : String
var stock_level : int
var max_stock_level : int
var demand_level : int
var min_demand : int
var max_demand : int
var tick_rate : float
var counter : float
var is_producing : bool
var is_consuming : bool
var upstream : Node
var downstream : Node

# Temporary
var demand_factor : float
var transit_size : int

# Can the supply point receive the amount of toilet paper?
func request_stock(amount : int):
	var vehicle = transit_vehicle_scene.instance()

	if transit_size != -1:
		vehicle.set_cargo_limit(transit_size)
	# Vehicle checks for how much is needed then collects and delivers
	vehicle.order(min(amount, max_stock_level - stock_level), upstream)

# Add stock to stock_level, limited by the max
func produce_stock(amount: int) -> void:
	stock_level = int(min(max_stock_level, stock_level + amount))

# Draw from the existing stockpile (no toilet paper debt yet)
func consume_stock(amount: int) -> void:
	stock_level = int(max(0, stock_level - amount))

# Constructor for SupplyPoint. Default supply points start without stock and
# demand 50 units of toilet paper. Default constraints are [0, 100]
func init(new_name := "New Supply Point", new_max_level := 100, new_level := 0, new_demand := 50,
	new_max_demand := 100, new_min_demand := 0):
	max_stock_level = new_max_level
	stock_level = new_level
	demand_level = new_demand
	min_demand = new_min_demand
	max_demand = new_max_demand
	tick_rate = 1.0
	counter = 0.0
	is_producing = false
	is_consuming = false
	demand_factor = 1.0
	transit_size = -1
	name = new_name
	get_node("SupplyPointVisual/VBoxContainer/Title").set_text(name)

func set_demand_factor(value : float) -> void:
	demand_factor = value

func set_transit_size(value : int) -> void:
	transit_size = value

func set_tick_rate(value : float) -> void:
	tick_rate = value

func set_is_consuming(value : bool) -> void:
	is_consuming = value

func set_is_producing(value : bool) -> void:
	is_producing = value

func set_downstream(value : Node):
	downstream = value
	value.upstream = self

func _process(delta):
	counter += delta
	if counter >= tick_rate:
		counter -= tick_rate
		if is_producing:
			produce_stock(demand_level)
		if is_consuming:
			consume_stock(demand_level)

		if stock_level < demand_level:
			request_stock(int(demand_level * demand_factor))
