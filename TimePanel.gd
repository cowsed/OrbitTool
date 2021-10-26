extends Panel


func _ready():
	set_time(0)
	pass # Replace with function body.

func set_time(t: float):
	var days = floor(t/(24*60*60))
	t-=days*(24*60*60)
	var hours = floor(t/(60*60))
	t-=hours*(60*60)
	var minutes = floor(t/60)
	t-=minutes*60
	var seconds = t
	
	var format_str = "%d days, %02d:%02d - %d"
	var time_str = format_str % [days, hours, minutes, seconds]
	$Label.text=time_str
