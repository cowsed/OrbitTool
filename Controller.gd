extends Spatial

#Todo: 
# Make body a scene? less instancing colliders and meshes in code
# Still have to do it for adding orbit
#Serialize Systems. im getting tired of typing
#More humane time warp
#Sets and gets on BodyStats
#Smooth Camera transitions

var Time: float = 0
var TimeMultiplier: float = 10
onready var UI = get_node("ControlDialog")
onready var SysOrig = get_node("SystemOrigin")
onready var Cam = get_node("SystemOrigin/Camera")

var Bodies: Array
#Currently selected body
var Active = -1

var TreeTracker: Dictionary #[int]leaf

func _ready():
	UI.popup()
	MakeTree()
	UI.get_node("VBoxContainer/Tree").connect("cell_selected", self, "TreeNodeSelected")
	
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
		print_debug("Valid Select")
		TreeTracker[bi].select(0)
	Cam.SetFocus(Bodies[Active])
	SetBodyStats()

func TreeNodeSelected():
	var leaf = UI.get_node("VBoxContainer/Tree").get_selected()
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
	var Stats = UI.get_node("VBoxContainer/BodyStats")
	Stats.get_node("HName/Name").text = b.name
	Stats.get_node("HSMA/SemiMajorAxis").text = str(b.SemiMajorAxis)
	Stats.get_node("HEccentricity/Eccentricity").text = str(b.eccentricity)
	Stats.get_node("HMass/Mass").text = str(b.Mass)
	Stats.get_node("HRadius/Radius").text = str(b.Radius)
	Stats.get_node("HPeriod/Period").text = str(b.Period)
	
func ClearBodyStats():
	var Stats = UI.get_node("VBoxContainer/BodyStats")
	Stats.get_node("HName/Name").text = ""
	Stats.get_node("HSMA/SemiMajorAxis").text = ""
	Stats.get_node("HEccentricity/Eccentricity").text = ""
	Stats.get_node("HMass/Mass").text = ""
	Stats.get_node("HRadius/Radius").text = ""
	Stats.get_node("HPeriod/Period").text = ""


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
	var tree= UI.get_node("VBoxContainer/Tree")
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	

	root.set_text(0,"Root")
	makeTree(SysOrig, root, tree)
	print(TreeTracker)

#	var child1 = tree.create_item(root)
#	child1.set_text(0, "A")
#
#
#	var child2 = tree.create_item(root)
#	child2.set_text(0, "B")
#
#	var subchild1 = tree.create_item(child1)
#	subchild1.set_text(0, "Subchild1")




func _on_TimeSlider_value_changed(value):
	TimeMultiplier=value
	UI.get_node("VBoxContainer/TimeWarpLabel").text="Time Scale: "+str(TimeMultiplier)
	pass # Replace with function body.
