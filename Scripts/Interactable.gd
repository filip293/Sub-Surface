extends StaticBody3D

@export var group: String = ""
@export var whoami_value = "Name"
@export var special: bool = false
@export var interaction_offset: Vector3 = Vector3(0, 0, 0)

enum ObjectType { GENERIC, KEY, DOOR }
@export var object_type: ObjectType = ObjectType.GENERIC

@export var key_id: String = ""

@export var required_key: String = ""
@export var is_entrance_door: bool = false
@export var audio_player: AudioStreamPlayer3D
@export var open_sound: AudioStream
@export var close_sound: AudioStream

var is_open: bool = false
var door_tween: Tween

func _get_property_list():
	var properties = []
	if object_type == ObjectType.KEY:
		properties.append({ "name": "key_id", "type": TYPE_STRING })
	elif object_type == ObjectType.DOOR:
		properties.append({ "name": "required_key", "type": TYPE_STRING })
		properties.append({ "name": "is_entrance_door", "type": TYPE_BOOL })
		properties.append({ "name": "audio_player", "type": TYPE_NODE_PATH, "hint_string": "AudioStreamPlayer3D" })
		properties.append({ "name": "open_sound", "type": TYPE_OBJECT, "hint_string": "AudioStream" })
		properties.append({ "name": "close_sound", "type": TYPE_OBJECT, "hint_string": "AudioStream" })
	return properties

func _ready() -> void:
	if group != "":
		add_to_group(group)

func interact() -> void:
	match object_type:
		ObjectType.KEY:
			_pickup_key()
		ObjectType.DOOR:
			_toggle_door()
		_:
			print("Interacted with generic object: ", whoami_value)

func _pickup_key() -> void:
	if not Globals.player_keys.has(key_id):
		Globals.player_keys.append(key_id)
		print("Player picked up key: ", key_id)
		$/root/Node3D/Player/KeyPickup.play()
	queue_free()

func _toggle_door() -> void:
	if door_tween and door_tween.is_running():
		return

	is_open = not is_open
	var target_rotation_y_deg: float
	
	door_tween = create_tween()

	if is_open:
		var open_duration = 3.2
		
		if audio_player and open_sound:
			audio_player.stream = open_sound
			audio_player.play()
			
		if is_entrance_door:
			target_rotation_y_deg = randf_range(70.0, 90.0)
		else:
			target_rotation_y_deg = randf_range(-70.0, -90.0)
		
		door_tween.tween_property(self, "rotation_degrees:y", target_rotation_y_deg, open_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	else: 
		var close_duration = 3.8
		
		if audio_player and close_sound:
			audio_player.stream = close_sound
			audio_player.play()
			
		target_rotation_y_deg = 180.0 if is_entrance_door else 0.0
		
		door_tween.tween_property(self, "rotation_degrees:y", target_rotation_y_deg, close_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func whoami():
	return whoami_value

func specialcheck():
	return special

func get_group():
	return group
	
func get_interaction_node() -> Node3D:
	return self

func get_offset() -> Vector3:
	return interaction_offset
