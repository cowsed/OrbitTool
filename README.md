# Godot CADLikeOrbit_Camera

A Camera wich behaves like most Cameras in 
CAD-Softwares. It uses the mouse and lets you Orbit,
Zoom and Pan around. 

Usage:

	1. Activate Plugin
	2. Add CADLike-Orbit Camera via new Node (Control+A)  to the Scene
	3. Define InputMap-Actions: (Project->Poject Settings->InputMap)
			example InputMap-Actions:
				Name: "Zooming", Event: Righ Button
				Name "Panning", Event: Middle Button
				Name: "Rotating", Event Left Button

---------------------------------------------------------------------
To determine the Focalpoint a RayCast-Node is used.
Has the RayCast no Collision  (Mouse is not on
a Pickable Object), Pre-Defined Uservalues are used.
 
To Keep one Mousebutton unused the Combination of the
Pan- and Zoom-Action can be used to trigger the Rotate
 Action.
