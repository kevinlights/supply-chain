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
	sp.downstream.adjust_pending_stock(desired_cargo)
	start_travel(destination.get_node("LeftLane"))

func pick_up():
	cargo = int(min(desired_cargo, destination.stock_level))
	destination.adjust_stock(-cargo)
	has_picked_up = true
	destination = destination.downstream
	start_travel(destination.get_node("RightLane"))

# Vehicle delivers its cargo to the given supply point. Any surplus to the
# supply point's capacity is thrown away
func deliver() -> void:
	destination.adjust_stock(cargo)
	destination.adjust_pending_stock(-desired_cargo) # Removing pending stock is adding negative stock
	# cargo does not get set to 0 since the vehicle is destroyed after
	queue_free()

func start_travel(lane: Node):
	if is_instance_valid(get_parent()):
		get_parent().remove_child(self)
	lane.add_child(self)

	var startPosition = lane.get_node("Origin").get_position()
	var endPosition = lane.get_node("Destination").get_position()
	var offset = Vector2(int(get_size().x / 2), get_size().y)
	set_position(startPosition)

	if is_instance_valid(travelTween):
		travelTween.remove_all()
		travelTween.queue_free()

	travelTween = Tween.new()
	add_child(travelTween)

	if startPosition.y > endPosition.y:
		set_rotation(0.0)
		startPosition += offset * Vector2(-1, 0.25)
		endPosition += offset * Vector2(-1, -1.25)
	else:
		set_rotation(PI)
		startPosition += offset * Vector2(1, -1.25)
		endPosition += offset * Vector2(1, 1.25)

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

func set_cargo_limit(new_limit: int = cargo_limit) -> void:
	cargo_limit = new_limit
	if cargo_limit <= 20:
		get_node("ColorRect").set_texture(preload("res://game_entities/transit_vehicle/car.png"))
	else:
		get_node("ColorRect").set_texture(preload("res://game_entities/transit_vehicle/truck_cab.png"))
		if cargo_limit <= 40:
			var thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
		else:
			var thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
			thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
