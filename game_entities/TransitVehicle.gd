extends VBoxContainer

# Transit vehicles have a carrying capacity and current value of cargo
class_name TransitVehicle

var cargo_limit : int
var cargo : int
var has_picked_up : bool
var desired_cargo : int
var destination : SupplyPoint
var speed : float
var trip_duration : float

# Vehicle collects the given amount of toilet paper, limited by the amount
# available at the given supply point and its carrying capacity, and reduces
# the supply point's stock
func order(amount : int, sp : SupplyPoint) -> void:
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
	queue_free()

# Constructor for TransitVehicle. Default vehicle starts empty with space
# for 10 units
func _ready():
	cargo_limit = 10
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

func set_cargo_limit(new_limit: int) -> void:
	cargo_limit = new_limit
	if cargo_limit < 20:
		pass
	elif cargo_limit < 40:
		var thing = ColorRect.new()
		thing.set_custom_minimum_size(Vector2(30, 30))
		add_child(thing)
	else:
		var thing = ColorRect.new()
		thing.set_custom_minimum_size(Vector2(30, 30))
		add_child(thing)
		add_child(thing)
