extends Node

# Supply points hold toilet paper and demand for toilet paper as well as the
# limits on stock and demand
# stock_level: Current amount of toilet paper
# max_stock_level: Maximum storage for toilet paper
# demand level: The amount of a toilet paper this supply point currently wants
# min_demand, max_demand: Constraints on values demand can take
class SupplyPoint2:
	var name : String
	var stock_level : int
	var max_stock_level : int
	var demand_level : int
	var min_demand : int
	var max_demand : int
	var tick_rate : float
	var counter : float
	var is_producing : bool
	var is_consuming : bool
	var upstream : SupplyPoint2
	var downstream : SupplyPoint2

	# Temporary
	var transit_list = []
	var demand_factor : float
	var transit_size : int

	# Can the supply point receive the amount of toilet paper?
	func request_stock(amount : int):
		var vehicle
		if transit_size == -1:
			vehicle = TransitVehicle2.new()
		else:
			vehicle = TransitVehicle2.new(transit_size)
		transit_list.push_back(vehicle)
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
	func _init(new_name := "New Supply Point", new_max_level := 100, new_level := 0, new_demand := 50,
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

	func set_downstream(value : SupplyPoint2):
		downstream = value
		value.upstream = self

	func _process(delta):
		for vehicle in transit_list:
			if is_instance_valid(vehicle):
				vehicle._process(delta)
		counter += delta
		if counter >= tick_rate:
			counter -= tick_rate
			if is_producing:
				produce_stock(demand_level)
			if is_consuming:
				consume_stock(demand_level)

			if stock_level < demand_level:
				request_stock(int(demand_level * demand_factor))


# Transit vehicles have a carrying capacity and current value of cargo
class TransitVehicle2:
	var cargo_limit : int
	var cargo : int
	var has_picked_up : bool
	var desired_cargo : int
	var destination : SupplyPoint2
	var speed : float
	var trip_duration : float

	# Vehicle collects the given amount of toilet paper, limited by the amount
	# available at the given supply point and its carrying capacity, and reduces
	# the supply point's stock
	func order(amount : int, sp : SupplyPoint2) -> void:
		destination = sp
		desired_cargo = int(min(amount, cargo_limit))

	func pick_up():
		cargo = int(min(desired_cargo, destination.stock_level))
		destination.stock_level -= cargo
		has_picked_up = true
		destination = destination.downstream

	# Vehicle delivers its cargo to the given supply point. Any surplus to the
	# supply point's capacity is thrown away
	func deliver() -> void:
		destination.stock_level = int(min(destination.max_stock_level, destination.stock_level + cargo))
		destination.transit_list.erase(self)
		# cargo does not get set to 0 since the vehicle is destroyed after
		if self.unreference() == false:
			pass

	# Constructor for TransitVehicle. Default vehicle starts empty with space
	# for 10 units
	func _init(new_limit := 10):
		cargo_limit = new_limit
		cargo = 0
		speed = 1.0
		trip_duration = 0.0
		has_picked_up = false

	func _process(delta):
		trip_duration += delta
		if trip_duration >= speed:
			if !has_picked_up:
				pick_up()
			else:
				deliver()
			trip_duration = 0

# Simulation requires a manufacturer, a warehouse, and a consumer which are
# defined as supply points
var sp_list := []

# Counter ensures a certain amount of time passes before checking to see if
# SupplyPoints will try to restock
var counter:= 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Instantiate the manufacturer, warehouse and home
	sp_list.push_back(SupplyPoint2.new("Manufacturer"))
	sp_list.back().set_is_producing(true)

	sp_list.push_back(SupplyPoint2.new("Warehouse"))
	sp_list.back().set_transit_size(100)

	sp_list.push_back(SupplyPoint2.new("Store"))
	sp_list.back().set_transit_size(100)

	sp_list.push_back(SupplyPoint2.new("Home", 100, 0, 40))
	sp_list.back().set_is_consuming(true)
	sp_list.back().set_demand_factor(0.5)

	setup_downstreams(sp_list)

func setup_downstreams(list : Array):
	for i in range(0, list.size()):
		if i == list.size() -1:
			break
		list[i].set_downstream(list[i + 1])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	for sp in sp_list:
		sp._process(delta)

	# Make sure at least 1 second has passed before we print
	counter += delta
	if counter > 1:
		counter -= 1
		# Print the current stock and demand for each SupplyPoint for debugging
		for sp in sp_list:
			print(sp.name, " stock: ", sp.stock_level, 
				", demand: ", sp.demand_level)
