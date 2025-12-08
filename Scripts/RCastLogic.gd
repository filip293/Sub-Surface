extends RayCast3D

@onready var label = $"../../../../POV/CanvasLayer/Label"
@onready var neck := $"../.."
@onready var Crosshair = $"../../../../POV/CanvasLayer/Crosshair"
@onready var SKeyPadText = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/TextKeypad"
@onready var KeypadAudio = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/Sound"
@onready var keypad_path = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad"
@onready var doll: Node3D = $"../../../../Car2/Doll"
@onready var doll_scream: AudioStreamPlayer3D = $"../../../../Car2/Doll/Scream"

@onready var ambiance_music = $"../../../../AmbianceMUSIC"

@onready var black_m: Node3D = $"../../../../Car3/Black_M"
@onready var black_m_animation: AnimationPlayer = $"../../../../Car3/Black_M/AnimationPlayer2"

@export_group("Reading UI System")
@export var read_ui_container: Control 
@export var story_label: Label

var item_original_transforms: Dictionary = {}
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null

var is_dragging_item: bool = false
var drag_sensitivity: float = 0.01

var first = true
var first2 = true
var keypad_active := false
var brrsound := true
var EndOfKeypad := false
var MannequinAnimation := false

var has_played_door2_music := false 

var doll_shaking := false

var is_reading := false
var r_key_was_pressed := false

var monster_active := false
var monster_seen := false

var label_tween: Tween
var current_displayed_text: String = ""

var keypad_sounds = [
	preload("res://Sounds/ButtonPress.mp3"),
	preload("res://Sounds/Accept.mp3"),
	preload("res://Sounds/Wrong.mp3")
]

func _ready() -> void:
	label.text = ""
	label.modulate.a = 0.0
	current_displayed_text = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if not item_active or not active_item:
		return

	if event is InputEventMouseMotion:
		if "draggable" in active_item and active_item.draggable:
			if is_dragging_item:
				var camera = get_viewport().get_camera_3d()
				var cam_basis = camera.global_transform.basis
				active_item.global_rotate(cam_basis.y, event.relative.x * drag_sensitivity)
				active_item.global_rotate(cam_basis.x, event.relative.y * drag_sensitivity)
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging_item = event.pressed


func _physics_process(delta: float) -> void:
	var target_text = ""

	if MannequinAnimation and not $"../../../../Car1/mannequin/AnimationPlayer".is_playing():
		$"../../../../Car1/mannequin/AnimationPlayer".play("mixamo_com")
	
	if item_active:
		var can_read = "read_text" in active_item and active_item.read_text != ""
		var can_drag = "draggable" in active_item and active_item.draggable
		
		if is_reading:
			target_text = "" 
		else:
			var txt = "[E] Put back"
			if can_drag:
				txt += "   [Hold Click] Rotate"
			if can_read:
				txt += "   [R] Read"
			target_text = txt
		
		if can_read and Input.is_key_pressed(KEY_R):
			if not r_key_was_pressed:
				r_key_was_pressed = true
				_toggle_reading_mode()
		else:
			r_key_was_pressed = false

		if Input.is_action_just_pressed("Interact"):
			if is_reading:
				_toggle_reading_mode()
			else:
				handle_item_interaction(active_item, Vector3.ZERO)
		
		_animate_label(target_text)
		return 
		
	if keypad_active:
		if Input.is_action_just_pressed("Forward") \
		or Input.is_action_just_pressed("Backwards") \
		or Input.is_action_just_pressed("Left") \
		or Input.is_action_just_pressed("Right"):
			exit_keypad()

	if is_colliding():
		var collider = get_collider()
		if collider:
			if collider.has_method("interact"):
				var interactable = collider
				
				if interactable.object_type == interactable.ObjectType.DOOR:
					if Globals.player_keys.has(interactable.required_key):
						target_text = "[E] Close Door" if interactable.is_open else "[E] Open Door"
						if Input.is_action_just_pressed("Interact"):
							if not has_played_door2_music and not interactable.is_open:
								if str(interactable.required_key) == "2" and interactable.name == "HingeDoor2":
									if ambiance_music:
										await Globals.calltime(1)
										ambiance_music.play()
									has_played_door2_music = true
							interactable.interact()
					else:
						target_text = "Locked"

				elif interactable.object_type == interactable.ObjectType.KEY and EndOfKeypad:
					target_text = "[E] Pick up " + interactable.whoami()
					if Input.is_action_just_pressed("Interact"):
						interactable.interact()
				
				elif interactable.object_type == interactable.ObjectType.GENERIC and not collider.get_group() == "Keypad":
					pass

			if collider.specialcheck():
				target_text = "[E] Examine " + collider.whoami()
				if Input.is_action_just_pressed("Interact") and collider.has_method("get_interaction_node") and collider.has_method("get_offset"):
					var item_node: Node3D = collider.get_interaction_node()
					var offset: Vector3 = collider.get_offset()
					if item_node:
						handle_item_interaction(item_node, offset)
					else:
						push_warning("get_interaction_node() returned null")

			if collider.has_method("whoami") and not collider.special:
				if collider.get_group() == "Keypad":
					target_text = "[E] To interact"
					if Input.is_action_just_pressed("Interact"):
						if collider.whoami() == "OK":
							if SKeyPadText.mesh.text.length() < 4 or int(SKeyPadText.mesh.text) != 814:
								KeypadAudio.stop()
								KeypadAudio.stream = keypad_sounds[2]
								KeypadAudio.play()
								SKeyPadText.mesh.text = "Denied"
							else:
								keypad_active = false
								KeypadAudio.stop()
								KeypadAudio.stream = keypad_sounds[1]
								KeypadAudio.play()
								SKeyPadText.mesh.text = "Accept"
								$"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/NumOK/CollisionShape3D".disabled = true
								$"../../../Player".play_backwards("Fov")
								Globals.mouse_sensitivity *= 4
								Globals.playermoveallow = true
								await Globals.calltime(1)
								$"../../../../Car1/TempWall/CollisionShape3D".disabled = false
								$"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/Fall".play("Fall")
								await Globals.calltime(0.3)
								$"../../../../Car1/Security Keypad/Key/KayFall".play("KeyFall")
								await Globals.calltime(2)
								$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".stop()
								var lights = [
								$"../../../../Car1/body003_Body_0/OmniLight3D", $"../../../../Car1/body003_Body_0/OmniLight3D2", 
								$"../../../../Car1/body003_Body_0/OmniLight3D3", $"../../../../Car1/body003_Body_0/OmniLight3D4",
								$"../../../../Car1/body003_Body_0/OmniLight3D5", $"../../../../Car1/body003_Body_0/OmniLight3D6",
								$"../../../../Car1/body003_Body_0/OmniLight3D7", $"../../../../Car1/body003_Body_0/OmniLight3D8",
								$"../../../../Car1/body003_Body_0/OmniLight3D9"
								]
								for light in lights: light.visible = false
								brrsound = false
								$"../../../../Car1/mannequin".visible = true
								MannequinAnimation = true
								await Globals.calltime(2)
								for light in lights: light.visible = true
								brrsound = true
								$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".play()
								EndOfKeypad = true
								$"../../../../Car1/TempWall/CollisionShape3D".disabled = true
								
								for button in keypad_path.get_children():
									var collider2 = button.get_node_or_null("CollisionShape3D")
									if collider2: collider2.disabled = true
								
						elif collider.whoami() == "CLR":
							KeypadAudio.stop()
							KeypadAudio.stream = keypad_sounds[0]
							KeypadAudio.play()
							SKeyPadText.mesh.text = ""
						else:
							KeypadAudio.stop()
							KeypadAudio.stream = keypad_sounds[0]
							KeypadAudio.play()
							if SKeyPadText.mesh.text.length() < 4:
								SKeyPadText.mesh.text += collider.whoami()
							else:
								SKeyPadText.mesh.text = ""
								SKeyPadText.mesh.text += collider.whoami()
				
				if collider.whoami() == "Keypad":
					target_text = "[E] To interact"
					if Input.is_action_just_pressed("Interact") and not keypad_active:
						enter_keypad()
				
				if collider.whoami() == "Glass":
					target_text = "[E] Pick up glass"
					if Input.is_action_just_pressed("Interact"):
						$"../../../Glass/PickUp".play()
						$"../../../../Car3/Glass".queue_free()
						$"../../../Glass".visible = true;
					
				if collider.whoami() == "Chalkboard":
					target_text = "[E] To interact"
					if first:
						if Input.is_action_just_pressed("Interact"):
							var door = $"../../../../Car2/StaticBody3D"
							if door and door.has_method("_toggle_door"):
								if door.is_open:
									door._toggle_door()
								$"../../../../Car2/StaticBody3D/CollisionShape3D".disabled = true
							$"../../../../Car2/Classroom/ChalkBoard/Chalk".play("LightsAndSound")
							$"../../../../Car2/Classroom/ChalkBoard/group1802101336/StaticBody3D/CollisionShape3D".disabled = true
							first = false
							await Globals.calltime(6)
							$"../../../../Car2/Desk/RootNode/Desk_Drawer3/Key/CollisionShape3D".disabled = false
							$"../../../../Car2/Desk/Desk".play("Desk")
							$"../../../../Car3".visible = true
							$"../../../../Car1".queue_free()
							$"../../../../Newspaper".queue_free()
							$"../../../../Wallet".queue_free()

	_animate_label(target_text)


func _animate_label(new_text: String):
	if current_displayed_text == new_text:
		return

	current_displayed_text = new_text

	if label_tween:
		label_tween.kill()
	
	label_tween = create_tween()
	
	if new_text == "":
		label_tween.tween_property(label, "modulate:a", 0.0, 0.2)
		label_tween.tween_callback(func(): label.text = "")
	else:
		if label.modulate.a <= 0.05:
			label.text = new_text
			label_tween.tween_property(label, "modulate:a", 1.0, 0.3)
		else:
			label_tween.tween_property(label, "modulate:a", 0.0, 0.15)
			label_tween.tween_callback(func(): label.text = new_text)
			label_tween.tween_property(label, "modulate:a", 1.0, 0.25)


func _toggle_reading_mode():
	if not read_ui_container or not story_label:
		printerr("RayCast Error: ReadUI Container or Label not assigned in Inspector!")
		return

	is_reading = !is_reading
	
	if is_reading:
		if "read_text" in active_item:
			story_label.text = active_item.read_text
		else:
			story_label.text = "Error: No text found on object."
			
		read_ui_container.visible = true
		
		read_ui_container.modulate.a = 0.0
		read_ui_container.scale = Vector2(0.9, 0.9)
		read_ui_container.pivot_offset = read_ui_container.size / 2 
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(read_ui_container, "modulate:a", 1.0, 0.2)
		tween.tween_property(read_ui_container, "scale", Vector2(1.0, 1.0), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
	else:
		var tween = create_tween()
		tween.tween_property(read_ui_container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): read_ui_container.visible = false)

func enter_keypad():
	keypad_active = true
	Globals.mouse_sensitivity /= 4
	$"../../../../Car1/Security Keypad/Keypad/CollisionShape3D".disabled = true
	$"../../../Player".play("Fov")
	Globals.playermoveallow = false

func exit_keypad():
	keypad_active = false
	Globals.mouse_sensitivity *= 4
	$"../../../../Car1/Security Keypad/Keypad/CollisionShape3D".disabled = false
	$"../../../Player".play_backwards("Fov")
	Globals.playermoveallow = true

func handle_item_interaction(item: Node3D, offset: Vector3) -> void:
	var path_str := str(item.get_path())

	if not item_original_transforms.has(path_str):
		item_original_transforms[path_str] = { "transform": item.global_transform }

	if not item_active:
		var player = get_tree().get_root().get_node("Node3D/Player")
		if not player: return
		var camera = player.get_node_or_null("Neck/Camera")
		if not camera: return

		var cam_transform = camera.global_transform
		var new_basis = Basis(cam_transform.basis)
		new_basis = new_basis.scaled(item.global_transform.basis.get_scale())
		var new_position = cam_transform.origin
		new_position += -cam_transform.basis.z * offset.z
		new_position += -cam_transform.basis.x * offset.x
		new_position += cam_transform.basis.y * offset.y
		var new_transform = Transform3D(new_basis, new_position)

		item_tween = create_tween()
		item_tween.tween_property(item, "global_transform", new_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape: collider_shape.disabled = true

		Globals.playermoveallow = false
		Crosshair.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		active_item = item
		item_active = true

		if item.name == "Wallet":
			neck.wallet_picked_up()

		if item == doll:
			if first2:
				first2 = false
				item_tween.finished.connect(start_doll_shake)

	elif item_active and active_item == item:
		if is_reading:
			_toggle_reading_mode()
		
		is_dragging_item = false
		item_active = false
		active_item = null
		
		if neck.standup:
			Globals.playermoveallow = true
			Crosshair.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		var orig_transform: Transform3D = item_original_transforms[path_str]["transform"]

		item_tween = create_tween()
		item_tween.tween_property(item, "global_transform", orig_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# --- FIX: SPAWN MONSTER IMMEDIATELY (Before animation finishes) ---
		if item.name == "Clipboard" and not monster_active:
			monster_active = true
			black_m.visible = true
		# ------------------------------------------------------------------

		await item_tween.finished
		
		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape: collider_shape.disabled = false

		if item.name == "Wallet":
			await neck.wallet_put_down()

		if item == doll:
			stop_doll_shake()


func start_doll_shake() -> void:
	doll_shaking = true
	if not doll_scream.playing:
		doll_scream.play()
	shake_doll()
	await get_tree().create_timer(4.0).timeout
	stop_doll_shake()

func stop_doll_shake() -> void:
	doll_shaking = false

func shake_doll() -> void:
	if not doll_shaking: return
	var rand_rot = Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1)
	)
	doll.rotate_x(rand_rot.x)
	doll.rotate_y(rand_rot.y)
	doll.rotate_z(rand_rot.z)
	await get_tree().create_timer(0.03).timeout
	shake_doll()


func _RemoveDoll(body: Node3D) -> void:
	if $"../../../../Car1/mannequin".visible == true and EndOfKeypad:
		$"../../../../Car1/mannequin/Head".play("HeadLookBack")
		await Globals.calltime(1.9)
		$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".stop()
		var lights = [
		$"../../../../Car1/body003_Body_0/OmniLight3D", $"../../../../Car1/body003_Body_0/OmniLight3D2", 
		$"../../../../Car1/body003_Body_0/OmniLight3D3", $"../../../../Car1/body003_Body_0/OmniLight3D4",
		$"../../../../Car1/body003_Body_0/OmniLight3D5", $"../../../../Car1/body003_Body_0/OmniLight3D6",
		$"../../../../Car1/body003_Body_0/OmniLight3D7", $"../../../../Car1/body003_Body_0/OmniLight3D8",
		$"../../../../Car1/body003_Body_0/OmniLight3D9"
		]
		for light in lights: light.visible = false
		brrsound = false
		await Globals.calltime(0.1)
		$"../../../../Car1/mannequin".visible = false
		MannequinAnimation = false
		$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".play()
		for light in lights: light.visible = true
		brrsound = true

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	if monster_active and not monster_seen:
		monster_seen = true
		$"../../../../Car3/Black_M/Jumpscare".play()
		await Globals.calltime(1)
		black_m_animation.play("GoToSeat")
