extends HBoxContainer

var transit_vehicle_scene = preload("res://game_entities/transit_vehicle/TransitVehicle.tscn")

var visual_indicators = {
	"home": preload("res://game_entities/supply_point/visual_indicators/HomeAnchors.tscn"),
	"store": preload("res://game_entities/supply_point/visual_indicators/StoreAnchors.tscn"),
	"warehouse": preload("res://game_entities/supply_point/visual_indicators/WarehouseAnchors.tscn"),
	"manufacturer": preload("res://game_entities/supply_point/visual_indicators/ManufacturerAnchors.tscn"),
	"default": preload("res://game_entities/supply_point/visual_indicators/HomeAnchors.tscn")
}

var sp_name : String
var stock_level : int
var max_stock_level : int
var demand_level : int
var min_demand_offset : int = 0
var max_demand_offset : int = 0
var max_stock_level_offset : int = 0
var min_demand_increase_rate : int = 1
var max_demand_increase_rate : int = -1
var stock_comfort_band_min : int
var stock_comfort_band_max : int
var min_demand : int
var max_demand : int
var pending_stock: int
var enroute_stock: int
var tick_rate : float
var counter : float
var consume_counter: float
var is_producing : bool
var is_consuming : bool
var upstream : Node
var downstream : Node
var demand_slider : HSlider
var should_update_indicators : bool
var stock_indicator_anchor : TextureRect
var stock_indicator_value : float
var pickup_particles : Particles2D
var consumption_rate : int
var production_rate : int
var consume_produce_frequency : float
var consume_produce_frequency_multiplier : float = 1.0
var consume_produce_paused : bool = false
var transit_speed_multiplier : float = 1.0
var transit_vehicles_paused : bool = false
var next_vehicle_crash : bool = false
var auto_stop_production : bool = false
var prevent_transit_waste : bool = false

var demand_marker_min : TextureRect
var demand_marker_max : TextureRect

var transit_size : int

# Quarterly performance indicators
var stock_in : int = 0
var stock_out : int = 0
var waste : int = 0
var opening_stock : int = 0
var closing_stock : int = 0
var ticks_at_max : int = 0
var ticks_at_min : int = 0
var ticks_no_produce : int = 0
var ticks_no_consume : int = 0
var transit_time : float = 0

# Lifetime performance indicators
var historic_stock = {
			"stock_in": [],
			"stock_out": [],
			"waste": [],
			"opening_stock": [],
			"closing_stock": [],
		}
var historic_time = {
			"time_full": [],
			"time_empty": [],
			"unable_to_produce": [],
			"unable_to_consume": [],
	}
var historic_misc = {
			"transit_efficiency": [],
		}
var max_datum_count = 20 #Note, this corresponds to max_datum_count in Chart.gd, which establishes horozontal scale of charts based on the assumption of a fixed maximum number of values
var historic_datum_count = -1 #Start at -1 so that we can be at 0 for the first period

# Can the supply point receive the amount of toilet paper?
func request_stock(amount : int):
	if !is_instance_valid(upstream):
		print("Something terrible has happened!")
		return

	if transit_vehicles_paused:
		return

	if upstream.stock_level - (pending_stock - enroute_stock) <= 0:
	#if upstream.stock_level - pending_stock <= 0:
		return

	var vehicle = transit_vehicle_scene.instance()
	
	if next_vehicle_crash:
		vehicle.set_crash()
		set_next_vehicle_crash(false)

	if transit_size != -1:
		vehicle.set_cargo_limit(transit_size)
	else:
		vehicle.set_cargo_limit()
	vehicle.set_speed_multiplier(transit_speed_multiplier)
	# Vehicle checks for how much is needed then collects and delivers
	if prevent_transit_waste:
		vehicle.order(int(min(vehicle.cargo_limit, max_stock_level - stock_level)), upstream)
	else:
		vehicle.order(vehicle.cargo_limit, upstream)

# Add stock to stock_level, limited by the max
func produce_stock(amount: int) -> void:
	if (stock_level < max_stock_level + max_stock_level_offset):
		if auto_stop_production:
			#Only produce the amount needed to fill storage
			amount = int(min(amount, max_stock_level + max_stock_level_offset - stock_level))
	else:
		ticks_no_produce += 1
		if auto_stop_production:
			#Produce nothing so that there will be no wastage
			amount = 0

	if (stock_level < max_stock_level + max_stock_level_offset):
		stock_indicator_anchor.set_animation_paused(false)
	else:
		if auto_stop_production:
			stock_indicator_anchor.set_animation_paused(true)

	adjust_stock(amount)

# Draw from the existing stockpile (no toilet paper debt yet)
func consume_stock(amount: int) -> void:
	var adj_amount : int = int(min(amount, stock_level))
	adjust_stock(-adj_amount)
	if (adj_amount != amount):
		ticks_no_consume += 1
		stock_indicator_anchor.do_cant_consume()

	if (stock_level > 0):
		stock_indicator_anchor.set_animation_paused(false)
	else:
		stock_indicator_anchor.set_animation_paused(true)

func play_pickup_animation(amount : int) -> float:
	amount = int(amount / stock_indicator_anchor.get_particle_value())
	pickup_particles.set_amount(max(1, amount))
	pickup_particles.get_process_material().set_trail_divisor(amount)
	pickup_particles.set_emitting(true)
	return pickup_particles.get_lifetime()

# Constructor for SupplyPoint. Default supply points start without stock and
# demand 50 units of toilet paper. Default constraints are [0, 100]
func init(new_name := "New Supply Point", new_max_level := 100, new_level := 0, new_demand := 50,
	new_max_demand := 100, new_min_demand := 0):
	max_stock_level = new_max_level
	update_stock_comfort_band()
	stock_level = new_level
	demand_level = new_demand
	min_demand = new_min_demand
	max_demand = new_max_demand
	pending_stock = 0
	enroute_stock = 0
	tick_rate = 1.0
	consume_produce_frequency = 0.50
	production_rate = 2
	consumption_rate = 1
	counter = 0.0
	consume_counter = 0.0
	is_producing = false
	is_consuming = false
	transit_size = 10
	sp_name = new_name
	stock_indicator_value = 1.0
	should_update_indicators = false
	get_node("SupplyPointVisual/VBoxContainer/Title").set_text(sp_name.to_upper())
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	if is_producing:
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandLabel").set_text("Production Rate")
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(max(1, demand_level * 2)) + "%")
	else:
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level) + "%")

	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand").set_value(demand_level)

	configure_stock_indicators()

func set_auto_stop_production(value : bool) -> void:
	auto_stop_production = value

func set_prevent_transit_waste(value : bool) -> void:
	prevent_transit_waste = value

# Set max stock level to a given value
func set_max_stock_level(value : int) -> void:
	max_stock_level = value
	update_stock_indicator_value()
	update_stock_comfort_band()

func update_stock_comfort_band():
	stock_comfort_band_min = int((max_stock_level + max_stock_level_offset) * 0.25)
	stock_comfort_band_max = int((max_stock_level + max_stock_level_offset) * 0.75)

# Set stock level to a given value
func set_stock_level(value : int) -> void:
	stock_level = value
	update_stock_indicators()

# Adjust minimum demand by a given value. Keeps track of temporary effects from events
func adjust_min_demand_offset(value : int, check_max = true) -> void:
	min_demand_offset += value
	if min_demand + min_demand_offset < 0:
		min_demand_offset = -min_demand

	#Slider grabber is positioned 7px from the edge of the slider widget. Theme customisation doesn't really allow control of this, so let's compensate
	demand_marker_min.set_position(Vector2((demand_marker_min.get_parent().get_parent().get_size().x - 14) / 100.0 * (min_demand + min_demand_offset) + 1, 0))

	if check_max:
		if min_demand + min_demand_offset > max_demand + max_demand_offset:
			adjust_max_demand_offset((min_demand + min_demand_offset) - (max_demand + max_demand_offset), false)

	#TODO: For optimisation, should this only be called if demand level is below combined min?
	update_demand(demand_level)

# Adjust maximum demand by a given value. Keeps track of temporary effects from events
func adjust_max_demand_offset(value : int, check_min = true) -> void:
	max_demand_offset += value
	if max_demand + max_demand_offset > 100:
		max_demand_offset = 100 - max_demand

	#Slider grabber is positioned 7px from the edge of the slider widget. Theme customisation doesn't really allow control of this, so let's compensate
	demand_marker_max.set_position(Vector2((demand_marker_max.get_parent().get_parent().get_size().x - 14) / 100.0 * (max_demand + max_demand_offset) + 7, 0))

	if check_min:
		if max_demand + max_demand_offset < min_demand + min_demand_offset:
			adjust_min_demand_offset((max_demand + max_demand_offset) - (min_demand + min_demand_offset), false)

	#TODO: For optimisation, should this only be called if demand level is below combined min?
	update_demand(demand_level)

# Adjust maximum stock level by a given value. Keeps track of temporary effects from events
func adjust_max_stock_level_offset(value: int) -> void:
	max_stock_level_offset += value
	update_stock_comfort_band()

# Adjust the frequency for production and consumption. Keeps track of changes resulting from events
func adjust_consume_produce_frequency_multiplier(value: float) -> void:
	var counter_fraction := consume_counter / max(0.1, consume_produce_frequency * consume_produce_frequency_multiplier)
	consume_produce_frequency_multiplier += value
	consume_counter = counter_fraction * consume_produce_frequency_multiplier * consume_produce_frequency

func pause_consume_produce(value : bool) -> void:
	consume_produce_paused = value
	if value:
		stock_indicator_anchor.set_animation_paused(true)

func pause_transit_vehicles(value : bool) -> void:
	transit_vehicles_paused = value

func adjust_transit_speed_multiplier(value : float) -> void:
	transit_speed_multiplier = max(0.25, transit_speed_multiplier + value)

	#TODO: Set caps/limits?
	for child in get_node("RightLane").get_children():
		if child.has_method("set_speed_multiplier"):
			print("Setting speed for existing returning vehicle")
			child.set_speed_multiplier(transit_speed_multiplier)
	if !is_producing:
		for child in upstream.get_node("LeftLane").get_children():
			if child.has_method("set_speed_multiplier"):
				print("Setting speed for existing leaving vehicle")
				child.set_speed_multiplier(transit_speed_multiplier)

# Set stock indicators
func configure_stock_indicators():
	if sp_name.to_lower() in visual_indicators:
		stock_indicator_anchor = visual_indicators[sp_name.to_lower()].instance()
	else:
		stock_indicator_anchor = visual_indicators["default"].instance()

	get_node("SupplyPointVisual").add_child(stock_indicator_anchor)
	get_node("SupplyPointVisual").move_child(stock_indicator_anchor, 0)
	update_stock_indicator_value()

func update_stock_indicator_value():
	stock_indicator_value = 1.0 / (float(stock_indicator_anchor.get_indicator_count()) / max_stock_level)
	stock_indicator_anchor.set_indicator_value(stock_indicator_value)

# Adjust stock indicators
func update_stock_indicators():
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	stock_indicator_anchor.update_stock_indicators(stock_level)

# Set transit size to a given value
func set_transit_size(value : int) -> void:
	transit_size = value

# Set tick rate to a given value
func set_tick_rate(value : float) -> void:
	tick_rate = value

# Turn consuming on (true) or off (false)
func set_is_consuming(value : bool) -> void:
	is_consuming = value

# Turn production on (true) or off (false)
func set_is_producing(value : bool) -> void:
	is_producing = value
	if is_producing:
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandLabel").set_text("Production Rate")

# Set the downstream SupplyPoint to the given node
func set_downstream(value : Node):
	downstream = value
	value.upstream = self

# add_pending_stock always adds to pending stock. Negative values on delivery
func adjust_pending_stock(value : int) -> void:
	pending_stock += value

func adjust_enroute_stock(value : int) -> void:
	enroute_stock += value

func adjust_waste(value: int) -> void:
	waste += value

func adjust_transit_time(value: float) -> void:
	transit_time += value

# Adjust_stock is a helper function to centralize all stock adjustments
func adjust_stock(value : int, dostats := true) -> void:
	var previous_stock := stock_level
	stock_level = int(clamp(stock_level + value, 0, max_stock_level + max_stock_level_offset))
	var diff = stock_level - previous_stock
	if diff != value:
		var lost_stock = int(abs(diff - value))
		adjust_waste(lost_stock)
		stock_indicator_anchor.play_waste_animation(lost_stock * 2)
	should_update_indicators = true
	if dostats:
		if diff > 0:
			stock_in += diff
		else:
			stock_out += diff

# Sets the demand_level to the given value and updates the text for the level
func update_demand(value : float) -> void:
	demand_level = int(clamp(value, min_demand + min_demand_offset, max_demand + max_demand_offset))
	if is_instance_valid(demand_slider):
		correct_demand_level()
	if is_producing:
		#Note that consume_produce_frequency_multiplier as messed with by events will shape resulting values
		consume_produce_frequency = (105.0 - demand_level) / 20.0
		#print(consume_produce_frequency)
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(max(1, demand_level * 2)) + "%")
	else:
		get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level) + "%")

# Adjusts demand level if the slider does not match
func correct_demand_level() -> void:
	if demand_level != demand_slider.value:
		demand_slider.disconnect("value_changed", self, "update_demand")
		demand_slider.set_value(demand_level)
		demand_slider.connect("value_changed", self, "update_demand")

# Produces report values and stores them to lifetime
func make_report() -> void:
	#TODO: Decide whether or not we want to bake this calculation into historic data longer term (for now, it's simplifying chart generation)
	historic_misc["transit_efficiency"].append(0.0 if stock_in == 0 else transit_time / stock_in)
	transit_time = 0
	historic_stock["stock_in"].append(stock_in)
	stock_in = 0
	historic_stock["stock_out"].append(stock_out)
	stock_out = 0
	historic_stock["waste"].append(waste)
	waste = 0
	historic_stock["opening_stock"].append(opening_stock)
	opening_stock = 0
	historic_stock["closing_stock"].append(closing_stock)
	closing_stock = 0
	historic_time["time_full"].append(ticks_at_max)
	ticks_at_max = 0
	historic_time["time_empty"].append(ticks_at_min)
	ticks_at_min = 0
	historic_time["unable_to_produce"].append(ticks_no_produce)
	ticks_no_produce = 0
	historic_time["unable_to_consume"].append(ticks_no_consume)
	ticks_no_consume = 0

	for series in historic_stock:
		while historic_stock[series].size() > max_datum_count + 1:
			historic_stock[series].pop_front()
	for series in historic_time:
		while historic_time[series].size() > max_datum_count + 1:
			historic_time[series].pop_front()
	for series in historic_misc:
		while historic_misc[series].size() > max_datum_count + 1:
			historic_misc[series].pop_front()
	historic_datum_count += 1

# Set an indicator for the next vehicle crash
func set_next_vehicle_crash(val := true) -> void:
	next_vehicle_crash = val

# If enough time has passed, a supply point will produce/consume/request stock
func _process(delta):
	correct_demand_level()

	if should_update_indicators:
		update_stock_indicators()
		should_update_indicators = false
	counter += delta
	consume_counter += delta
	if consume_counter >= consume_produce_frequency * consume_produce_frequency_multiplier:
		consume_counter -= consume_produce_frequency * consume_produce_frequency_multiplier
		if !consume_produce_paused:
			if is_producing:
				produce_stock(production_rate)
			if is_consuming:
				consume_stock(consumption_rate)
		else:
			#TODO: Maybe this should be in produce_stock() and consume_stock()
			if is_producing:
				ticks_no_produce += 1
				stock_indicator_anchor.set_animation_paused(true)
			if is_consuming:
				ticks_no_consume += 1
				stock_indicator_anchor.set_animation_paused(true)
				stock_indicator_anchor.do_cant_consume()

	if counter >= tick_rate:
		counter -= tick_rate
		if stock_level >= (max_stock_level + max_stock_level_offset):
			ticks_at_max += 1
			adjust_max_demand_offset(max_demand_increase_rate)
			adjust_min_demand_offset(-min_demand_increase_rate * 2)
		elif stock_level <= 0:
			ticks_at_min += 1
			adjust_min_demand_offset(min_demand_increase_rate)
			adjust_max_demand_offset(-max_demand_increase_rate * 2)
		if stock_level > stock_comfort_band_min:
			adjust_min_demand_offset(-min_demand_increase_rate)
		if stock_level < stock_comfort_band_max:
			adjust_max_demand_offset(-max_demand_increase_rate)

		if (is_producing):
			pass
		else:
			if stock_level + pending_stock < max_stock_level * (demand_level / 100.0):
				request_stock(transit_size)

# Initialize values for sliders
func _ready() -> void:
	pickup_particles = get_node("PickupParticles")
	demand_slider = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand")
	demand_slider.connect("value_changed", self, "update_demand")
	demand_marker_min = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/MarkerAnchor/MarkerL")
	demand_marker_max = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/MarkerAnchor/MarkerR")
	adjust_min_demand_offset(0)
	adjust_max_demand_offset(0)
