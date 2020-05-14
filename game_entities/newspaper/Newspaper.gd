extends Control

var animationTween : Tween

func _ready():
	get_tree().paused = true
	animationTween = Tween.new()
	add_child(animationTween)
	animationTween.interpolate_method(self, "set_rotation", -TAU * 3, 0, 0.75, Tween.TRANS_SINE, Tween.EASE_OUT)
	animationTween.interpolate_method(self, "set_scale", Vector2(0.0001, 0.0001), Vector2(1, 1), 0.6, Tween.TRANS_SINE, Tween.EASE_OUT)
	animationTween.start()

func set_event(event : Dictionary):
	if "headline" in event:
		get_node("Paper/TitleContent/Headline").set_text(event["headline"].to_upper())
	if "image" in event:
		var imagePath = "game_entities/newspaper/" + event["image"]
		if ResourceLoader.exists(imagePath):
			get_node("Paper/PaperContent/Center/PhotoFrame/Photo").texture = load(imagePath)
		else:
			#TODO: Set a default image
			get_node("Paper/PaperContent/Center/PhotoFrame/Photo").texture = null
			pass

func _process(_delta):
	if Input.is_action_just_released("ui_select"):
		close()

func close():
	get_tree().paused = false
	get_parent().set_process(true)
	queue_free()