extends Control

var heading_font = preload("res://fonts/heading.tres") #The font that we'll use for headings
var ui_font = preload("res://fonts/small_font.tres")
var settings_container : VBoxContainer
var user_config : ConfigFile
var config_file := "user://config.cfg"
var gap_space : int = 10

var settings := {
	"audio": {
			"master_volume":
			{
				"type": TYPE_REAL,
				"default": 0.75,
				"description": "Adjusts the master volume for all game audio.",
			},
			"music_volume":
			{
				"type": TYPE_REAL,
				"default": 0.5,
				"description": "Adjusts the volume of in-game music.",
			},
			"sfx_volume":
			{
				"type": TYPE_REAL,
				"default": 0.75,
				"description": "Adjusts the volume of in-game sounds.",
			}
		},
	"gameplay": {
			"start_stocked":
			{
				"type": TYPE_BOOL,
				"default": false,
				"description": "Gives each supply point initial stock when starting a new game.",
			},
			"auto_stop_production":
			{
				"type": TYPE_BOOL,
				"default": false,
				"description": "Automatically stops production when producing supply points are full.",
			},
			"prevent_transit_waste":
			{
				"type": TYPE_BOOL,
				"default": false,
				"description": "Prevents vehicles from picking up more stock than there is room to deliver.",
			},
			#TODO: Maybe events and reports should be frequency ranges in minutes with 0 being never?
			"skip_events":
			{
				"type": TYPE_BOOL,
				"default": false,
				"description": "Prevents events from triggering in-game.",
			},
			"skip_reports":
			{
				"type": TYPE_BOOL,
				"default": false,
				"description": "Prevents reports from triggering in-game.",
			},
		},
	}

func _ready():
	get_node("Back").connect("pressed", self, "close")
	user_config = ConfigFile.new()
	if user_config.load(config_file) != OK:
		printerr("Unable to load user config. Using defaults.")

	settings_container = get_node("ColorRect/CenterContainer/VBoxContainer")

	for category in settings:
		var heading_label := Label.new()
		heading_label.set_text(category.capitalize())
		heading_label.add_font_override("font", heading_font)
		settings_container.add_child(heading_label)
		for item in settings[category]:
			settings[category][item]["stored_value"] = retrieve_config_value(category, item)
			if settings[category][item]["type"] == TYPE_BOOL:
				var widget := CheckBox.new()
				widget.add_font_override("font", ui_font)
				widget.set_text(item.capitalize())
				widget.hint_tooltip = settings[category][item]["description"]
				widget.set_pressed(settings[category][item]["stored_value"])
				update_setting_bool(settings[category][item]["stored_value"], category, item)
				widget.connect("toggled", self, "update_setting_bool", [category, item])
				settings_container.add_child(widget)
			elif settings[category][item]["type"] == TYPE_REAL:
				var label := Label.new()
				label.add_font_override("font", ui_font)
				label.set_text(item.capitalize())
				label.hint_tooltip = settings[category][item]["description"]
				label.set_mouse_filter(Control.MOUSE_FILTER_STOP)
				update_setting_range(settings[category][item]["stored_value"], category, item, label)
				var widget := HSlider.new()
				widget.set_h_size_flags(HSlider.SIZE_EXPAND_FILL)
				widget.set_v_size_flags(HSlider.SIZE_EXPAND_FILL)
				widget.set_min(0.0)
				widget.set_max(1.0)
				widget.set_step(0.01)
				widget.set_value(settings[category][item]["stored_value"])
				widget.hint_tooltip = settings[category][item]["description"]
				widget.connect("value_changed", self, "update_setting_range", [category, item, label])
				settings_container.add_child(label)
				settings_container.add_child(widget)
			var gap := MarginContainer.new()
			gap.set_custom_minimum_size(Vector2(gap_space, gap_space))
			settings_container.add_child(gap)
		var gap := MarginContainer.new()
		gap.set_custom_minimum_size(Vector2(gap_space, gap_space))
		settings_container.add_child(gap)

func update_setting_bool(state, category, setting):
	if has_method("set_" + setting):
		call("set_" + setting, state)
	store_config_value(category, setting, state)

func update_setting_range(value, category, setting, label):
	if is_instance_valid(label):
		var labelValue = String(int(value * 100)) + "%"
		if value <= 0:
			labelValue = "off"
		label.set_text(setting.capitalize() + " (" + labelValue + ")")

	if has_method("set_" + setting):
		call("set_" + setting, value)

	if setting.ends_with("_volume"):
		update_setting_volume(value, setting.substr(0, setting.length() - 7))

	store_config_value(category, setting, value)

func store_config_value(category, setting, value = null):
	if value == null:
		value = retrieve_config_value(category, setting)
	user_config.set_value(category, setting, value)
	user_config.save(config_file)

func retrieve_config_value(category, setting):
	return user_config.get_value(category, setting, settings[category][setting]["default"])

func update_setting_volume(value, bus):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus.capitalize()), linear2db(value))

func close() -> void:
	get_parent().fake_show_menu()
	visible = false

func get_setting(category, setting):
	return retrieve_config_value(category, setting)

func set_skip_events(value : bool) -> void:
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.skip_events = value

func set_skip_reports(value) -> void:
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.skip_reports = value

func set_start_stocked(value : bool) -> void:
	get_parent().start_stocked = value

func set_auto_stop_production(value : bool) -> void:
	get_parent().auto_stop_production = value
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.set_auto_stop_production(value)

func set_prevent_transit_waste(value : bool) -> void:
	get_parent().prevent_transit_waste = value
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.set_prevent_transit_waste(value)
