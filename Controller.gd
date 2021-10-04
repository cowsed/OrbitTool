extends Spatial

#Todo: 
#Serialize Systems. im getting tired of typing
#Figure out where the sysstem disagrees with reality, probably mass or distance scale?
#Get the speeds right so it goes faster at periapsis
# billboard type things for AN, Peri, and Apo
#Notify all to recalculate when affecting change is made by other body
#Figure out why on entering the seen, a 2nd body gets SOI correct but when changed mid run, it gets the default error SOI
#More humane time warp  - kinda

#Completed
#---Sets and gets on BodyStats---
#---Smooth Camera transitions---
#  ---Don't work on layers deeper than 1. ie sun->moon->craft focusing on craft will focus on place it would be if it had same characteristics but was childed to the sun---

#Maybe:
# Make body a scene? less instancing colliders and meshes in code
# Still have to do it for adding orbit


var Time: float = 0
var TimeMultiplier: float = 10
onready var UI = get_node("ControlDialog")
onready var SysOrig = get_node("SystemOrigin")
onready var Cam = get_node("SystemOrigin/CameraHolder")

var Bodies: Array
#Currently selected body
var Active = -1

var TreeTracker: Dictionary #[int]leaf

func _ready():
	UI.popup()
	MakeTree()
	UI.get_node("VBoxContainer/VSplit/Tree").connect("cell_selected", self, "TreeNodeSelected")
	
func _process(delta):
	Time+=delta*TimeMultiplier

func FindBodyIndex(b):
	for bi in Bodies.size():
		if b == Bodies[bi]:
			return bi
	return -1 

func BodySelected(b):
	print(b.name)
	var bi=FindBodyIndex(b)
	if bi!=-1:
		Active=bi
		TreeTracker[bi].select(0)
	#Cam.SetFocus(Bodies[Active])  #Dont set focus again here or else lerp is broken, this is because Tree.select triggers the other selection function which sets old target ot what is now the new targe
	SetBodyStats()

func TreeNodeSelected():
	var leaf = UI.get_node("VBoxContainer/VSplit/Tree").get_selected()
	for k in TreeTracker:
		if TreeTracker[k] == leaf:
			Active=k
	Cam.SetFocus(Bodies[Active])
	SetBodyStats()
	
	
func AddBody(bname = "Body", a = 10, e = 0, br = 1000, bm=1000,  bcol = Color8(255,0,0,255)):	
	var nb: Body = Body.new()
	nb.Controller=self
	if Active>-1:
		nb.Parent = Bodies[Active]
	else:
		 nb.Parent = null
	
	nb.name=bname
	nb.Radius=br
	nb.Mass=bm
	nb.SetSMA(a)
	nb.eccentricity=e
	nb.Col=bcol
	
	nb.MakeOrbitRep()
	nb.GenerateMesh()
	nb.GenerateSOIMesh()
	
	
	if len(Bodies)>0 and Active>-1:
		Bodies[Active].add_child(nb)
	else:
		SysOrig.add_child(nb)
	Bodies.append(nb)
	
	MakeTree()

func SetBodyStats():
	var b: Body = Bodies[Active]
	var Stats = UI.get_node("VBoxContainer/VSplit/BodyStats")
	Stats.get_node("HName/Name").text = b.name
	Stats.get_node("HSMA/SemiMajorAxis").text = str(b.SemiMajorAxis)
	Stats.get_node("HEccentricity/Eccentricity").text = str(b.eccentricity)
	Stats.get_node("HMass/Mass").text = str(b.Mass)
	Stats.get_node("HRadius/Radius").text = str(b.Radius)
	Stats.get_node("HPeriod/Period").text = str(b.Period)
	Stats.get_node("HColor/ColorPickerButton").color=b.Col
	
func ClearBodyStats():
	var Stats = UI.get_node("VBoxContainer/VSplit/BodyStats")
	Stats.get_node("HName/Name").text = ""
	Stats.get_node("HSMA/SemiMajorAxis").text = ""
	Stats.get_node("HEccentricity/Eccentricity").text = ""
	Stats.get_node("HMass/Mass").text = ""
	Stats.get_node("HRadius/Radius").text = ""
	Stats.get_node("HPeriod/Period").text = ""
	Stats.get_node("HColor/ColorPickerButton").color=Color8(0,0,0,255)


func makeTree(body, tree_root, tree):
	#add
	for c in body.get_children():
		if c.get_class()=="Body":
			var leaf = tree.create_item(tree_root)
			TreeTracker[FindBodyIndex(c)]=leaf
			leaf.set_text(0,c.name)
			leaf.set_selectable(0,true)
			makeTree(c, leaf, tree)

func MakeTree():
	var tree= UI.get_node("VBoxContainer/VSplit/Tree")
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	

	root.set_text(0,"Root")
	makeTree(SysOrig, root, tree)
	print(TreeTracker)


func _on_TimeSlider_value_changed(value):
	TimeMultiplier=value
	var descString = ""
	if TimeMultiplier<60.0:
		descString = str(TimeMultiplier)+" Sec/RealSec"
	elif TimeMultiplier<60.0*60:
		descString = str(TimeMultiplier/60)+" min/RealSec"
	elif TimeMultiplier<60.0*60*24:
		descString = str(TimeMultiplier/(60*60))+" hour/RealSec"
	else:
		descString = str(TimeMultiplier/(24*60*60))+" days/RealSec"

	UI.get_node("VBoxContainer/TimeWarpLabel").text="Time Scale: "+descString
	pass # Replace with function body.

#34.65 sec for one rev
#5.1667 days per sec
#period 2419200
# should be near one month
func _on_Name_text_entered(new_text):
	Bodies[Active].name=new_text
	SetBodyStats()

func _on_SemiMajorAxis_text_entered(new_text):
	Bodies[Active].SetSMA(float(new_text))
	SetBodyStats()


func _on_Eccentricity_text_entered(new_text):
	Bodies[Active].SetE(float(new_text))
	SetBodyStats()

func _on_Radius_text_entered(new_text):
	Bodies[Active].SetRadius(float(new_text))
	SetBodyStats()

func _on_Mass_text_entered(new_text):
	Bodies[Active].SetMass(float(new_text))
	SetBodyStats()

func _on_Period_text_entered(new_text):
	Bodies[Active].SetPeriod(float(new_text))
	SetBodyStats()

func _on_ColorPickerButton_color_changed(color):
	Bodies[Active].SetCol(color)


func _on_Loan_text_entered(new_text):
	Bodies[Active].SetLOAN(float(new_text))
