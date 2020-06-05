extends VBoxContainer

# Transit vehicles have a carrying capacity and current value of cargo
enum VehicleType {CAR, TRUCK, ARTICULATED}
var cargo_limit : int = 10
var cargo : int
var has_picked_up : bool
var desired_cargo : int
var destination : Node
var base_speed : float = 5.0
var speed : float = base_speed
var trip_duration : float
var travel_tween : Tween
var crash : bool = false
var lifetime : float = 0.0
var cargo_threshold_car = 20
var cargo_threshold_truck = 40
var type = VehicleType.CAR

var articulated_crash_scene = preload("res://game_entities/transit_vehicle/articulated_crash.tscn")
var truck_crash_scene = preload("res://game_entities/transit_vehicle/truck_crash.tscn")
var car_crash_scene = preload("res://game_entities/transit_vehicle/car_crash.tscn")

# Vehicle collects the given amount of toilet paper, limited by the amount
# available at the given supply point and its carrying capacity, and reduces
# the supply point's stock
func order(amount : int, sp : Node) -> void:
	destination = sp
	desired_cargo = int(min(amount, cargo_limit))
	sp.downstream.adjust_pending_stock(desired_cargo)
	start_travel(destination.get_node("LeftLane"))

# Vehicle moves cargo from supply point to cargo, sets destination to home and switches lanes
func pick_up():
	cargo = int(min(desired_cargo, destination.stock_level))
	destination.adjust_stock(-cargo)
	has_picked_up = true
	destination = destination.downstream
	start_travel(destination.get_node("RightLane"), crash)

# Vehicle delivers its cargo to the given supply point. Any surplus to the
# supply point's capacity is thrown away
func deliver() -> void:
	destination.adjust_stock(cargo)
	destination.adjust_pending_stock(-desired_cargo) # Removing pending stock is adding negative stock
	# cargo does not get set to 0 since the vehicle is destroyed after
	destination.adjust_transit_time(lifetime)
	queue_free()

# Move to destination for the given lane (animation)
func start_travel(lane: Node, will_crash: bool = false):
	# Add vehicle to lane
	if get_parent() != lane:
		if is_instance_valid(get_parent()):
			get_parent().remove_child(self)
		lane.add_child(self)

	var startPosition : Vector2 = lane.get_node("Origin").get_position()
	var endPosition : Vector2 = lane.get_node("Destination").get_position()
	var offset : Vector2 = Vector2(int(get_size().x / 2), get_size().y)
	set_position(startPosition)

	if is_instance_valid(travel_tween):
		travel_tween.remove_all()
		travel_tween.queue_free()

	travel_tween = Tween.new()
	add_child(travel_tween)

	# Sets direction the car is facing
	if startPosition.y > endPosition.y:
		set_rotation(0.0)
		startPosition += offset * Vector2(-1, 0.0)
		endPosition += offset * Vector2(-1, -1.0)
	else:
		set_rotation(PI)
		startPosition += offset * Vector2(1, -1.0)
		endPosition += offset * Vector2(1, 1.0)

	if will_crash:
		endPosition = ((endPosition - startPosition) / 2) + startPosition
		travel_tween.connect("tween_completed", self, "handle_crash")

	# Move from start to end
	if speed <= 0:
		printerr("Uh oh! Speed is negative (", speed, "). Resetting to default.")
		speed = base_speed
	travel_tween.interpolate_method(self, "set_position", startPosition, endPosition, speed / 2.0 if will_crash else speed, Tween.TRANS_LINEAR, Tween.EASE_IN if will_crash else Tween.EASE_IN_OUT)
	travel_tween.start()

func set_crash(val := true) -> void:
	crash = val
	
func handle_crash(_obj, _key) -> void:
	destination.adjust_pending_stock(-desired_cargo)
	destination.adjust_waste(desired_cargo)

	var spillage_scene
	var crash_event = {"headline": "Roll toll on toll road", "time": 0, "target": destination}
	if type == VehicleType.CAR:
		crash_event["image"] = "crash_car.png"
		crash_event["headline"] = "Car rolled close to home"
		crash_event["subheading"] = "None injured, egos bruised"
		spillage_scene = car_crash_scene
	elif type == VehicleType.TRUCK:
		crash_event["image"] = "crash_truck.png"
		crash_event["subheading"] = "Wiped out stock doesn't reach shops"
		spillage_scene = truck_crash_scene
	else: #type == VehicleType.ARTICULATED
		crash_event["image"] = "crash_articulated.png"
		crash_event["headline"] = "Newly made stock flushed in truck accident"
		crash_event["subheading"] = "A modern tragedy"
		spillage_scene = articulated_crash_scene
	#TODO: Move crash headline/subheadings out to file. Use a random pool like newspaper names?
	destination.get_parent().add_event(crash_event)
	destination.adjust_transit_time(lifetime)

	#Add the image to both lanes. Since they're both clipped and should align, it'll look like one image spanning both lanes
	# (a larger scale refactor could migrate everything to sprites and take advantage of z-index, or create separate "overlays" for vehicles, crash detritus, etc.)
	var crash_location = Vector2(0, get_position().y)
	var spillage = spillage_scene.instance()
	destination.get_node("RightLane/CrashAnchor").add_child(spillage)
	spillage.set_position(crash_location)
	spillage = spillage_scene.instance()
	destination.upstream.get_node("LeftLane/CrashAnchor").add_child(spillage)
	spillage.set_position(crash_location)

	queue_free()

# Constructor for TransitVehicle. Default vehicle starts empty with space for 10 units
func _ready():
	cargo_limit = 10
	cargo = 0
	trip_duration = 0.0
	has_picked_up = false

# Check to see if the vehicle has arrived and pick up or deliver
func _process(delta):
	lifetime += delta
	if is_instance_valid(destination):
		trip_duration += delta
		if trip_duration >= speed:
			if !has_picked_up:
				pick_up()
			else:
				deliver()
			trip_duration = 0
	get_node("ColorRect/Cargo").set_text(str(cargo)) # Helper to display cargo when debugging. Not always visible

func set_speed_multiplier(value : float):
	var progress = 0
	if is_instance_valid(travel_tween):
		progress = travel_tween.tell()
		if progress != 0:
			progress = speed / progress

	#Speed is actually travel duration, so increasing velocity should mean smaller speed
	speed = base_speed / value
	if speed <= 0:
		print("Oh noes", print(speed <= 0))

	if is_instance_valid(travel_tween):
		start_travel(get_parent(), crash)
		travel_tween.seek(speed / progress)
		trip_duration = speed / progress

# Sets cargo limits and corresponding vehicle displays (Cars for < 20, Trucks for 21-40, articulated trucks for more)
func set_cargo_limit(new_limit: int = cargo_limit) -> void:
	cargo_limit = new_limit
	if cargo_limit <= cargo_threshold_car:
		get_node("ColorRect").set_texture(preload("res://game_entities/transit_vehicle/car.png"))
		type = VehicleType.CAR
	else:
		get_node("ColorRect").set_texture(preload("res://game_entities/transit_vehicle/truck_cab.png"))
		if cargo_limit <= cargo_threshold_truck:
			var thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
			type = VehicleType.TRUCK
		else:
			var thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
			thing = TextureRect.new()
			thing.set_texture(preload("res://game_entities/transit_vehicle/truck_trailer.png"))
			add_child(thing)
			type = VehicleType.ARTICULATED
