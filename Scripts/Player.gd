extends CharacterBody3D

# --- Player Components ---
@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var footstep_player := $RightFoot

@export var footstep_sounds: Array[AudioStream]

const SPEED = 2.0
const FOOTSTEP_INTERVAL := 1.3 / SPEED
const FOOT_OFFSET_X := 0.3 

var is_left_foot := true
var footstep_timer := 0.0
var current_footstep_index := 0

var inmenu = true


func _ready() -> void:
	Globals.playerlookallow = false
	Globals.playermoveallow = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$"../Menu2/CanvasLayer".visible = true
	


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
		footstep_timer = 0.0

	if direction and Globals.playermoveallow:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func play_footstep_sound():
	if footstep_sounds.is_empty():
		return

	if current_footstep_index >= footstep_sounds.size():
		current_footstep_index = 0
		footstep_sounds.shuffle()
		
	footstep_player.stream = footstep_sounds[current_footstep_index]

	if is_left_foot:
		footstep_player.position.x = -FOOT_OFFSET_X
	else:
		footstep_player.position.x = FOOT_OFFSET_X
	
	footstep_player.play()

	current_footstep_index += 1
	is_left_foot = !is_left_foot


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel") and inmenu:
		if $"../Options/CanvasLayer".visible == true:
			$"../Options/CanvasLayer".visible = false
			$"../Menu2/CanvasLayer".visible = true
	elif Input.is_action_pressed("ui_cancel") and inmenu == false:
		if $"../Options/CanvasLayer".visible == false:
			$"../Options/CanvasLayer".visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

			
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.playerlookallow:
		self.rotate_y(deg_to_rad(event.relative.x * Globals.mouse_sensitivity * -1))
		
		var camera_rot = neck.rotation_degrees
		var rotation_to_apply_on_x_axis = (-event.relative.y * Globals.mouse_sensitivity);

		camera_rot.x = clamp(camera_rot.x + rotation_to_apply_on_x_axis, -90, 70)
		neck.rotation_degrees = camera_rot

func _OutsideSub(body: Node3D) -> void:
	$"../Outside/Outside".play("Outside")
	print("triggered")

func _InsideSub(body: Node3D) -> void:
	$"../Outside/Outside".play("Inside")
	print("triggered2")


func _on_button_pressed() -> void:
	inmenu = false
	$"../Menu2/CanvasLayer".visible = false
	if not footstep_sounds.is_empty():
		footstep_sounds.shuffle()

	Globals.playerlookallow = false
	Globals.playermoveallow = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$"../Car1/body003_Body_0/StaticBody3D/Bulbs".play("OnOff")
	await Globals.calltime(3)
	$"../Car4".visible = false
	$"../Car5".visible = false
	DialogueManager.show_dialogue_balloon(load("res://Dialogue/Dialogue.dialogue"), "Subway")
	await DialogueManager.dialogue_ended
	
	Globals.playerlookallow = true
	$"../Car3/Black_M/AnimationPlayer2".play("GoToSeat")
	await Globals.calltime(0.1)
	$"../Car3/Black_M/AnimationPlayer2".pause()


func _on_button_3_pressed() -> void:
	get_tree().quit()

func _on_button_2_pressed() -> void:
	$"../Menu2/CanvasLayer".visible = false
	$"../Options/CanvasLayer".visible = true


func _on_back_pressed() -> void:
	if inmenu:
		$"../Menu2/CanvasLayer".visible = true
		$"../Options/CanvasLayer".visible = false
	else:
		$"../Options/CanvasLayer".visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_h_slider_2_value_changed(value: float) -> void:
	Globals.mouse_sensitivity = $"../Options/CanvasLayer/VBoxContainer/HSlider2".value


func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db($"../Options/CanvasLayer/VBoxContainer/HSlider".value))
