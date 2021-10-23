extends MeshInstance

class_name Body, "Body.svg"


export(float) var Mass: float = 5.9e24  setget SetMass# #In kgs Mass of the Body

export(float) var Radius: float = 1000 setget SetRadius #In KM, the radius of the body

export(bool) var IsStar = false setget SetStar
export(float) var Period = 1 setget SetPeriod
export(Color, RGBA) var Col  setget SetCol

export var SemiMajorAxis: float = 10 setget SetSMA
export(float,0,1) var eccentricity: float = .0 setget SetE
export var loan: float = 0.0 setget SetLOAN  #longitude of ascending node 
export var offsetTime = 0.0
export var ShowOrbit = true 
export var Static = true #if true, is a planet, if false, can be influenced and enter other spheres of influence
 
onready var Controller = get_tree().root.get_node("Spatial")

const DistanceScale = 0.001 #KM to scene units
const SecsPerDay = 24*60*60
const OUTERSOI = 100_000_000 #the size for an unconstrained? soi 
const G: float = 6.67e-11

onready var Parent= null #get_parent()


func is_type(type): return type == "Body" or .is_type(type)
func    get_type(): return "Body"
func get_class(): return "Body"

var OrbitRep = Line3D.new()
var SOIRep = MeshInstance.new()
var Clicker = Area.new()
var ClickerSphere = CollisionShape.new()

signal SelfSelected(s)
signal SelfUpdated(s)

func Jsonify():
	var res: String ="{"
	res+='"name":"'+name+'",'
	res+='"mass":'+str(Mass)+','
	res+='"semimajoraxis":'+str(SemiMajorAxis)+','
	res+='"eccentricity":'+str(eccentricity)+','
	res+='"loan":'+str(loan)+','
	res+='"offsetTime":'+str(offsetTime)+','
	res+='"children": ['
	var cCount=0
	for c in get_children():
		if c.get_class()=="Body":
			res+=c.Jsonify()
			res+=","
			cCount+=1
	if cCount>0:
		res=res.substr(0,res.length()-1)
	res+=']'
	res+="}"
	return res

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
	self.connect("SelfUpdated", Controller,"BodyUpdated")
	


func _process(_delta):		
		
	if Parent==null:
		Parent=get_parent()
	if SOIRep.mesh==null:
		GenerateSOIMesh()

	var RelativePos
	if Controller==null:
		RelativePos=AtPos2(0)
	else:
		RelativePos=AtPos(Controller.Time)
		RelativePos=AtPos2(Controller.Time)
		
	
	if not Parent==null:
		global_transform.origin=Parent.global_transform.origin+RelativePos


func wasClicked(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			emit_signal("SelfSelected",self)

func UpdateSelf():
	print_debug("updating self")
	SetSOIMesh()
	#Parent could have changed so recalculate period
	if Parent!=null&&Parent.get_class()=="Body":
		var u = Parent.Mass*G
		Period = 2*PI * sqrt(pow(SemiMajorAxis*1000,3)/u)
	MakeOrbitRep()
	SetSOIMesh()

	
func CalcVelocityAt(r: float):

	var parentMass = 0
	if Parent.get_class() == "Body":
		parentMass=Parent.Mass
	var a = SemiMajorAxis

	if r==0 or a==0:
		return 0

	return sqrt(G*parentMass*((2/r)-(1/a)))
func calcB()-> float:
	var e = eccentricity
	var a = SemiMajorAxis
	return a*sqrt(1-pow(e,2))
func AtPos(t: float)-> Vector3:
	if SemiMajorAxis==0 or Period==0:
		return Vector3()
	
	var a=SemiMajorAxis*DistanceScale
	#var b=calcB()
	var e = eccentricity
	var v = t/Period+offsetTime
	var p#: Vector3 = Vector3(cos(v)*a,0,sin(v)*b)
	var r = (a* (1-pow(e,2))  /  (1+e*cos(v)))
	p=Vector3(cos(v)*r, 0, sin(v)*r)
	#p-=translation
	#p=p.rotate_z(loan)
	p=p.rotated(Vector3(0,1,0),loan)
	#p+=translation
	return p

func AtPos2(t: float)-> Vector3:
	if SemiMajorAxis==0 or Period==0 or Parent==null:
		return Vector3()

	var e = eccentricity
	var mu: float = G*Parent.Mass
	
	var Mt: float = t*sqrt(mu/pow(SemiMajorAxis*1000,3))
	var Et: float=SolveKeplersEquation(Mt, eccentricity)
	var Vt = 2*atan2(sqrt(1+e)*sin(Et/2), sqrt(1-e)*cos(Et/2))
	var r_c = SemiMajorAxis*(1-e*cos(Et))
	var o = r_c*DistanceScale*Vector3(cos(Vt), 0, sin(Vt))
	o=o.rotated(Vector3(0,1,0),loan)
	return o

func SolveKeplersEquation(M: float, e: float):
	var E: float = M
	var En: float
	for i in range(10):
		En = E-((E-e*sin(E)-M)/(1-e*cos(E)))
		E=En
	return E

func MakeOrbitRep():
	if OrbitRep==null:
		OrbitRep=Line3D.new()
		
	OrbitRep.ClearOrbit()
	var res=.01;
	var t=0
	while t<2*PI:
		var p = AtPos(t*Period+offsetTime)
		#add p to line
		OrbitRep.AddPoint(p)
		t+=res
	OrbitRep.MakeMesh()


# Called when the node enters the scene tree for the first time.


func CalcSOI():
	if Parent==null || Parent.get_class()!="Body":
		return OUTERSOI
		
	else:
		var parentMass: float=Parent.Mass
		#var parentMassScale = get_parent().MassScale
		print_debug("m/M ",Mass/parentMass)
		return SemiMajorAxis*pow(Mass/parentMass, 2.0/5.0) #Todo remove this? or no cuz its dividing by that so what the hell


func GenerateSOIMesh():
	SOIRep.mesh=SphereMesh.new()
	SOIRep.mesh.material = SpatialMaterial.new()
	SOIRep.mesh.material.flags_transparent=true
	SOIRep.mesh.material.flags_unshaded=true

	SOIRep.mesh.material.albedo_color.r=.8
	SOIRep.mesh.material.albedo_color.g=.8
	SOIRep.mesh.material.albedo_color.b=.8

	SOIRep.mesh.material.albedo_color.a=.006
	SetSOIMesh()
	
func SetSOIMesh():
	if SOIRep.mesh==null:
		SOIRep.mesh=SphereMesh.new()
	var r: float
	r=CalcSOI()
	print_debug("Rad",r)
	SOIRep.mesh.radius=r*DistanceScale
	SOIRep.mesh.height=2*SOIRep.mesh.radius


		
	
	
func GenerateMesh():
	mesh=SphereMesh.new()
	mesh.material = SpatialMaterial.new()
	ClickerSphere.shape = SphereShape.new()
	SetMesh()
	SetMaterial()

	
func SetMesh():
	if mesh==null:
		GenerateMesh()
	mesh.radius=Radius*DistanceScale
	mesh.height=2*mesh.radius
	
	if ClickerSphere.shape!=null:
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



func SetMass(nm):
	if nm==0:
		nm=1	
	print("SOI: ",CalcSOI())
	Mass=nm*1.0e24#*MassScale
	print(name," sets SOI Parent", Parent)
	print("SOI: ",CalcSOI())
	
	SetSOIMesh()
	emit_signal("SelfUpdated",self)
		
func SetRadius(nr):
	Radius=nr
	SetMesh()
	emit_signal("SelfUpdated",self)
func SetSMA(n):
	SemiMajorAxis=n
	SetSOIMesh()
	if Parent!=null && Parent.get_class()=="Body":
		var u = Parent.Mass*G
		Period = 2*PI * sqrt(pow(SemiMajorAxis*1000,3)/u) #Convert SMA to meters
	MakeOrbitRep()
	emit_signal("SelfUpdated",self)

func SetPeriod(np):
	if np==0:
		np=1
	Period=np
	print(name,"sets period w/ parent", get_parent())
	if Parent!=null && Parent.get_class()=="Body":
		var u = Parent.Mass*G
		SemiMajorAxis = (pow((u*pow(Period,2.0))/(4*PI*PI),1.0/3.0)) / 1000.0
	MakeOrbitRep()
	emit_signal("SelfUpdated",self)
	
func SetE(newE):
	eccentricity=newE
	MakeOrbitRep()
	emit_signal("SelfUpdated",self)
func SetLOAN(nl):
	loan=nl
	MakeOrbitRep()
	emit_signal("SelfUpdated",self)

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
