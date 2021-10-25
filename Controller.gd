extends Spatial

#Todo: 
#Convery all the textboxes to SpinBoxes
#Serialize Systems. im getting tired of typing - halfway done
#--- Figure out where the sysstem disagrees with reality, probably mass or distance scale? -- doesnt really, just keep your ratios of masses correct
# This is false, period calculation gets messed up because planets have very large masses
# also straighten out what the actual units are, it is confusing 
#Get the speeds right so it goes faster at periapsis
# billboard type things for AN, Peri, and Apo
#--- Notify all to recalculate when affecting change is made by other body ---
#--- Figure out why on entering the seen, a 2nd body gets SOI correct but when changed mid run, it gets the default error SOI---
#---More humane time warp  - kinda--- - is now exponential
#Add UI Safeguards
# if no or nonsense values are entered, stop that
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
onready var InfoUI = get_node("InfoDialog")
onready var SysOrig = get_node("SystemOrigin")
onready var Cam = get_node("SystemOrigin/CameraHolder")

var Bodies: Array
#Currently selected body
var Active = -1

var TreeTracker: Dictionary #[int]leaf

func _ready():
	MakeTree()
	UI.get_node("VBoxContainer/VSplit/Tree").connect("cell_selected", self, "TreeNodeSelected")
	
	
func _process(delta):
	if $ControlDialog.playing:
		Time+=delta*TimeMultiplier

func FindBodyIndex(b):
	for bi in Bodies.size():
		if b == Bodies[bi]:
			return bi
	return -1 

func BodyUpdated(ub):
	for b in Bodies:
		if b!=ub:
			b.UpdateSelf()

func BodySelected(b):
	print("Body ",b.name, " Selected")
	var bi=FindBodyIndex(b)
	if bi!=-1:
		Active=bi
		TreeTracker[bi].select(0)

	Cam.SetFocus(Bodies[Active])
	SetBodyStats()
	InfoUI.ViewBody=Bodies[Active]

func TreeNodeSelected():
	var leaf = UI.get_node("VBoxContainer/VSplit/Tree").get_selected()
	for k in TreeTracker:
		if TreeTracker[k] == leaf:
			Active=k
	Cam.SetFocus(Bodies[Active])
	SetBodyStats()
	InfoUI.ViewBody=Bodies[Active]
	
func AddBody(bname = "Body", a = 10, e = 0, br = 1000, bm=1, bParent = null, bcol = Color8(255,0,0,255))->Body:	
	var nb: Body = Body.new()
	nb.Controller=self
	
	if bParent==null:
		print_debug("Very Not Good")
		if Active>-1:
			nb.Parent = Bodies[Active]
		else:
			 nb.Parent = null
	else:
		print_debug("Very Good")
		nb.Parent = bParent
	nb.name=bname
	nb.SetRadius(br)
	nb.SetMass(bm)
	nb.SetSMA(a)
	nb.SetE(e)
	nb.Col=bcol
	
	nb.MakeOrbitRep()
	nb.GenerateMesh()
	nb.GenerateSOIMesh()
	
	if nb.Parent!=null:
		nb.Parent.add_child(nb)
	else:
		if len(Bodies)>0 and Active>-1:
			Bodies[Active].add_child(nb)
		else:
			SysOrig.add_child(nb)
	Bodies.append(nb)
	
	MakeTree()
	return nb
func SetBodyStats():
	var b: Body = Bodies[Active]
	var Stats = InfoUI.get_node("TabContainer/Controls")
	#Stats.show()
	Stats.get_node("HName/Name").text = b.name
	Stats.get_node("HSMA/SMA").value = b.SemiMajorAxis
	Stats.get_node("HEccentricity/Eccentricity").value = b.eccentricity
	Stats.get_node("HMass/Mass").value = b.Mass/(1e24)
	Stats.get_node("HRadius/Radius").value = b.Radius
	Stats.get_node("HPeriod/Period").value = b.Period
	Stats.get_node("HColor/ColorPickerButton").color=b.Col
	Stats.get_node("HSOI/SOI").value = b.CalcSOI()
	Stats.get_node("HLoan/Loan").value = rad2deg(b.loan)
	
func ClearBodyStats():
	
	var Stats = InfoUI.get_node("TabContainer/Controls")
	Stats.hide()
	Stats.get_node("HName/Name").text = ""
	Stats.get_node("HSMA/SemiMajorAxis").text = ""
	Stats.get_node("HEccentricity/Eccentricity").text = ""
	Stats.get_node("HMass/Mass").text = ""
	Stats.get_node("HRadius/Radius").text = ""
	Stats.get_node("HPeriod/Period").text = ""
	Stats.get_node("HColor/ColorPickerButton").color=Color8(0,0,0,255)
	Stats.get_node("HSOI/SOI").text=""


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
	MakeTree()
	SetBodyStats()

func _on_Period_value_changed(value):
	Bodies[Active].SetPeriod(value)
	SetBodyStats()


func _on_SMA_value_changed(value):
	print_debug("SMASet",value)
	Bodies[Active].SetSMA(value)
	SetBodyStats()


func _on_Ecc_value_changed(value):
	Bodies[Active].SetE(value)
	SetBodyStats()


func _on_Radius_value_changed(value):
	Bodies[Active].SetRadius(value)
	SetBodyStats()


func _on_Mass_value_changed(value):
	Bodies[Active].SetMass(value)
	SetBodyStats()


func _on_Loan_value_changed(value):
	Bodies[Active].SetLOAN(deg2rad(value))
	SetBodyStats()

func _on_ColorPickerButton_color_changed(color):
	Bodies[Active].SetCol(color)





func _on_LoadSystemButton_pressed():
	$LoadDialogue.popup()
	print_debug("Load System from file")

func _on_SaveSystemButton_pressed():
	$SaveDialogue.popup()
	print_debug("Save System to file")
	

func ClearSystem():
	Time=0
	TimeMultiplier=1
	_on_TimeSlider_value_changed(1)
	Cam.Focus=null
	InfoUI.ViewBody=null
	
	#Clear Old system
	Bodies.resize(0)
	for c in $SystemOrigin.get_children():
		if c.get_class()=="Body":
			$SystemOrigin.remove_child(c)
			c.queue_free()
	Active=-1
	
func _on_LoadDialogue_file_selected(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	var res: JSONParseResult = JSON.parse(content)
	if res.error!=OK:
		print("Error Loading, From old version?")
		return
	
	ClearSystem()
	#Decode New System
	DecodeFile(res.result)

func DecodeFile(result):
	if typeof(result) == TYPE_ARRAY:
		print("Good", len(result))
		for bRep in result:
			print(bRep, typeof(bRep)==TYPE_DICTIONARY)
			AddBodyFromDict(bRep)
	
func AddBodyFromDict(d, par=null) -> Body:
	var ecc=float(d["eccentricity"])
	var sma = float(d["semimajoraxis"])
	print_debug("Loaded Mass = ",float(d["mass"]))
	var mass = float(d["mass"])
	var loan = float(d["loan"])
	var new_name = d["name"]
	var rad = d["radius"]
	var col_rep = d["color"]
	var col: Color = Color(col_rep)
	var me = AddBody(new_name, sma, ecc, rad, mass, par, col)
	print_debug("In Node Mass = ",me.Mass)
	
	
	var kids=d["children"]
	if typeof(kids) == TYPE_ARRAY:
		for bRep in kids:
			print(bRep, typeof(bRep)==TYPE_DICTIONARY)
			AddBodyFromDict(bRep, me)
	return me
func _on_SaveDialogue_file_selected(path):
	print("save to ",path)
	var res="["
	for c in $SystemOrigin.get_children():
		if c.get_class()=="Body":
			res+=c.Jsonify()
			res+=","
	
	res=res.substr(0,res.length()-1) #Hacky way to remove trailing comma
	res+="]"
	print(res)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(res)
	file.close()


func _on_SOI_value_changed(value):
	#print_debug("Not Implemented")
	pass # Replace with function body.




func _on_Clear_pressed():
	ClearSystem()
	MakeTree()
	$InfoDialog.hidden=true
	$InfoDialog._on_ShowHide_pressed()
	$ControlDialog
