extends Node

@onready var RCastLogic = $"../Camera/RayCast3D"

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if $/root/Node3D/Player/Neck/TrainSound.is_playing() == false:
		$/root/Node3D/Player/Neck/TrainSound.play()
	
	if not $"../../../Car1/body003_Body_0/OmniLight3D2/LightBrr".is_playing() and RCastLogic.brrsound == true:
		var lights = [
			$"../../../Car1/body003_Body_0/OmniLight3D/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D2/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D3/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D4/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D5/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D6/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D7/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D8/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D9/LightBrr"
		]
		for light in lights:
			light.play()
	elif RCastLogic.brrsound == false:
		var lights = [
			$"../../../Car1/body003_Body_0/OmniLight3D/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D2/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D3/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D4/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D5/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D6/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D7/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D8/LightBrr",
			$"../../../Car1/body003_Body_0/OmniLight3D9/LightBrr"
		]
		for light in lights:
			light.stop()
