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

	func sendStock(amount : int) -> bool:
		return true

	func receiveStock(amount : int) -> bool:
		return true

	func _init(new_max_level := 100, new_level := 0, new_demand := 50, new_max_demand := 100, new_min_demand := 0):
		max_stock_level = new_max_level
		stock_level = new_level
		demand_level = new_demand
		min_demand = new_min_demand
		max_demand = new_max_demand

class TransitVehicle:
	var cargo_limit : int
	var cargo : int

	func collect(amount : int, new_sp : SupplyPoint) -> void:
		pass

	func deliver(amount : int, new_sp : SupplyPoint) -> void:
		pass

	func _init(new_limit := 10, new_cargo := 5):
		cargo_limit = new_limit
		cargo = new_cargo


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
