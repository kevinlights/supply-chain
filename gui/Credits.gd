extends Control

#Declare some variables for displaying credits
var creditsFile = "credits.json" #The file that credits are stored in
var headingFont = preload("res://fonts/heading.tres") #The font that we'll use for headings
var subHeadingFont = preload("res://fonts/heading.tres") #The font that we'll use for headings of sub sections
var ui_font = preload("res://fonts/small_font.tres")
var creditsAnchor #A node that the credits will all be attached to
var firstItem = true

func _ready():
	get_node("Back").connect("pressed", self, "close")

	#Instantiate a new VBoxContainer and set it to the window size
	creditsAnchor = VBoxContainer.new()
	creditsAnchor.connect("gui_input", self, "process_input")

	#Read json from the credits file
	var credits = read_json("res://json/" + creditsFile)

	#Add the credits to the credits anchor via a fancy recursive function
	add_credits_item(credits, creditsAnchor, 0, "")

	#Add the credits anchor to the scene tree and set its position to be just below the window boundary
	add_child(creditsAnchor)

	creditsAnchor.set_position(Vector2(-creditsAnchor.get_size().x / 2, get_viewport().get_visible_rect().size.y / 2))

func read_json(path):
	var file = File.new()
	if not file.file_exists(path):
		print("ERROR: Unable to open resource ", path)
	file.open(path, file.READ)
	var text = file.get_as_text()
	file.close()
	var parse = JSON.parse(text)
	if parse.error == OK:
		return parse.result
	else:
		print("Error reading ", path, " at line " + str(parse.error_line) + ": " + parse.error_string)
		return null

func close():
	queue_free()

func process_input(event):
	if Input.is_action_pressed("ui_select"):
		if event is InputEventMouseMotion:
			var temp = creditsAnchor.get_position()
			if temp.y < - creditsAnchor.get_size().y - get_viewport().get_visible_rect().size.y / 2:
				temp.y = get_viewport().get_visible_rect().size.y / 2
	
			#Move the credits anchor up a bit
			creditsAnchor.set_position(Vector2(-creditsAnchor.get_size().x / 2, temp.y + event.relative.y))


#This built-in function is called regularly by the engine
func _process(delta):
	if Input.is_action_pressed("ui_select"):
		return
	#Get the position of the credits anchor, and if it's more than its own height above the top, wrap it back to below the window boundary
	var temp = creditsAnchor.get_position()
	if temp.y < - creditsAnchor.get_size().y - get_viewport().get_visible_rect().size.y / 2:
		temp.y = get_viewport().get_visible_rect().size.y / 2

	#Move the credits anchor up a bit
	creditsAnchor.set_position(Vector2(-creditsAnchor.get_size().x / 2, temp.y - delta * 30))

#This function recursively adds credits items to the specified credits anchor, with heading padding based on depth
func add_credits_item(item, anchor, depth, section):
	if item is Dictionary:
		#If the item's a dictionary, that means it's got headings and extra items that we need to call add_credits_item() again for
		var oldAnchor = anchor
		for section in item:
			anchor = oldAnchor
			if anchor is GridContainer:
				var tempContainer = VBoxContainer.new()
				tempContainer.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
				anchor.add_child(tempContainer)
				anchor = tempContainer

			if !firstItem:
				#Instantiate and add a MarginContainer to the anchor before the heading, sized based on depth
				var marginTemp = MarginContainer.new()
				if depth == 0:
					marginTemp.set("rect_min_size", Vector2(10, 50))
				else:
					marginTemp.set("rect_min_size", Vector2(10, 25))
				anchor.add_child(marginTemp)
				marginTemp.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
			else:
				firstItem = false

			#Instantiate a Label for the heading, set its text, font and alignment, then add it to the anchor
			var tempLabel = Label.new()
			tempLabel.set_text(section)
			tempLabel.add_font_override("font", headingFont if depth == 0 else subHeadingFont)
			tempLabel.set_align(Label.ALIGN_CENTER)
			anchor.add_child(tempLabel)

			add_credits_item(item[section], anchor, depth + 1, section)
	else:
		#If the item isn't a dictionary, it's just an array of names/roles that we can add as labels
		var itemCount = 0
		for subItem in item:
			itemCount += 1
			#Instantiate a Label for the item, set its text, font and alignment, then add it to the anchor

			if anchor is GridContainer && itemCount == item.size():
				var temp = item.size()
				if section in ["Special Thanks", "Supporters"]:
					temp -= 1
				if temp % anchor.columns != 0:
					anchor.add_child(MarginContainer.new())

			if subItem.ends_with(".co.uk") || subItem.ends_with(".com") || subItem.ends_with(".com.au") || subItem.ends_with(".net") || subItem.ends_with(".ca"):
				var tempButton = Button.new()
				tempButton.set_text(subItem)
				tempButton.set_text_align(Button.ALIGN_CENTER)
				tempButton.set_focus_mode(Control.FOCUS_NONE)
				tempButton.set_flat(true)
				tempButton.connect("pressed", get_parent(), "open_url", [subItem])
				anchor.add_child(tempButton)
			else:
				var tempLabel = Label.new()
				tempLabel.add_font_override("font", ui_font)
				tempLabel.set_text(subItem)
				tempLabel.set_align(Label.ALIGN_CENTER)
				anchor.add_child(tempLabel)

			if section in ["Special Thanks", "Supporters"] && itemCount == 1:
				anchor = setup_grid(anchor, 3 if item.size() >= 4 else item.size())

func setup_grid(anchor, columns):
	var centerer = CenterContainer.new()
	centerer.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	anchor.add_child(centerer)
	var gridder = GridContainer.new()
	gridder.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	gridder.columns = columns
	gridder.set("custom_constants/hseparation", 50)
	centerer.add_child(gridder)
	return gridder
