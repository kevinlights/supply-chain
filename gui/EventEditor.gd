extends Control

var headingFont = preload("res://fonts/heading.tres") #The font that we'll use for headings
var editor_container : VBoxContainer
var event_selector : OptionButton
var prop_selector : OptionButton
var game_node : HBoxContainer
var selected_supply_point = ""
var selected_item_index = ""
var selected_event = {}

var color_bad = Color(1.0, 0, 0, 1.0)

func _ready():
	editor_container = get_node("PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer")
	event_selector = get_node("PanelContainer/VBoxContainer/HBoxContainer/EventSelector")
	prop_selector = get_node("PanelContainer/VBoxContainer/HBoxContainer3/PropertyList")
	get_node("PanelContainer/VBoxContainer/HBoxContainer3/AddPropertyButton").connect("pressed", self, "add_property")

	get_node("PanelContainer/VBoxContainer/HBoxContainer/PrevButton").connect("pressed", self, "select_prev_event")
	get_node("PanelContainer/VBoxContainer/HBoxContainer/NextButton").connect("pressed", self, "select_next_event")

	get_node("PanelContainer/VBoxContainer/HBoxContainer2/SaveButton").connect("pressed", self, "save_event")
	get_node("PanelContainer/VBoxContainer/HBoxContainer2/DeleteButton").connect("pressed", self, "delete_event")
	get_node("PanelContainer/VBoxContainer/HBoxContainer2/PreviewButton").connect("pressed", self, "preview_event")
	get_node("PanelContainer/VBoxContainer/HBoxContainer2/ActivateButton").connect("pressed", self, "activate_event")

	game_node = get_parent().get_node("Game")
	populate_selectors()
	generate_editor_ui(0)
	get_tree().paused = true

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			close()

func populate_selectors(select_supply_point = "", select_item_index = -1):
	if event_selector.is_connected("item_selected", self, "generate_editor_ui"):
		event_selector.disconnect("item_selected", self, "generate_editor_ui")
	event_selector.clear()
	event_selector.add_item("-New event-")

	for supply_point in game_node.event_list:
		for item in game_node.event_list[supply_point]:
			var id = game_node.event_list[supply_point].find(item)
			if "internal_name" in item:
				event_selector.add_item(supply_point + ": " + item["internal_name"], id)
				event_selector.set_item_metadata(event_selector.get_item_count() - 1, supply_point)
			elif "headline" in item:
				event_selector.add_item(supply_point + ": " + item["headline"], id)
				event_selector.set_item_metadata(event_selector.get_item_count() - 1, supply_point)
			else:
				event_selector.add_item(supply_point + ": " + String(item), id)
				event_selector.set_item_metadata(event_selector.get_item_count() - 1, supply_point)
	event_selector.connect("item_selected", self, "generate_editor_ui")

	if select_item_index != -1 && select_supply_point in game_node.event_list:
		for i in range(0, event_selector.get_item_count()):
			if event_selector.get_item_metadata(i) == select_supply_point && event_selector.get_item_id(i) == select_item_index:
				event_selector.select(i)
	else:
		event_selector.select(0)


	prop_selector.clear()
	for prop in game_node.event_prop_list:
		if "required" in game_node.event_prop_list[prop] && game_node.event_prop_list[prop]["required"] == true:
			continue
		prop_selector.add_item(prop)

func clear_editor_ui():
	while editor_container.get_child_count() > 0:
		editor_container.remove_child(editor_container.get_children()[0])

func get_event_template():
	var template = {}
	for prop in game_node.event_prop_list:
		if "required" in game_node.event_prop_list[prop] && game_node.event_prop_list[prop]["required"] == true:
			template[prop] = game_node.event_prop_list[prop]["default"]
	return template

func generate_editor_ui(id):
	clear_editor_ui()

	if id == 0:
		selected_supply_point = ""
		selected_item_index = -1
		selected_event = get_event_template()
	else:
		selected_supply_point = event_selector.get_selected_metadata()
		selected_item_index = event_selector.get_selected_id()
		selected_event = game_node.event_list[selected_supply_point][selected_item_index].duplicate()

	for prop in game_node.event_prop_list:
		if "required" in game_node.event_prop_list[prop] && game_node.event_prop_list[prop]["required"] == true:
			generate_prop_widget(selected_event, prop, false)

	for prop in selected_event:
		if prop in game_node.event_prop_list:
			if "required" in game_node.event_prop_list[prop] && game_node.event_prop_list[prop]["required"] == true:
				continue
			generate_prop_widget(selected_event, prop)
		else:
			print("Can't show widget for unknown property ", prop)

func generate_prop_widget(event, prop, removeable = true):
	if !(prop in event):
		event[prop] = game_node.event_prop_list[prop]["default"]
	if game_node.event_prop_list[prop]["type"] == TYPE_STRING:
		editor_container.add_child(generate_string_widget(prop, event[prop], removeable))
	elif game_node.event_prop_list[prop]["type"] == TYPE_REAL:
		editor_container.add_child(generate_float_widget(prop, event[prop], false, removeable))
	elif game_node.event_prop_list[prop]["type"] == TYPE_INT:
		editor_container.add_child(generate_float_widget(prop, event[prop], true, removeable))
	elif game_node.event_prop_list[prop]["type"] == TYPE_BOOL:
		editor_container.add_child(generate_bool_widget(prop, event[prop], removeable))

func generate_remove_button(name, container):
	var remove_button = Button.new()
	remove_button.set_text("X")
	remove_button.connect("pressed", self, "remove_property", [name, container])
	container.add_child(remove_button)

func generate_label(text):
	var label = Label.new()
	label.set_custom_minimum_size(Vector2(150, 25))
	label.set_text(text.capitalize() + ": ")
	label.set_valign(Label.VALIGN_CENTER)
	label.set_align(Label.ALIGN_RIGHT)
	return label

func generate_bool_widget(name, value, removeable):
	var temp_container = HBoxContainer.new()
	temp_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	var widget = CheckBox.new()
	widget.set_text(name.capitalize())
	widget.set_pressed(value)
	widget.connect("toggled", self, "update_bool_value", [name])
	temp_container.add_child(widget)
	if removeable:
		generate_remove_button(name, temp_container)
	return temp_container

func generate_float_widget(name, value, is_int, removeable):
	var temp_container = HBoxContainer.new()
	temp_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	temp_container.add_child(generate_label(name))
	var widget = SpinBox.new()
	widget.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	if is_int:
		widget.set_step(1.0)
	else:
		widget.set_step(0.1)
	widget.set_allow_lesser(true)
	widget.set_allow_greater(true)
	widget.set_value(value)

	widget.connect("value_changed", self, "update_float_value", [name])
	temp_container.add_child(widget)

	if removeable:
		generate_remove_button(name, temp_container)

	return temp_container

func generate_string_widget(name, value, removeable):
	var temp_container = HBoxContainer.new()
	temp_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	temp_container.add_child(generate_label(name))
	var widget = TextEdit.new()
	widget.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	widget.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	widget.set_text(value)
	temp_container.add_child(widget)

	if "validate_func" in game_node.event_prop_list[name]:
		widget.connect("text_changed", self, game_node.event_prop_list[name]["validate_func"], [widget, name])
	widget.connect("text_changed", self, "update_string_value", [widget, name])

	if removeable:
		generate_remove_button(name, temp_container)

	return temp_container

func remove_property(name, container):
	print(selected_event)
	selected_event.erase(name)
	print(selected_event)
	container.queue_free()

func add_property(prop = ""):
	if prop == "":
		prop = prop_selector.get_item_text(prop_selector.get_selected_id())
	if !(prop in selected_event):
		if prop in game_node.event_prop_list:
			generate_prop_widget(selected_event, prop)
		else:
			print("Can't show widget for unknown property ", prop)
	else:
		print("Can't add property twice ", prop)

func update_string_value(widget, prop):
	selected_event[prop] = widget.get_text()

func update_float_value(value, prop):
	selected_event[prop] = value

func update_bool_value(value, prop):
	selected_event[prop] = value

func check_image(widget, prop, value = ""):
	if value == "":
		value = widget.get_text()
	var valid = false
	if value.ends_with(".png"):
		var path = ""
		if prop in game_node.event_prop_list && "prefix" in game_node.event_prop_list[prop]:
			path = game_node.event_prop_list[prop]["prefix"]
		if ResourceLoader.exists(path + value):
			valid = true
	if is_instance_valid(widget):
		if valid:
			widget.set("custom_colors/font_color", null)
		else:
			widget.add_color_override("font_color", color_bad)
	return valid

func check_sp_name(widget, _prop, value = ""):
	if value == "":
		value = widget.get_text()
	var valid = false
	if value in game_node.supply_point_list.keys() || value == "generic":
		valid = true

	if is_instance_valid(widget):
		if valid:
			widget.set("custom_colors/font_color", null)
		else:
			widget.add_color_override("font_color", color_bad)
	return valid

func save_event_list():
	game_node.write_json(game_node.events_file, game_node.event_list)

func save_event():
	for prop in selected_event:
		if prop in game_node.event_prop_list:
			if "validate_func" in game_node.event_prop_list[prop]:
				print("Trying validation of ", prop)
				if !call(game_node.event_prop_list[prop]["validate_func"], null, prop, selected_event[prop]):
					print("Can't save, ", prop, " value is invalid.")
					return
	if selected_item_index != -1:
		if selected_supply_point != selected_event["supply_point"]:
			print(selected_event["internal_name"] + " removing from supply point ", selected_supply_point)
			game_node.event_list[selected_supply_point].erase(game_node.event_list[selected_supply_point][selected_item_index])
			selected_item_index = -1
		else:
			print(selected_event["internal_name"] + " keeping supply point ", selected_supply_point)
	selected_supply_point = selected_event["supply_point"]

	if selected_item_index != -1:
		game_node.event_list[selected_supply_point][selected_item_index] = selected_event
	else:
		if !(selected_supply_point in game_node.event_list):
			game_node.event_list[selected_supply_point] = []
		game_node.event_list[selected_supply_point].push_back(selected_event)
		selected_item_index = game_node.event_list[selected_supply_point].size() -1
	print("Validation passed?", selected_event)
	save_event_list()
	populate_selectors(selected_supply_point, selected_item_index)

func delete_event():
	if selected_item_index != -1:
		game_node.event_list[selected_supply_point].erase(game_node.event_list[selected_supply_point][selected_item_index])
		selected_item_index = -1
		selected_supply_point = ""
	save_event_list()
	populate_selectors(selected_supply_point, selected_item_index)
	generate_editor_ui(0)

func preview_event():
	if "headline" in selected_event:
		var newspaper = game_node.newspaper_scene.instance()
		newspaper.is_preview = true
		newspaper.set_event(selected_event)
		game_node.get_parent().add_child(newspaper)

func activate_event():
	get_tree().paused = false
	game_node.add_event(selected_event)
	queue_free()

func close():
	get_tree().paused = false
	queue_free()

func select_next_event():
	if event_selector.get_item_count() < 2:
		return
	var temp = event_selector.get_selected() + 1
	if temp >= event_selector.get_item_count():
		temp = 0
	event_selector.select(temp)
	generate_editor_ui(temp)

func select_prev_event():
	if event_selector.get_item_count() < 2:
		return
	var temp = event_selector.get_selected() - 1
	if temp < 0:
		temp = event_selector.get_item_count() - 1
	event_selector.select(temp)
	generate_editor_ui(temp)
