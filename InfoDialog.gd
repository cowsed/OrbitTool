extends Panel


onready var ViewBody: Body = null
onready var Controller = get_parent()


onready var width = rect_size.x

var hidden = true

func _ready():
	hidden=true
	$TabContainer.visible=false	
	$ShowHide.text="Show Stats"
	$ShowHide.rect_size.x=width/4
	rect_size.x=0


func _process(delta):
	if ViewBody!=null:
		$TabContainer/Stats/NameLabel.text=ViewBody.name
		var v = ViewBody.VelAt(Controller.Time)
		$TabContainer/Stats/SpeedLabel.text="Speed: "+str(v.length()/1000)+" km/s"
		$TabContainer/Stats/Velocity/x.value=v.x/1000
		$TabContainer/Stats/Velocity/z.value=v.y/1000
		$TabContainer/Stats/Velocity/z.value=v.z/1000
		var h = ViewBody.HeightAt(Controller.Time)
		$TabContainer/Stats/HeightLabel.text = "Height: "+str(h/1000)+" km"
		


func _on_ShowHide_pressed():
	if ViewBody==null:
		hidden=true
		$TabContainer.visible=false
		$ShowHide.text="Show Stats"
		$ShowHide.rect_size.x=width/4
		rect_size.x=0

		return

	if hidden==true:
		hidden=false
		$TabContainer.visible=true
		$ShowHide.text="Hide Stats"
		$ShowHide.rect_size.x=width
		rect_size.x=width
	else:
		hidden=true
		$TabContainer.visible=false
		$ShowHide.text="Show Stats"
		$ShowHide.rect_size.x=width/4
		rect_size.x=0
