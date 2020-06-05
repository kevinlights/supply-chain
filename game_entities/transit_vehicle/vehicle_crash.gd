extends TextureRect

var fade_tween : Tween
var fade_duration = 5.0

func _ready() -> void:
	fade_tween = Tween.new()
	add_child(fade_tween)
	fade_tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), fade_duration, Tween.TRANS_SINE, Tween.EASE_IN)
	fade_tween.connect("tween_completed", self, "remove")
	fade_tween.start()

func remove(_object, _property) ->void:
	queue_free()
