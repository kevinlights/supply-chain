extends AudioStreamPlayer

var playlist := []
var menu_music := preload("res://music/supplytitle.ogg")
var music_path := "res://music/tracks/"
var current_track_index : int = -1
var paused_track_time := 0.0
var track_gap := 2.0
var gap_timer : Timer

func _ready():
	connect("finished", self, "handle_track_end")
	gap_timer = get_node("GapTimer")
	gap_timer.connect("timeout", self, "play_track")
	gap_timer.set_wait_time(track_gap)
	gap_timer.set_one_shot(true)

func assemble_playlist(path := music_path) -> void:
	var file_names := []
	var music_folder = Directory.new()
	if music_folder.open(path) == OK:
		music_folder.list_dir_begin()
		var file_name = music_folder.get_next()
		while file_name != "":
			if !music_folder.current_is_dir():
				if file_name.ends_with(".ogg.import"):
					file_name = file_name.substr(0, file_name.length() - 7)
				if file_name.ends_with(".ogg"):
					if !(file_name in file_names):
						file_names.append(file_name)
			file_name = music_folder.get_next()
	playlist.clear()
	for file_name in file_names:
		playlist.append(load(music_path + file_name))
		playlist.back().set_loop(false)
	playlist.shuffle()

	current_track_index = -1
	paused_track_time = 0

func handle_music_end() -> void:
	pass

func pause_track() -> void:
	paused_track_time = get_playback_position()
	stop()

func play_track(track_index := current_track_index, start_time := 0.0) -> void:
	if playlist.size() <= 0:
		printerr("Trying to play music from an empty playlist!")
		gap_timer.start()
		return

	if track_index < 0:
		track_index = randi() % playlist.size()
	elif track_index >= playlist.size():
		track_index = 0

		#If shuffling is desired, make sure the first track in the newly shuffled list isn't the last track we played
#		var temp = playlist.back().get_path()
#		playlist.shuffle()
#		if playlist[0].get_path() == temp:
#			playlist.push_back(playlist.pop_front())

	#print("Playing music track ", playlist[track_index].get_path(), "" if start_time <= 0 else " at " + String(start_time))
	set_stream(playlist[track_index])
	current_track_index = track_index

	if start_time < 0:
		start_time = fmod(randf(), stream.get_length())
	if start_time > 0:
		play(start_time)
	else:
		play()

func handle_track_end():
	current_track_index += 1
	gap_timer.start()

func resume_track():
	play_track(current_track_index, paused_track_time)

func play_menu_music():
	if is_instance_valid(gap_timer):
		if !gap_timer.is_stopped():
			gap_timer.stop()
			current_track_index = -1
	pause_track()
	set_stream(menu_music)
	play()
	#print("Playing menu music: ", menu_music.get_path())
