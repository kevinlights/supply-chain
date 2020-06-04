extends CenterContainer

var game_scene = preload("res://gui/Game.tscn")
var credits_scene = preload("res://gui/Credits.tscn")

var version_number : String = "Unknown"
var new_button : Button
var settings_button : Button
var credits_button : Button
var website_button : Button
var quit_button : Button
var resume_button : Button
var button_container : VBoxContainer
var game_node : HBoxContainer
var music_player : AudioStreamPlayer
var settings : Control
var start_stocked = false
var auto_stop_production = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	load_version_number()

	resume_button = get_node("VBoxContainer/Resume")
	new_button = get_node("VBoxContainer/New")
	settings_button = get_node("VBoxContainer/Settings")
	credits_button = get_node("VBoxContainer/Credits")
	website_button = get_node("VBoxContainer/Website")
	quit_button = get_node("VBoxContainer/Quit")
	button_container = get_node("VBoxContainer")

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
	settings.get_node("Label").set_text(version_number)

	music_player = get_node("MusicPlayer")
	music_player.play_menu_music()

	#Workaround for https://github.com/godotengine/godot/issues/29362
	get_viewport().set_pause_mode(Node.PAUSE_MODE_PROCESS)

func _input(event):
	if visible:
		if event.is_action_pressed("ui_cancel"):
			if is_instance_valid(game_node):
				resume_game()
				get_tree().set_input_as_handled()

# Pauses game and makes menus visible
func show_menu() -> void:
	print("Showing menu")
	self.visible = true
	button_container.visible = true
	resume_button.visible = true
	game_node.visible = false
	game_node.set_process_input(false)
	set_process_input(true)
	get_tree().paused = true
	music_player.play_menu_music()

# Hides menu and unpauses game
func hide_menu() -> void:
	print("Hiding menu")
	self.visible = false
	get_tree().paused = false
	game_node.set_process_input(true)
	set_process_input(false)
	music_player.resume_track()

func fake_hide_menu() -> void:
	button_container.visible = false

func fake_show_menu() -> void:
	button_container.visible = true

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
	game_node.auto_stop_production = auto_stop_production
	game_node.skip_events = settings.get_setting("gameplay", "skip_events")
	game_node.skip_reports = settings.get_setting("gameplay", "skip_reports")
	get_parent().add_child(game_node)
	hide_menu()

# Shows settings menu, currently a stub
func show_settings() -> void:
	settings.visible = true
	fake_hide_menu()

# Plays credits
func show_credits() -> void:
	add_child(credits_scene.instance())
	fake_hide_menu()

# Exit the game
func quit_game() -> void:
	get_tree().quit()

func open_url(url):
	if !(url.begins_with("http://") || url.begins_with("https://")):
		url = "http://" + url
	print("Attempting to launch URL: ", url, " (", OS.shell_open(url), ")")

func load_version_number():
	var version_file = "res://version.txt"
	var file = File.new()
	if not file.file_exists(version_file):
		print("ERROR: Unable to load version")
		return
	file.open(version_file, file.READ)
	version_number = file.get_as_text().strip_edges()
	print("Running ", version_number)
	file.close()
