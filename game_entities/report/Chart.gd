extends HBoxContainer

var data := {}
var chart : ColorRect
var colours := {
		"opening_stock": Color.yellow,
		"stock_in": Color.green,
		"stock_out": Color.blue,
		"closing_stock": Color.aqua,
		"waste": Color.red,
		"ticks_at_min": Color.yellow,
		"ticks_at_max": Color.purple,
		"ticks_no_produce": Color.orange,
		"ticks_no_consume": Color.red,
		"transit_time": Color.orange,
	}
var padding = Vector2(10, 10)
var min_v_scale = 5
var max_datum_count := 20
var series_offset_step := 2
var use_series_offset := true
var label_font = preload("res://fonts/report_value.tres")

func _ready() -> void:
	chart = get_node("VBoxContainer/ChartArea")
	chart.connect("draw", self, "draw_chart")

func set_data(new_data, is_producing, is_consuming) -> void:
	data = new_data
	if !is_producing:
		data.erase("ticks_no_produce")
	if !is_consuming:
		data.erase("ticks_no_consume")
	get_node("VBoxContainer/Label").set_text(PoolStringArray(data.keys()).join(", "))

func draw_chart() -> void:
	var max_value = min_v_scale
	for series in data:
		var smax = data[series].max()
		if smax > max_value:
			max_value = smax

	var scale = (chart.get_size() - padding * 2) / Vector2(max_datum_count, 1)

	#Draw axis lines
	chart.draw_line(padding - Vector2(2, 2), Vector2(padding.x - 2, scale.y + padding.y + 2), Color.black)
	chart.draw_line(Vector2(padding.x - 3, scale.y + padding.y + 2), Vector2(chart.get_size().x - padding.x + 2, scale.y + padding.y + 2), Color.black)

	#Draw tickmarks and labels
	#TODO: Work out appropriate rounding so that 3 - 4 vertical tickmarks can be shown comfortably
	chart.draw_line(Vector2(padding.x - 3, scale.y + padding.y + 2), Vector2(padding.x - 6, scale.y + padding.y + 2), Color.black)
	chart.draw_string(label_font, Vector2(padding.x - 8, scale.y + padding.y + 2) + (label_font.get_string_size("0") * Vector2(-1, 0.25)), "0", Color.black)

	chart.draw_line(Vector2(padding.x - 3, 0 + padding.y), Vector2(padding.x - 6, 0 + padding.y), Color.black)
	chart.draw_string(label_font, Vector2(padding.x - 8 , 0 + padding.y + 2) + (label_font.get_string_size(String(max_value)) * Vector2(-1, 0.25)), String(max_value), Color.black)

	#TODO: Draw horizontal labels

	#Plot data
	var series_offset = 0
	for series in data:
		var points = PoolVector2Array()
		for i in range(0, data[series].size()):
			var temp_value = 0
			if !is_equal_approx(data[series][i], 0.0):
				temp_value = scale.y / (max_value / abs(data[series][i]))

			points.append(padding + Vector2(i * scale.x, scale.y - temp_value + (series_offset if use_series_offset else 0)))

			#If there's only one data point, double it so that we have something to look at
			if data[series].size() == 1:
				points.append(padding + Vector2(i + 1 * scale.x, scale.y - temp_value + (series_offset if use_series_offset else 0)))

		for i in range(0, points.size() - 1):
			chart.draw_line(points[i], points[i + 1], Color(0, 0, 0, 1) if !(series in colours) else colours[series], 2.0, false)

		series_offset -= series_offset_step
