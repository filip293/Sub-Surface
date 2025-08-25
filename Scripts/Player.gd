extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var right_foot_audio := $RightFoot
@onready var left_foot_audio := $LeftFoot


const FOOTSTEP_INTERVAL := 1.3 / SPEED
const SPEED = 2.0

var is_left_foot := true
var footstep_timer := 0.0


func _ready() -> void:
	Globals.playerlookallow = false
	Globals.playermoveallow = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$"../Car1/body003_Body_0/StaticBody3D/Bulbs".play("OnOff")
	await Globals.calltime(3)
	
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/Dialogue.dialogue"), "Subway")
	await DialogueManager.dialogue_ended
	
	Globals.playerlookallow = true
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Globals.playermoveallow and direction.length() > 0.1:
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			play_footstep_sound()
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0  # Reset timer if not moving

	if direction and Globals.playermoveallow:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()



func play_footstep_sound():
	if Globals.playermoveallow:
		if is_left_foot:
			left_foot_audio.play()
		else:
			right_foot_audio.play()
		
		is_left_foot = !is_left_foot


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.playerlookallow:
		self.rotate_y(deg_to_rad(event.relative.x * Globals.mouse_sensitivity * -1))
		
		var camera_rot = neck.rotation_degrees
		var rotation_to_apply_on_x_axis = (-event.relative.y * Globals.mouse_sensitivity);
		
		if (camera_rot.x + rotation_to_apply_on_x_axis < -90):
			camera_rot.x = -90
		elif (camera_rot.x + rotation_to_apply_on_x_axis > 70):
			camera_rot.x = 70
		else:
			camera_rot.x += rotation_to_apply_on_x_axis;
			neck.rotation_degrees = camera_rot


func _OutsideSub(body: Node3D) -> void:
	$"../Car1/Outside/Outside".play("Outside")


func _InsideSub(body: Node3D) -> void:
	$"../Car1/Outside/Outside".play("Inside")
