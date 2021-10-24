extends Panel

onready var SysController = get_parent()
onready var Adder = get_parent().get_node("AdderDialogue")
func _ready():
	pass












func _on_AddBodyButton_pressed():
	Adder.popup_centered(Vector2(get_viewport().size.x/2.0,0))


func _on_CancelButton_pressed():
	Adder.hide()


func _on_ConfirmButton_pressed():
	var Name = Adder.get_node("ParameterHolder/BodyName").text
	var a = float(Adder.get_node("ParameterHolder/SemiMajorAxis").text)
	var e = float(Adder.get_node("ParameterHolder/Eccentricity").text)
	var r = float(Adder.get_node("ParameterHolder/Radius").text)
	var m = float(Adder.get_node("ParameterHolder/Mass").text)
	var c = Adder.get_node("ParameterHolder/HBoxContainer/ColorPickerButton").color
	SysController.AddBody(
		Name,
		a,
		e,
		r,
		m,
		null, 
		c
		)
	Adder.hide()
