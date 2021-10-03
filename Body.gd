extends MeshInstance

class_name Body, "Body.svg"


export(float) var Mass: float = 5.9e12  setget SetMass# #In kgs Mass of the Body
#export var MassScale = 1e12  #Mass*MassScale = actual Mass

export(float) var Radius: float = 1000 #In KM, the radius of the body

export(bool) var IsStar = false 
export(float) var Period = 1
export(Color, RGBA) var Col 

export var SemiMajorAxis: float = 10 
export(float,0,1) var eccentricity: float = .0
export var loan: float = 0.0  #longitude of ascending node
export var offsettAng = 0.0
export var ShowOrbit = true 
export var Static = true #if true, is a planet, if false, can be influenced and enter other spheres of influence
 
export var focus = false setget SetFocus
onready var Controller = get_tree().root.get_node("Spatial")

const DistanceScale = 0.001 #KM to scene units
const OUTERSOI = 1_000_000 #the size for an unconstrained? soi 

onready var Parent= null #get_parent()
var IsOuter = false

func is_type(type): return type == "Body" or .is_type(type)
func    get_type(): return "Body"
func get_class(): return "Body"

var OrbitRep = Line3D.new()
var SOIRep = MeshInstance.new()
var Clicker = Area.new()
var ClickerSphere = CollisionShape.new()

signal SelfSelected(s)

func _ready():
	OrbitRep.set_name(name+"-OrbitRepresentation")
	get_parent().call_deferred("add_child",OrbitRep)
	
	SOIRep.set_name(name+"-SOIRepresentation")
	add_child(SOIRep)
	Clicker.set_name(name+"-Area")
	ClickerSphere.set_name(name+"-Sphere")	
	Clicker.add_child(ClickerSphere)
	#connect clicker to signal
	add_child(Clicker)
	Clicker.connect("input_event", self, "wasClicked")
	
	self.connect("SelfSelected", Controller,"BodySelected")
	print(Controller)

func wasClicked(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			emit_signal("SelfSelected",self)
			
	

func CalcVelocityAt(r: float):

	var parentMass = 0
	if Parent.get_class() == "Body":
		parentMass=Parent.Mass
	#print("ParentMass",parentMass)
	#print("A",SemiMajorAxis)
	var G: float = 6.67e-11
	#print("G-%.15f"%G)
	#print("r",r)
	var a = SemiMajorAxis

	if r==0 or a==0:
		return 0

	return sqrt(G*parentMass*((2/r)-(1/a)))
func calcB():
	var e = eccentricity
	var a = SemiMajorAxis
	return a*sqrt(1-pow(e,2))
func AtPos(t: float):
	var a=SemiMajorAxis
	#var b=calcB()
	var e = eccentricity
	var v = t/Period+offsettAng
	var p#: Vector3 = Vector3(cos(v)*a,0,sin(v)*b)
	var r = (a* (1-pow(e,2))  /  (1+e*cos(v)))
	p=Vector3(cos(v)*r, 0, sin(v)*r)
	#p-=translation
	#p=p.rotate_z(loan)
	p=p.rotated(Vector3(0,1,0),loan)
	#p+=translation

	return p

func MakeOrbitRep():
	if OrbitRep==null:
		OrbitRep=Line3D.new()
		
	OrbitRep.ClearOrbit()
	var res=.01;
	var t=0
	while t<2*PI:
		var p = AtPos(t*Period+offsettAng)
		#add p to line
		OrbitRep.AddPoint(p)
		t+=res
	OrbitRep.MakeMesh()


# Called when the node enters the scene tree for the first time.


func CalcSOI():
	if Parent==null:
		print("ow",name)
		return OUTERSOI
		
	if !IsOuter:
		print("is Body")
		var parentMass: float=Parent.Mass
		print(Mass,"/",parentMass,"=",Mass/parentMass)
		#var parentMassScale = get_parent().MassScale
		print_debug("SOI=",SemiMajorAxis*pow(Mass/parentMass, 2.0/5.0)/DistanceScale)
		return SemiMajorAxis*pow(Mass/parentMass, 2.0/5.0)/DistanceScale
	else:
		print("IS NOT BODY",Parent, "-", IsOuter,"-", name)
		return OUTERSOI #100 thousand KM

func GenerateSOIMesh():
	SOIRep.mesh=SphereMesh.new()
	SOIRep.mesh.material = SpatialMaterial.new()
	SOIRep.mesh.material.flags_transparent=true

	SOIRep.mesh.material.albedo_color.a=.1
	SetSOIMesh()
	
func SetSOIMesh():
	if SOIRep.mesh==null:
		SOIRep.mesh=SphereMesh.new()
	var r: float
	if !IsOuter:
		r = CalcSOI()
	else:
		r=OUTERSOI
	#print_debug(r,"ds",DistanceScale)
	SOIRep.mesh.radius=r*DistanceScale
	SOIRep.mesh.height=2*SOIRep.mesh.radius


		
func _process(_delta):
	#if Controller==null:
		
		
	if Parent==null:
		print_debug("Problematic")
		Parent=get_parent()
		print_debug(Parent.get_class())
		if Parent.get_class()!="MeshInstance":
			IsOuter=true
		else:
			IsOuter=false
	if SOIRep.mesh==null:
		GenerateSOIMesh()

	var RelativePos
	if Controller==null:
		RelativePos=AtPos(0)
	else:
		RelativePos=AtPos(Controller.Time)
		
	#RelativePos.x=cos(time*Period)*SemiMajorAxis
	#RelativePos.z=sin(time*Period)*SemiMajorAxis
	
	if not Parent==null:
		global_transform.origin=Parent.global_transform.origin+RelativePos
	
	
func GenerateMesh():
	mesh=SphereMesh.new()
	mesh.material = SpatialMaterial.new()
	ClickerSphere.shape = SphereShape.new()
	SetMesh()
	SetMaterial()

	
func SetMesh():
	mesh.radius=Radius*DistanceScale
	mesh.height=2*mesh.radius
	
	if ClickerSphere.shape!=null:
		print(ClickerSphere.shape)
		ClickerSphere.shape.radius = mesh.radius


func SetMaterial():
	var cs = get_children()
	var light
	var add_light=false
	for n in cs:
		if n is OmniLight:
			light = n
			if not IsStar:
				n.free()
	if light==null and IsStar:
		light=OmniLight.new()
		add_light=true
	if IsStar:
		mesh.material.emission_enabled=true
		mesh.material.emission_energy=3.0
		mesh.material.emission=Col
		light.light_color=Col
		light.light_energy=1.0
		light.omni_range=48.0
	else:
		mesh.material.emission_enabled=false
		mesh.material.emission_energy=0.0
		
	if add_light:
		light.set_name(name+"-Light")
		add_child(light)
	mesh.material.albedo_color=Col


func SetFocus(nf):
	focus=nf
	mesh.material.flags_no_depth_test=focus
	mesh.material.flags_unshaded=focus
func SetMass(nm):
	Mass=nm#*MassScale
	if Parent!=null:
		SetSOIMesh()
	
func SetSMA(n):
	SemiMajorAxis=n

	if Parent!=null:
		SetSOIMesh()
	var G: float = 6.67e-11
	if Parent!=null:
		var u = Parent.Mass*G
		Period = 2*PI * sqrt(pow(SemiMajorAxis,3)/u)
	MakeOrbitRep()

func SetPeriod(np):
	Period=np
	var G: float = 6.67e-11
	if Parent!=null:
		var M = Parent.Mass
		SemiMajorAxis = (pow((G*M*pow(Period,2.0))/(4*PI*PI),1.0/3.0))
	MakeOrbitRep()
	
func SetE(newE):
	eccentricity=newE
	MakeOrbitRep()
func SetLOAN(nl):
	loan=nl
	MakeOrbitRep()

func SetOrbitVis(b):
	ShowOrbit=b
	if b:
		OrbitRep.show()
	else:
		OrbitRep.hide()


func SetCol(newCol):
	Col=newCol
	SetMaterial()
func GetCol():
	return Col

func SetStar(n):
	IsStar=n
	SetMesh()
	SetMaterial()

func GetIsStar():
	return IsStar
