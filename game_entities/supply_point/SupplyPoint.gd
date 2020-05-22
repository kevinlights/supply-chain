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
var min_demand : int
var max_demand : int
var pending_stock: int
var tick_rate : float
var counter : float
var consume_counter: float
var is_producing : bool
var is_consuming : bool
var upstream : Node
var downstream : Node
var demand_slider : HSlider
var should_update_indicators : bool
var stock_indicator_count : int
var stock_indicator_anchor : TextureRect
var stock_indicator_value : float
var consumption_rate : int
var production_rate : int
var consume_produce_frequency : float
var consume_produce_frequency_multiplier : float = 1.0
var next_vehicle_crash : bool = false

var demand_marker_min : TextureRect
var demand_marker_max : TextureRect

# Temporary
var demand_factor : float
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

# Lifetime performance indicators
var stock_in_life : Array
var stock_out_life : Array
var waste_life : Array
var opening_stock_life : Array
var closing_stock_life : Array
var ticks_at_max_life : Array
var ticks_at_min_life : Array
var ticks_no_produce_life : Array
var ticks_no_consume_life : Array

# Can the supply point receive the amount of toilet paper?
func request_stock(amount : int):
	if !is_instance_valid(upstream):
		print("Something terrible has happened!")
		return
		
	if upstream.stock_level - pending_stock <= 0:
		return

	var vehicle = transit_vehicle_scene.instance()
	
	if next_vehicle_crash:
		vehicle.set_crash()
		set_next_vehicle_crash(false)

	if transit_size != -1:
		vehicle.set_cargo_limit(transit_size)
	else:
		vehicle.set_cargo_limit()
	# Vehicle checks for how much is needed then collects and delivers
	vehicle.order(int(min(amount, max_stock_level - stock_level)), upstream)

# Add stock to stock_level, limited by the max
func produce_stock(amount: int) -> void:
	if (stock_level < max_stock_level + max_stock_level_offset):
		amount = int(min(amount, max_stock_level + max_stock_level_offset - stock_level))
		adjust_stock(amount)
	else:
		ticks_no_produce += 1
	if (stock_level < max_stock_level + max_stock_level_offset):
		stock_indicator_anchor.set_animation_paused(false)
	else:
		stock_indicator_anchor.set_animation_paused(true)


# Draw from the existing stockpile (no toilet paper debt yet)
func consume_stock(amount: int) -> void:
	var adj_amount : int = int(min(amount, stock_level))
	adjust_stock(-adj_amount)
	if (adj_amount != amount):
		ticks_no_consume += 1

	if (stock_level > 0):
		stock_indicator_anchor.set_animation_paused(false)
	else:
		stock_indicator_anchor.set_animation_paused(true)


# Constructor for SupplyPoint. Default supply points start without stock and
# demand 50 units of toilet paper. Default constraints are [0, 100]
func init(new_name := "New Supply Point", new_max_level := 100, new_level := 0, new_demand := 50,
	new_max_demand := 100, new_min_demand := 0):
	max_stock_level = new_max_level + max_stock_level_offset
	stock_level = new_level
	demand_level = new_demand
	min_demand = new_min_demand
	max_demand = new_max_demand
	pending_stock = 0
	tick_rate = 1.0
	consume_produce_frequency = 0.50
	production_rate = 2
	consumption_rate = 1
	counter = 0.0
	consume_counter = 0.0
	is_producing = false
	is_consuming = false
	demand_factor = 1.0
	transit_size = -1
	sp_name = new_name
	stock_indicator_count = 0
	stock_indicator_value = 1.0
	should_update_indicators = false
	get_node("SupplyPointVisual/VBoxContainer/Title").set_text(sp_name.to_upper())
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level) + "%")
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand").set_value(demand_level)
	configure_stock_indicators()

# Set max stock level to a given value
func set_max_stock_level(value : int) -> void:
	max_stock_level = value

# Set stock level to a given value
func set_stock_level(value : int) -> void:
	stock_level = value
	update_stock_indicators()

# Adjust minimum demand by a given value. Keeps track of temporary effects from events
func adjust_min_demand_offset(value : int) -> void:
	min_demand_offset += value
	demand_marker_min.set_position(Vector2(demand_marker_min.get_parent().get_parent().get_size().x / 100.0 * (min_demand + min_demand_offset) - 6, 0))
	update_demand(demand_level)

# Adjust maximum demand by a given value. Keeps track of temporary effects from events
func adjust_max_demand_offset(value : int) -> void:
	max_demand_offset += value
	demand_marker_max.set_position(Vector2(demand_marker_max.get_parent().get_parent().get_size().x / 100.0 * (max_demand + max_demand_offset), 0))
	update_demand(demand_level)

# Adjust maximum stock level by a given value. Keeps track of temporary effects from events
func adjust_max_stock_level_offset(value: int) -> void:
	max_stock_level_offset += value

# Adjust the frequency for production and consumption. Keeps track of changes resulting from events
func adjust_consume_produce_frequency_multiplier(value: float) -> void:
	var counter_fraction := (consume_produce_frequency * consume_produce_frequency_multiplier) / consume_counter
	consume_produce_frequency_multiplier += value
	consume_counter = counter_fraction * consume_produce_frequency_multiplier * consume_produce_frequency

# Set stock indicators
func configure_stock_indicators():
	if sp_name.to_lower() in visual_indicators:
		stock_indicator_anchor = visual_indicators[sp_name.to_lower()].instance()
	else:
		stock_indicator_anchor = visual_indicators["default"].instance()

	get_node("SupplyPointVisual").add_child(stock_indicator_anchor)
	get_node("SupplyPointVisual").move_child(stock_indicator_anchor, 0)
	stock_indicator_count = stock_indicator_anchor.get_child_count()
	stock_indicator_value = 1.0 / (float(stock_indicator_count) / max_stock_level)
	stock_indicator_anchor.set_indicator_value(stock_indicator_value)

# Adjust stock indicators
func update_stock_indicators():
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	stock_indicator_anchor.update_stock_indicators(stock_level)

# Set demand factor (no longer used?)
func set_demand_factor(value : float) -> void:
	demand_factor = value

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

# Set the downstream SupplyPoint to the given node
func set_downstream(value : Node):
	downstream = value
	value.upstream = self

# add_pending_stock always adds to pending stock. Negative values on delivery
func adjust_pending_stock(value : int) -> void:
	pending_stock += value

func adjust_waste(value: int) -> void:
	waste += value

# Adjust_stock is a helper function to centralize all stock adjustments
func adjust_stock(value : int, dostats := true) -> void:
	var previous_stock := stock_level
	stock_level = int(clamp(stock_level + value, 0, max_stock_level + max_stock_level_offset))
	var diff = stock_level - previous_stock
	if diff != value:
		adjust_waste(int(abs(diff - value)))
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
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level) + "%")

# Adjusts demand level if the slider does not match
func correct_demand_level() -> void:
	if demand_level != demand_slider.value:
		demand_slider.disconnect("value_changed", self, "update_demand")
		demand_slider.set_value(demand_level)
		demand_slider.connect("value_changed", self, "update_demand")

# Prints report values to output and stores them to lifetime
func make_report() -> void:
	# Print the report
	print("Report for %s" % sp_name)
	print("Stock in: ", str(stock_in))
	print("Stock out: ", str(abs(stock_out)))
	print("Waste: ", str(waste))
	print("Opening stock: ", str(opening_stock))
	print("Closing  stock: ", str(closing_stock))
	print("Ticks at max: ", str(ticks_at_max))
	print("Ticks at min: ", str(ticks_at_min))
	print("Ticks no production: ", str(ticks_no_produce))
	print("Ticks no consumption: ", str(ticks_no_consume))
	
	# Add to lifetime records and reset
	stock_in_life.append(stock_in)
	stock_in = 0
	stock_out_life.append(stock_out)
	stock_out = 0
	waste_life.append(waste)
	waste = 0
	opening_stock_life.append(opening_stock)
	opening_stock = 0
	closing_stock_life.append(closing_stock)
	closing_stock = 0
	ticks_at_max_life.append(ticks_at_max)
	ticks_at_max = 0
	ticks_at_min_life.append(ticks_at_min)
	ticks_at_min = 0
	ticks_no_produce_life.append(ticks_no_produce)
	ticks_no_produce = 0
	ticks_no_consume_life.append(ticks_no_consume)
	ticks_no_consume = 0
	
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
		if is_producing:
			produce_stock(production_rate)
		if is_consuming:
			consume_stock(consumption_rate)
	if counter >= tick_rate:
		counter -= tick_rate
		if stock_level >= (max_stock_level + max_stock_level_offset):
			ticks_at_max += 1
		elif stock_level <= 0:
			ticks_at_min += 1
		if (is_producing):
			pass
		else:
			if stock_level + pending_stock < demand_level:
				request_stock(int(demand_level * demand_factor))

# Initialize values for sliders
func _ready() -> void:
	demand_slider = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand")
	demand_slider.connect("value_changed", self, "update_demand")
	demand_marker_min = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/MarkerAnchor/MarkerL")
	demand_marker_max = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/MarkerAnchor/MarkerR")
	adjust_min_demand_offset(0)
	adjust_max_demand_offset(0)
