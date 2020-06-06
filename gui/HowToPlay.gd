extends Control


func _ready() -> void:
	get_node("Back").connect("pressed", self, "close")

func close() -> void:
	get_parent().fake_show_menu()
	queue_free()
