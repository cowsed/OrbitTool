extends Camera


onready var Focus = get_parent()
onready var lastFocusPos = get_parent().translation
var azimuth = 1
var inclination = 45

var mscalex = 0.01
var mscaley = 0.01

var min_zoom = 1

func _ready():
	move_cam(0,0)
	pass # Replace with function body.
func move_cam(dx,dy):
	var r = (translation - Focus.translation).length()
	azimuth+=-dx*mscalex
	inclination+=dy*mscaley
	var newPos:Vector3 = Vector3(r,0,0)#Vector3(r*cos(inclination)*sin(azimuth), r*sin(inclination)*sin(azimuth),r*cos(azimuth))
	newPos=newPos.rotated(Vector3(1,0,1).normalized(),inclination)

	newPos = newPos.rotated(Vector3(0,1,0),azimuth)
	newPos= newPos+Focus.translation
	
	translation = newPos
	
	look_at(Focus.translation, Vector3(0,1,0))
	pass

func _process(_delta):
	#Kinda hackish
	var delta = Focus.translation-lastFocusPos
	translation+=delta
	#look_at(Focus.translation, Vector3(0,1,0))
	
	lastFocusPos=Focus.translation

func SetFocus(b):
	#var off = translation-Focus.translation
	Focus = b
	move_cam(0,0)
	#translation+=off
	#look_at(Focus.translation, Vector3(0,1,0))
	
func set_zoom(delta: float):
	var r = (translation - Focus.translation).length()
	var dir = (translation + Focus.translation).normalized()
	if !r<min_zoom:
		r+=delta
	else:
		r=min_zoom
	translation = dir*(r)+Focus.translation

func set_zoom_r(r: float):
	var dir = (translation + Focus.translation).normalized()
	if r<min_zoom:
		r=min_zoom
	translation = dir*(r)




func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		set_zoom_r(10)
	if Input.is_action_just_released("zoom_in"):
		set_zoom(0.2)

	if Input.is_action_just_released("zoom_out"):
		set_zoom(-0.2)
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_cam"):
			move_cam(event.relative.x,event.relative.y)
	
