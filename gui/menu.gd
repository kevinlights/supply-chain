extends CenterContainer

var game_scene = preload("res://gui/Game.tscn")
var credits_scene = preload("res://gui/Credits.tscn")

var new_button : Button
var settings_button : Button
var credits_button : Button
var website_button : Button
var quit_button : Button
var resume_button : Button
var game_node : HBoxContainer
var music_player : AudioStreamPlayer
var settings : Control
var start_stocked = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	resume_button = get_node("VBoxContainer/Resume")
	new_button = get_node("VBoxContainer/New")
	settings_button = get_node("VBoxContainer/Settings")
	credits_button = get_node("VBoxContainer/Credits")
	website_button = get_node("VBoxContainer/Website")
	quit_button = get_node("VBoxContainer/Quit")


	if new_button.connect("pressed", self, "new_game") != OK:
		printerr("Error while connecting signal to new game button")
	if resume_button.connect("pressed", self, "resume_game") != OK:
		printerr("Error while connecting signal to new game button")
	if settings_button.connect("pressed", self, "show_settings") != OK:
		printerr("Error while connecting signal to settings button")
	if credits_button.connect("pressed", self, "show_credits") != OK:
		printerr("Error while connecting signal to credits button")
	if website_button.connect("pressed", self, "open_url", ["cheeseness.itch.io/supply-chain"]) != OK:
		printerr("Error while connecting signal to credits button")
	if quit_button.connect("pressed", self, "quit_game") != OK:
		printerr("Error while connecting signal to quit game button")

	settings = get_node("Settings")

	music_player = get_node("MusicPlayer")
	music_player.play_menu_music()

# Pauses game and makes menus visible
func show_menu() -> void:
	print("Showing menu")
	self.visible = true
	resume_button.visible = true
	game_node.visible = false
	get_tree().paused = true
	music_player.play_menu_music()

# Hides menu and unpauses game
func hide_menu() -> void:
	print("Hiding menu")
	self.visible = false
	get_tree().paused = false
	music_player.resume_track()

# Hides the menu and resumes the game
func resume_game() -> void:
	hide_menu()
	game_node.visible = true

# Creates a new game with SupplyPoints back to default values
func new_game() -> void:
	print("Starting new game")
	music_player.assemble_playlist()
	if is_instance_valid(game_node):
		game_node.queue_free()
	game_node = game_scene.instance()
	game_node.menu_node = self
	game_node.start_stocked = start_stocked
	game_node.skip_events = settings.get_setting("gameplay", "skip_events")
	game_node.skip_reports = settings.get_setting("gameplay", "skip_reports")
	get_parent().add_child(game_node)
	hide_menu()

# Shows settings menu, currently a stub
func show_settings() -> void:
	settings.visible = true

# Plays credits
func show_credits() -> void:
	add_child(credits_scene.instance())

# Exit the game
func quit_game() -> void:
	get_tree().quit()

func open_url(url):
	if !(url.begins_with("http://") || url.begins_with("https://")):
		url = "http://" + url
	print("Attempting to launch URL: ", url, " (", OS.shell_open(url), ")")
