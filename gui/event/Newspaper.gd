extends Control

var animation_tween : Tween
var is_preview = false

# Pause the game and play the newspaper animation
func _ready() -> void:
	get_tree().paused = true
	get_parent().set_process(false)
	animation_tween = Tween.new()
	add_child(animation_tween)
	animation_tween.interpolate_method(self, "set_rotation", -TAU * 3, 0, 0.75, Tween.TRANS_SINE, Tween.EASE_OUT)
	animation_tween.interpolate_method(self, "set_scale", Vector2(0.0001, 0.0001), Vector2(1, 1), 0.6, Tween.TRANS_SINE, Tween.EASE_OUT)
	animation_tween.start()

	connect("gui_input", self, "handle_input")

func set_title(value : String):
	get_node("Paper/Content/TitleContent/Title").set_text(value)

func set_date(value : String):
	get_node("Paper/Content/TitleContent/HBoxContainer/Date").set_text(value)

# Populate paper with event details
func set_event(event : Dictionary):
	if "headline" in event:
		get_node("Paper/Content/TitleContent/Headline").set_text(event["headline"].to_upper())
	if "subheading" in event:
		get_node("Paper/Content/TitleContent/Subheading").visible = true
		get_node("Paper/Content/TitleContent/Subheading").set_text(event["subheading"])
	if "image" in event:
		var imagePath = "res://gui/event/images/" + event["image"]
		if ResourceLoader.exists(imagePath):
			get_node("Paper/Content/PaperContent/Center/PhotoFrame/Photo").texture = load(imagePath)
		else:
			#TODO: Set a default image
			get_node("Paper/Content/PaperContent/Center/PhotoFrame/Photo").texture = null
			pass

	#FIXME: Remove column lines if they spill over the page height (rect_clip_content doesn't work properly hen rotated)

# Close on player input only if the paper has finished its animation
func _process(_delta : float) -> void:
	if Input.is_action_just_released("ui_cancel"):
		if !animation_tween.is_active():
			close()

func handle_input(event):
	if event is InputEventKey || event is InputEventMouseButton || event is InputEventJoypadButton:
		if event.is_action("ui_select") ||  event.is_action("ui_accept"):
			close()
			get_tree().set_input_as_handled()

# Unpause the game and remove the paper
func close() -> void:
	if !is_preview:
		get_tree().paused = false
		get_parent().set_process(true)
	queue_free()
