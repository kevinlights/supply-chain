extends HBoxContainer

var label_font = preload("res://fonts/chart_label.tres")
var legend_font = preload("res://fonts/legend_font.tres")
var chart : ColorRect
var toggles := {}
var data := {}
var colours = [ #category10 from d3.js
		Color("1474b3"),
		Color("ff7e00"),
		Color("24a133"),
		Color("d92722"),
		Color("9462bb"),
		Color("8d564b"),
		Color("e572bf"),
		Color("bbbe26"),
		Color("00bdcf"),
	]
var colours_okabe_ito = [ #from http://jfly.uni-koeln.de/color/
		Color(0.90, 0.60, 0.0),
		Color(0.35, 0.70, 0.90),
		Color(0.00, 0.60, 0.50),
		Color(0.95, 0.90, 0.25),
		Color(0.00, 0.45, 0.70),
		Color(0.80, 0.40, 0.00),
		Color(0.80, 0.60, 0.70),
	]
var datum_colours := {
		"stock_in": colours[0],
		"production": colours[0],
		"stock_out": colours[2],
		"consumption": colours[2],
		"waste": colours[3],
		"opening_stock": colours[6],
		"closing_stock": colours[4],
		"time_empty": colours[0],
		"time_full": colours[1],
		"unable_to_produce": colours[3],
		"unable_to_consume": colours[3],
		"transit_efficiency": colours[0],
	}

var padding = Vector2(10, 10)
var scale = Vector2(1, 1)
var min_v_scale = 5
var max_value : float = min_v_scale
var datum_count := 0
var max_datum_count := 20
var datum_offset := 0
var series_offset_step := 2
var use_series_offset := true
var line_width := 2.0

func _ready() -> void:
	chart = get_node("VBoxContainer/ChartArea")
	chart.connect("draw", self, "draw_chart")

func set_data(new_data, offset, is_producing, is_consuming) -> void:
	data = new_data
	datum_offset = offset

	if is_producing:
		if "stock_in" in data:
			data["production"] = data["stock_in"]
			data.erase("stock_in")
	else:
		data.erase("unable_to_produce")
	if is_consuming:
		if "stock_out" in data:
			data["consumption"] = data["stock_out"]
			data.erase("stock_out")
	else:
		data.erase("unable_to_consume")

	for series in datum_colours.keys():
		if series in data:
			var widget := CheckBox.new()
			widget.set_text(series.capitalize())
			widget.add_font_override("font", legend_font)
			widget.add_color_override("font_color", datum_colours[series])
			widget.add_color_override("font_color_hover", datum_colours[series])
			widget.add_color_override("font_color_pressed", datum_colours[series])
			widget.pressed = true
			widget.connect("pressed", get_node("VBoxContainer/ChartArea"), "update")
			get_node("VBoxContainer/HBoxContainer").add_child(widget)
			toggles[series] = widget
	get_node("VBoxContainer/Label").set_text(PoolStringArray(data.keys()).join(", "))

	for series in data:
		datum_count = data[series].size()
		var smax = max(data[series].max(), abs(data[series].min()))
		if smax > max_value:
			max_value = smax

	datum_count = int(max(2, datum_count)) #Make sure that we label the 0th period "1" for the first report
	if datum_offset > max_datum_count:
		datum_offset = datum_offset - max_datum_count
	else:
		datum_offset = 0

func draw_chart(_temp = "") -> void:
	scale = (chart.get_size() - padding * 2) / Vector2(max_datum_count, 1)

	#Draw axis lines
	chart.draw_line(padding - Vector2(2, 2), padding + Vector2(-2, scale.y + 2), Color.black)
	chart.draw_line(padding + Vector2(-3, scale.y + 2), (padding * Vector2(-1, 1)) + Vector2(chart.get_size().x, scale.y + 2), Color.black)

	#Draw tickmarks and labels
	#TODO: Work out appropriate rounding so that 3 - 4 vertical tickmarks can be shown comfortably
	chart.draw_line(padding + Vector2(-3, scale.y + 2), padding + Vector2(-6, scale.y + 2), Color.black)
	chart.draw_string(label_font, padding + Vector2(-8, scale.y + 2) + (label_font.get_string_size("0") * Vector2(-1, 0.25)), "0", Color.black)

	chart.draw_line(padding + Vector2(-3, 0), padding + Vector2(-6, 0), Color.black)
	chart.draw_string(label_font, padding + Vector2(-8 , 0 + 2) + (label_font.get_string_size(String(max_value)) * Vector2(-1, 0.25)), String(max_value), Color.black)

	#Draw horizontal tickmarks and labels
	for i in range(0, max_datum_count + 1):
		chart.draw_line(padding + Vector2(i * scale.x, scale.y + 2), padding + Vector2(i * scale.x, scale.y + 7), Color.black)
		if i < datum_count - 1:
			chart.draw_string(label_font, padding + Vector2(i * scale.x + (scale.x * 0.5), scale.y + 2) + (label_font.get_string_size(String(datum_offset + i + 1)) * Vector2(-0.5, 1)), String(datum_offset + i + 1), Color.black)

	#Plot data
	var series_offset = 0

	for series in datum_colours.keys():
		if !(series in data):
			continue
		if toggles[series].pressed:
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
				chart.draw_line(points[i], points[i + 1], Color(0, 0, 0, 1) if !(series in datum_colours) else datum_colours[series], line_width, false)
		series_offset -= series_offset_step
