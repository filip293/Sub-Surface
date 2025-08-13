extends StaticBody3D

@export var whoami_value = "Name"
@export var special: bool = false
@export var title: String = ""
@export var description: String = ""
@export var interaction_offset: Vector3 = Vector3(0, 0, 0)

func whoami():
	return whoami_value

func specialcheck():
	return special

func get_title():
	return title

func get_description():
	return description

func get_interaction_node() -> Node3D:
	return self

func get_offset() -> Vector3:
	return interaction_offset
