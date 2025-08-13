extends Node

@onready var BaseTime = $/root/Node3D/BaseTime
signal timeend

var mouse_sensitivity = 0.2
var playermoveallow = true
var playerlookallow = true

func calltime(time) -> void:
	BaseTime.set_wait_time(time)
	BaseTime.start()
	await BaseTime.timeout
	timeend.emit()
