extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

class SupplyPoint:
	var stock_level : int
	var max_stock_level : int
	var demand_level : int
	var min_demand : int
	var max_demand : int

	func send_stock(amount : int) -> bool:
		return true

	func receive_stock(amount : int) -> bool:
		return true
	
	func produce_stock(amount: int) -> void:
		stock_level = min(max_stock_level, stock_level + amount)
		
	func consume_stock(amount: int) -> void:
		stock_level = max(0, stock_level - amount)

	func _init(new_max_level := 100, new_level := 0, new_demand := 50, new_max_demand := 100, new_min_demand := 0):
		max_stock_level = new_max_level
		stock_level = new_level
		demand_level = new_demand
		min_demand = new_min_demand
		max_demand = new_max_demand

class TransitVehicle:
	var cargo_limit : int
	var cargo : int

	func collect(amount : int, sp : SupplyPoint) -> void:
		cargo = min(amount, sp.stock_level)
		sp.stock_level -= cargo

	func deliver(sp : SupplyPoint) -> void:
		sp.stock_level = min(sp.max_stock_level, sp.stock_level + cargo)
		self.unreference()

	func _init(new_limit := 10, new_cargo := 0):
		cargo_limit = new_limit
		cargo = new_cargo

var manufacturer : SupplyPoint
var warehouse : SupplyPoint
var home : SupplyPoint
var counter:= 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	manufacturer = SupplyPoint.new()
	warehouse = SupplyPoint.new()
	home = SupplyPoint.new(100, 0, 40)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	counter += delta
	if counter > 1:
		counter -= 1
		manufacturer.produce_stock(manufacturer.demand_level)
		home.consume_stock(home.demand_level)
		
		if home.stock_level < home.demand_level:
			var customer_vehicle = TransitVehicle.new(10)
			customer_vehicle.collect(min(customer_vehicle.cargo_limit, min(home.demand_level / 2, home.max_stock_level - home.stock_level)), warehouse)
			customer_vehicle.deliver(home)
		
		if warehouse.stock_level < warehouse.demand_level:
			var delivery_truck = TransitVehicle.new(100)
			delivery_truck.collect(min(delivery_truck.cargo_limit, min(warehouse.demand_level, warehouse.max_stock_level - warehouse.stock_level)), manufacturer)
			delivery_truck.deliver(warehouse)

	print("Home stock: ", home.stock_level, ", Home demand: ", home.demand_level)
	print("Warehouse stock: ", warehouse.stock_level, ", Warehouse demand: ", warehouse.demand_level)
	print("Manufacturer stock: ", manufacturer.stock_level, ", Manufacturer demand: ", manufacturer.demand_level)
