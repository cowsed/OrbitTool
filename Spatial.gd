extends Spatial

#Todo, accurate position and velocity according to time
#checking for intersections on next N orbits of non-static bodies
#  maybe need a registry here of all bodies that can do that math
# Show Ascending and Descending nodes
# Show Apoapsis and periapsis
# Setting sma affects period
# Setting period affects sma
class_name OrbitController

export(float,0,100) var timeMultiplier = 1

onready var Time = 0

func _process(delta):
	Time+=delta*timeMultiplier

func is_type(type): 
	return type == "OrbitController" or .is_type(type)
func get_type(): 
	return "OrbitController"
