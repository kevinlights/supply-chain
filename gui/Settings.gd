extends Control

var headingFont = preload("res://fonts/heading.tres") #The font that we'll use for headings
var settingsContainer : VBoxContainer
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
				"default": 0.75,
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

	settingsContainer = get_node("ColorRect/CenterContainer/VBoxContainer")

	for category in settings:
		var headingLabel := Label.new()
		headingLabel.set_text(category.capitalize())
		headingLabel.add_font_override("font", headingFont)
		settingsContainer.add_child(headingLabel)
		for item in settings[category]:
			settings[category][item]["stored_value"] = retrieve_config_value(category, item)
			print(settings[category][item])
			if settings[category][item]["type"] == TYPE_BOOL:
				var widget := CheckBox.new()
				widget.set_text(item.capitalize())
				widget.hint_tooltip = settings[category][item]["description"]
				widget.set_pressed(settings[category][item]["stored_value"])
				update_setting_bool(settings[category][item]["stored_value"], category, item)
				widget.connect("toggled", self, "update_setting_bool", [category, item])
				settingsContainer.add_child(widget)
			elif settings[category][item]["type"] == TYPE_REAL:
				var label := Label.new()
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
				settingsContainer.add_child(label)
				settingsContainer.add_child(widget)
			var gap := MarginContainer.new()
			gap.set_custom_minimum_size(Vector2(gap_space, gap_space))
			settingsContainer.add_child(gap)
		var gap := MarginContainer.new()
		gap.set_custom_minimum_size(Vector2(gap_space, gap_space))
		settingsContainer.add_child(gap)

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

func close():
	visible = false

func get_setting(category, setting):
	return retrieve_config_value(category, setting)

func set_skip_events(value):
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.skip_events = value

func set_skip_reports(value):
	if is_instance_valid(get_parent().game_node):
		get_parent().game_node.skip_reports = value