extends Node

@onready var RCastLogic = $"../Camera/RayCast3D"

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	# Try to get Car1 node safely
	var car = get_node_or_null("../../../Car1")
	if car == null:
		return # Car1 is gone, nothing to do

	# Gather lights safely
	var light_paths = [
		"body003_Body_0/OmniLight3D/LightBrr",
		"body003_Body_0/OmniLight3D2/LightBrr",
		"body003_Body_0/OmniLight3D3/LightBrr",
		"body003_Body_0/OmniLight3D4/LightBrr",
		"body003_Body_0/OmniLight3D5/LightBrr",
		"body003_Body_0/OmniLight3D6/LightBrr",
		"body003_Body_0/OmniLight3D7/LightBrr",
		"body003_Body_0/OmniLight3D8/LightBrr",
		"body003_Body_0/OmniLight3D9/LightBrr"
	]

	var lights: Array = []
	for path in light_paths:
		var light = car.get_node_or_null(path)
		if light:
			lights.append(light)

	# Check first light for state safely
	if lights.size() > 0 and RCastLogic.brrsound:
		if is_instance_valid(lights[1]) and not lights[1].is_playing():
			for light in lights:
				if is_instance_valid(light):
					light.play()
	elif not RCastLogic.brrsound:
		for light in lights:
			if is_instance_valid(light):
				light.stop()
