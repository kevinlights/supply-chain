extends Particles2D

var count = -1


func _ready():
	if count >= 1:
		set_amount(count)
	emitting = true

func _process(_delta):
	if !emitting:
		queue_free()
