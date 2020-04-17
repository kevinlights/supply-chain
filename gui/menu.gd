extends CenterContainer

var new_button : Button
var settings_button : Button
var quit_button : Button

# Called when the node enters the scene tree for the first time.
func _ready():
	new_button = get_node("VBoxContainer/New")
	settings_button = get_node("VBoxContainer/Settings")
	quit_button = get_node("VBoxContainer/Quit")

	if new_button.connect("pressed", self, "new_game") != OK:
		printerr("Error while connecting signal to new game button")
	if settings_button.connect("pressed", self, "show_settings") != OK:
		printerr("Error while connecting signal to settings button")
	if quit_button.connect("pressed", self, "quit_game") != OK:
		printerr("Error while connecting signal to quit game button")


func new_game():
	print("New game stub")

func show_settings():
	print("Show settings stub")

func quit_game():
	get_tree().quit()
