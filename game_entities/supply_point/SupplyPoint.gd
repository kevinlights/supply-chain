extends HBoxContainer

var transit_vehicle_scene = preload("res://game_entities/transit_vehicle/TransitVehicle.tscn")

var sp_name : String
var stock_level : int
var max_stock_level : int
var demand_level : int
var min_demand : int
var max_demand : int
var pending_stock: int
var tick_rate : float
var counter : float
var is_producing : bool
var is_consuming : bool
var upstream : Node
var downstream : Node
var demand_slider : HSlider
var should_update_indicators : bool
var stock_indicator_count : int
var stock_indicator_anchor : TextureRect
var stock_indicator_value : float
var stock_indicator_pool : Array

# Temporary
var demand_factor : float
var transit_size : int

# Can the supply point receive the amount of toilet paper?
func request_stock(amount : int):
	if !is_instance_valid(upstream):
		print("Something terrible has happened!")
		return
		
	if upstream.stock_level - pending_stock <= 0:
		return

	var vehicle = transit_vehicle_scene.instance()
	if transit_size != -1:
		vehicle.set_cargo_limit(transit_size)
	else:
		vehicle.set_cargo_limit()
	# Vehicle checks for how much is needed then collects and delivers
	vehicle.order(int(min(amount, max_stock_level - stock_level)), upstream)

# Add stock to stock_level, limited by the max
func produce_stock(amount: int) -> void:
	adjust_stock(amount)

# Draw from the existing stockpile (no toilet paper debt yet)
func consume_stock(amount: int) -> void:
	adjust_stock(-amount)

# Constructor for SupplyPoint. Default supply points start without stock and
# demand 50 units of toilet paper. Default constraints are [0, 100]
func init(new_name := "New Supply Point", new_max_level := 100, new_level := 0, new_demand := 50,
	new_max_demand := 100, new_min_demand := 0):
	max_stock_level = new_max_level
	stock_level = new_level
	demand_level = new_demand
	min_demand = new_min_demand
	max_demand = new_max_demand
	pending_stock = 0
	tick_rate = 1.0
	counter = 0.0
	is_producing = false
	is_consuming = false
	demand_factor = 1.0
	transit_size = -1
	sp_name = new_name
	stock_indicator_count = 0
	stock_indicator_value = 1.0
	should_update_indicators = false
	get_node("SupplyPointVisual/VBoxContainer/Title").set_text(sp_name)
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level))
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand").set_value(demand_level)
	configure_stock_indicators()

func configure_stock_indicators():
	if has_node("SupplyPointVisual/AnchorBackground"):
		stock_indicator_anchor = get_node("SupplyPointVisual/AnchorBackground")
		stock_indicator_count = stock_indicator_anchor.get_child_count()
		stock_indicator_value = 1.0 / (float(stock_indicator_count) / max_stock_level)
		for indicator in stock_indicator_anchor.get_children():
			indicator.visible = false
	for i in range(0, 20):
		stock_indicator_pool.append(load("res://game_entities/supply_point/home_visuals/stock_item_%02d.png" % i))


func update_stock_indicators():
	get_node("SupplyPointVisual/VBoxContainer/Stock").set_text(str(stock_level))
	for i in range(0, stock_indicator_count):
		if i < stock_level / stock_indicator_value:
			if stock_indicator_anchor.get_child(i).visible == false:
				stock_indicator_anchor.get_child(i).texture = stock_indicator_pool[randi() % stock_indicator_pool.size() - 1]
				stock_indicator_anchor.get_child(i).visible = true
			#TODO: Set texture from pool of images
		else:
			stock_indicator_anchor.get_child(i).visible = false

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

func set_downstream(value : Node):
	downstream = value
	value.upstream = self

# add_pending_stock always adds to pending stock. Negative values on delivery
func adjust_pending_stock(value : int) -> void:
	pending_stock += value

# adjust_stock is a helper function to centralize all stock adjustments
func adjust_stock(value : int) -> void:
	stock_level = int(clamp(stock_level + value, 0, max_stock_level))
	should_update_indicators = true

# Sets the demand_level to the given value and updates the text for the level
func update_demand(value : float) -> void:
	demand_level = int(value)
	get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/DemandValue").set_text(str(demand_level))

# If enough time has passed, a supply point will produce/consume/request stock
func _process(delta):
	if should_update_indicators:
		update_stock_indicators()
		should_update_indicators = false
	counter += delta
	if counter >= tick_rate:
		counter -= tick_rate
		if is_producing:
			produce_stock(demand_level)
		else:
			if is_consuming:
				consume_stock(demand_level)
			if stock_level + pending_stock < demand_level:
				request_stock(int(demand_level * demand_factor))

# Initialize values for sliders
func _ready() -> void:
	demand_slider = get_node("SupplyPointVisual/VBoxContainer/Panel/VBoxContainer/Demand")
	demand_slider.connect("value_changed", self, "update_demand")
