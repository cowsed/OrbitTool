extends Spatial

var mscalex: float = -0.002
var mscaley: float = -0.002
var zoom_amt: float = 1.4

var Focus: Node
var PrevFocusTrans: Vector3

var OldZoom: float = 1
var OldFocusPos: Vector3
var lerp_amt: float = 1
var lerp_speed: float = 0.05

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_cam"):
			move_cam(event.relative.x,event.relative.y)
	if Input.is_action_just_released("zoom_in"):
		$CameraHolder2/Camera.translation.z-=zoom_amt
	if Input.is_action_just_released("zoom_out"):
		$CameraHolder2/Camera.translation.z+=zoom_amt
			
func move_cam(dx,dy):
	rotation.y+=dx*mscalex
	$CameraHolder2.rotation.x+=dy*mscaley
	
func SetFocus(b):
	if lerp_amt<1:
		#Already Lerping, dont re set focus
		#DB Possibility, focus pos and active body getting out of sync
		pass
	lerp_amt=0
	
	if Focus!=null:
		OldFocusPos=Focus.get_global_transform().origin
		OldZoom=$CameraHolder2/Camera.translation.z
	else:
		OldFocusPos=Vector3()

	Focus = b

	PrevFocusTrans=Focus.get_global_transform().origin


func _process(_delta):
	if Focus!=null:
		var diff = Focus.get_global_transform().origin-PrevFocusTrans
		
		translation+=diff
		PrevFocusTrans=Focus.get_global_transform().origin
	if lerp_amt<1:
		#print("lerping from: ",OldFocusPos, " to ",Focus.translation)
		lerp_amt+=lerp_speed
		translation=lerp(OldFocusPos,Focus.get_global_transform().origin,lerp_amt)
		$CameraHolder2/Camera.translation.z=lerp(OldZoom,Focus.Radius*5*Focus.DistanceScale,lerp_amt)
