extends VBoxContainer

# Transit vehicles have a carrying capacity and current value of cargo

var cargo_limit : int = 10
var cargo : int
var has_picked_up : bool
var desired_cargo : int
var destination : Node
var speed : float = 5.0
var trip_duration : float
var travelTween : Tween

# Vehicle collects the given amount of toilet paper, limited by the amount
# available at the given supply point and its carrying capacity, and reduces
# the supply point's stock
func order(amount : int, sp : Node) -> void:
	destination = sp
	desired_cargo = int(min(amount, cargo_limit))
	start_travel(destination.get_node("LeftLane"))

func pick_up():
	cargo = int(min(desired_cargo, destination.stock_level))
	destination.stock_level -= cargo
	has_picked_up = true
	destination = destination.downstream
	start_travel(destination.get_node("RightLane"))

# Vehicle delivers its cargo to the given supply point. Any surplus to the
# supply point's capacity is thrown away
func deliver() -> void:
	var quantity : int = int(min(destination.max_stock_level, destination.stock_level + cargo))
	destination.stock_level = quantity
	destination.add_pending_stock(quantity * -1) # Removing pending stock is adding negative stock
	# cargo does not get set to 0 since the vehicle is destroyed after
	queue_free()

func start_travel(lane: Node):
	var startPosition = lane.get_node("Origin").get_position() + Vector2(-15, 0)
	var endPosition = lane.get_node("Destination").get_position() + Vector2(-15, 0)
	set_position(startPosition)

	if is_instance_valid(get_parent()):
		get_parent().remove_child(self)
	lane.add_child(self)

	if is_instance_valid(travelTween):
		travelTween.remove_all()
		travelTween.queue_free()

	travelTween = Tween.new()
	add_child(travelTween)
	travelTween.interpolate_method(self, "set_position", startPosition, endPosition, speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	travelTween.start()

# Constructor for TransitVehicle. Default vehicle starts empty with space
# for 10 units
func _ready():
	cargo_limit = 10
	cargo = 0
	speed = 5.0
	trip_duration = 0.0
	has_picked_up = false

func _process(delta):
	if is_instance_valid(destination):
		trip_duration += delta
		if trip_duration >= speed:
			if !has_picked_up:
				pick_up()
			else:
				deliver()
			trip_duration = 0
	get_node("ColorRect/Cargo").set_text(str(cargo))

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
		thing = ColorRect.new()
		thing.set_custom_minimum_size(Vector2(30, 30))
		add_child(thing)
