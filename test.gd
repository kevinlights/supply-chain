extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Supply points hold toilet paper and demand for toilet paper as well as the
# limits on stock and demand
# stock_level: Current amount of toilet paper
# max_stock_level: Maximum storage for toilet paper
# demand level: The amount of a toilet paper this supply point currently wants
# min_demand, max_demand: Constraints on values demand can take
class SupplyPoint:
	var stock_level : int
	var max_stock_level : int
	var demand_level : int
	var min_demand : int
	var max_demand : int
	
	# NOTE: I think *_stock functions are intended to do something with regards
	# generating trucks. Added comments so far as I can tell, but have doubts. 
	# Can the supply point send the given amount of toilet paper?
	func send_stock(amount : int) -> bool:
		# This function does not behave as the comment indicates
		return true

	# Can the supply point receive the amount of toilet paper?
	func receive_stock(amount : int) -> bool:
		# This function does not behave as the comment indicates
		return true
	
	# Add stock to stock_level, limited by the max
	func produce_stock(amount: int) -> void:
		stock_level = min(max_stock_level, stock_level + amount)
	
	# Draw from the existing stockpile (no toilet paper debt yet)
	func consume_stock(amount: int) -> void:
		stock_level = max(0, stock_level - amount)
		
	# Constructor for SupplyPoint. Default supply points start without stock and
	# demand 50 units of toilet paper. Default constraints are [0, 100]
	func _init(new_max_level := 100, new_level := 0, new_demand := 50, new_max_demand := 100, new_min_demand := 0):
		max_stock_level = new_max_level
		stock_level = new_level
		demand_level = new_demand
		min_demand = new_min_demand
		max_demand = new_max_demand

# Transit vehicles have a carrying capacity and current value of cargo
class TransitVehicle:
	var cargo_limit : int
	var cargo : int

	# Vehicle collects the given amount of toilet paper, limited by the ammount
	# available at the given supply point, and reduces the supply point's stock
	func collect(amount : int, sp : SupplyPoint) -> void:
		# The simulation already constrains by cargo limit, but it feels like
		# it should happen in collect
		cargo = min(amount, sp.stock_level)
		sp.stock_level -= cargo

	# Vehicle delivers its cargo to the given supply point. Any surplus to the
	# supply point's capacity is thrown away
	func deliver(sp : SupplyPoint) -> void:
		sp.stock_level = min(sp.max_stock_level, sp.stock_level + cargo)
		# cargo does not get set to 0 since the vehicle is destroyed after
		self.unreference()
	
	# Constructor for TransitVehicle. Default vehicle starts empty with space
	# for 10 units
	func _init(new_limit := 10, new_cargo := 0):
		cargo_limit = new_limit
		cargo = new_cargo

# Simulation requires a manufacturer, a warehouse, and a consumer whcih are
# defined as supply points
var manufacturer : SupplyPoint
var warehouse : SupplyPoint
var home : SupplyPoint

# Counter ensures a certain amount of time passes before checking to see if
# SupplyPoints will try to restock
var counter:= 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Instantiate the manufacturer, warehouse and home
	manufacturer = SupplyPoint.new()
	warehouse = SupplyPoint.new()
	home = SupplyPoint.new(100, 0, 40)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Make sure at least 1 second has passed before we run the simulation
	counter += delta
	if counter > 1:
		counter -= 1 # This no longer serves any purpose
		# Manufacturer and consumer produce/consume at their demand_level in
		# each period
		manufacturer.produce_stock(manufacturer.demand_level)
		home.consume_stock(home.demand_level)
		
		# If the consumer has less stock than what they want in the next period
		# they will go out to get more
		if home.stock_level < home.demand_level:
			var customer_vehicle = TransitVehicle.new(10) # Vehicle gets same capacity as default?
			# Vehicle checks to make sure it doesn't ask for more than its
			# capacity or more than it can store, then collects and delivers
			customer_vehicle.collect(min(customer_vehicle.cargo_limit, min(home.demand_level / 2, home.max_stock_level - home.stock_level)), warehouse)
			customer_vehicle.deliver(home)
		
		# If the warehouse has less stock than what they want in the next period
		# they wend a truck to get more
		if warehouse.stock_level < warehouse.demand_level:
			var delivery_truck = TransitVehicle.new(100) # Trucks are biggers than cars
			# Vehicle checks to make sure it doesn't ask for more than it can
			# carry or more than the warehouse can store, then collects/delivers
			delivery_truck.collect(min(delivery_truck.cargo_limit, min(warehouse.demand_level, warehouse.max_stock_level - warehouse.stock_level)), manufacturer)
			delivery_truck.deliver(warehouse)

	# Print the current stock and demand for each SupplyPoint for debugging
	print("Home stock: ", home.stock_level, ", Home demand: ", home.demand_level)
	print("Warehouse stock: ", warehouse.stock_level, ", Warehouse demand: ", warehouse.demand_level)
	print("Manufacturer stock: ", manufacturer.stock_level, ", Manufacturer demand: ", manufacturer.demand_level)
