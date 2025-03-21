extends VBoxContainer
class_name Shapekey_Slider

signal change_shapekeys (values:Dictionary)

var label_name : String
var shapekeys = [] #for lefts and rights

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label_Container/Label.text = label_name
	set_line_edit_from_slider_value()

func emit_shapekeys():
	var data = {}
	for shapekey_name in shapekeys:
		data[shapekey_name] = $Slider.value / 100	
	change_shapekeys.emit(data)

func set_line_edit_from_slider_value():
	$Label_Container/Value_Edit.text = str($Slider.value)
	
func set_value(value:int):
	$Slider.value = value

func slider_drag_ended(value_changed):
	set_line_edit_from_slider_value()
	emit_shapekeys()

func slider_value_changed(value):
	set_line_edit_from_slider_value()

func value_edit_text_submitted(new_text):
	if new_text.is_valid_float():
		var new_value = new_text.to_float()
		if new_value < $Slider.min_value:
			new_value = $Slider.min_value
		elif new_value > $Slider.max_value:
			new_value = $Slider.max_value
			
		$Slider.value = new_value
		emit_shapekeys()
	else:
		set_line_edit_from_slider_value()
