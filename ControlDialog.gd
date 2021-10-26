extends Panel

onready var SysController = get_parent()
onready var Adder = get_parent().get_node("AdderDialogue")

var playing=true

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
	var loan=0
	SysController.AddBody(
		Name,
		a,
		e,
		r,
		m,
		loan,
		null, 
		c
		)
	Adder.hide()


func _on_PauseButton_pressed():
	if playing:
		playing=false
		$VBoxContainer/PauseButton.text="Play"
	else:
		playing=true
		$VBoxContainer/PauseButton.text="Pause"


func _on_RewindButton_toggled(button_pressed):
	if button_pressed:
		SysController.TimeReverser=-1
	else:
		SysController.TimeReverser=1
