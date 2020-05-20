extends CenterContainer

var game_scene = preload("res://gui/Game.tscn")
var credits_scene = preload("res://gui/Credits.tscn")

var new_button : Button
var settings_button : Button
var credits_button : Button
var quit_button : Button
var resume_button : Button
var game_node : HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	resume_button = get_node("VBoxContainer/Resume")
	new_button = get_node("VBoxContainer/New")
	settings_button = get_node("VBoxContainer/Settings")
	credits_button = get_node("VBoxContainer/Credits")
	quit_button = get_node("VBoxContainer/Quit")

	if new_button.connect("pressed", self, "new_game") != OK:
		printerr("Error while connecting signal to new game button")
	if resume_button.connect("pressed", self, "resume_game") != OK:
		printerr("Error while connecting signal to new game button")
	if settings_button.connect("pressed", self, "show_settings") != OK:
		printerr("Error while connecting signal to settings button")
	if credits_button.connect("pressed", self, "show_credits") != OK:
		printerr("Error while connecting signal to credits button")
	if quit_button.connect("pressed", self, "quit_game") != OK:
		printerr("Error while connecting signal to quit game button")

# Pauses game and makes menus visible
func show_menu():
	self.visible = true

	resume_button.visible = true
	game_node.visible = false
	get_tree().paused = true

# Hides menu and unpauses game
func hide_menu():
	self.visible = false
	get_tree().paused = false

# Hides the menu and resumes the game
func resume_game():
	hide_menu()
	game_node.visible = true

# Creates a new game with SupplyPoints back to default values
func new_game():
	if is_instance_valid(game_node):
		game_node.queue_free()
	game_node = game_scene.instance()
	game_node.menu_node = self
	get_parent().add_child(game_node)
	hide_menu()

# Shows settings menu, currently a stub
func show_settings():
	print("Show settings stub")

# Plays credits
func show_credits():
	add_child(credits_scene.instance())

# Exit the game
func quit_game():
	get_tree().quit()
