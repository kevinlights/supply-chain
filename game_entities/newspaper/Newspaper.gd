extends Control

var animationTween : Tween
var is_preview = false

# Pause the game and play the newspaper animation
func _ready():
	get_tree().paused = true
	animationTween = Tween.new()
	add_child(animationTween)
	animationTween.interpolate_method(self, "set_rotation", -TAU * 3, 0, 0.75, Tween.TRANS_SINE, Tween.EASE_OUT)
	animationTween.interpolate_method(self, "set_scale", Vector2(0.0001, 0.0001), Vector2(1, 1), 0.6, Tween.TRANS_SINE, Tween.EASE_OUT)
	animationTween.start()

func set_title(value : String):
	get_node("Paper/Content/TitleContent/Title").set_text(value)

func set_date(value : String):
	get_node("Paper/Content/TitleContent/HBoxContainer/Date").set_text(value)

# Populate paper with event details
func set_event(event : Dictionary):
	if "headline" in event:
		get_node("Paper/Content/TitleContent/Headline").set_text(event["headline"].to_upper())
	if "image" in event:
		var imagePath = "res://game_entities/newspaper/images/" + event["image"]
		if ResourceLoader.exists(imagePath):
			get_node("Paper/Content/PaperContent/Center/PhotoFrame/Photo").texture = load(imagePath)
		else:
			#TODO: Set a default image
			get_node("Paper/Content/PaperContent/Center/PhotoFrame/Photo").texture = null
			pass

# Close on player input only if the paper has finished its animation
func _process(_delta):
	if Input.is_action_just_released("ui_select") ||  Input.is_action_just_released("ui_accept") ||  Input.is_action_just_released("ui_cancel"):
		if !animationTween.is_active():
			close()

# Unpause the game and remove the paper
func close():
	if !is_preview:
		get_tree().paused = false
		get_parent().set_process(true)
	queue_free()
