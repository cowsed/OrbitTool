extends ImmediateGeometry

class_name Line3D, "res://Line.svg"

var Points: PoolVector3Array
var Center: Vector3

func AddPoint(v: Vector3):
	Points.push_back(v)

func ClearOrbit():
	Points.resize(0)
	pass

func MakeMesh():
	
	clear()
	begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for p in Points:
		add_vertex(p+Center)
	
	end()
