extends RayCast3D

@onready var label = $"../../../../POV/CanvasLayer/Label"
@onready var neck := $"../.."
@onready var Crosshair = $"../../../../POV/CanvasLayer/Crosshair"
@onready var SKeyPadText = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/TextKeypad"
@onready var KeypadAudio = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/Sound"
@onready var keypad_path = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad"
@onready var doll: Node3D = $"../../../../Car2/Doll"
@onready var doll_scream: AudioStreamPlayer3D = $"../../../../Car2/Doll/Scream"

@onready var black_m: Node3D = $"../../../../Car3/Black_M"
@onready var black_m_animation: AnimationPlayer = $"../../../../Car3/Black_M/AnimationPlayer2"

@export_group("Reading UI System")
@export var read_ui_container: Control 
@export var story_label: Label

var item_original_transforms: Dictionary = {}
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null

var first = true
var keypad_active := false
var brrsound := true
var EndOfKeypad := false
var MannequinAnimation := false

var doll_shaking := false

var is_reading := false
var r_key_was_pressed := false

var monster_active := false
var monster_seen := false

var keypad_sounds = [
	preload("res://Sounds/ButtonPress.mp3"),
	preload("res://Sounds/Accept.mp3"),
	preload("res://Sounds/Wrong.mp3")
]

func _physics_process(delta: float) -> void:
	if MannequinAnimation and not $"../../../../Car1/mannequin/AnimationPlayer".is_playing():
		$"../../../../Car1/mannequin/AnimationPlayer".play("mixamo_com")
	
	if item_active:
		var can_read = "read_text" in active_item and active_item.read_text != ""
		
		if is_reading:
			label.text = "" 
		elif can_read:
			label.text = "[E] Put back    [R] Read"
		else:
			label.text = "[E] Put back"
		
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
		return
		
	if keypad_active:
		if Input.is_action_just_pressed("Forward") \
		or Input.is_action_just_pressed("Backwards") \
		or Input.is_action_just_pressed("Left") \
		or Input.is_action_just_pressed("Right"):
			exit_keypad()

	if is_colliding():
		var collider = get_collider()
		if not collider:
			return

		if collider.has_method("interact"):
			var interactable = collider
			
			if interactable.object_type == interactable.ObjectType.DOOR:
				if Globals.player_keys.has(interactable.required_key):
					label.text = "[E] Close Door" if interactable.is_open else "[E] Open Door"
					if Input.is_action_just_pressed("Interact"):
						interactable.interact()
				else:
					label.text = "Locked"
				return

			if interactable.object_type == interactable.ObjectType.KEY and EndOfKeypad:
				label.text = "[E] Pick up " + interactable.whoami()
				if Input.is_action_just_pressed("Interact"):
					interactable.interact()
				return

		if collider.specialcheck():
			label.text = "[E] Examine " + collider.whoami()
			if Input.is_action_just_pressed("Interact") and collider.has_method("get_interaction_node") and collider.has_method("get_offset"):
				var item_node: Node3D = collider.get_interaction_node()
				var offset: Vector3 = collider.get_offset()
				if item_node:
					handle_item_interaction(item_node, offset)
				else:
					push_warning("get_interaction_node() returned null")

		elif collider.has_method("whoami") and not collider.special:
			if Input.is_action_just_pressed("Interact"):
				if collider.get_group() == "Keypad":
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
							for light in lights:
								light.visible = false
							brrsound = false
							$"../../../../Car1/mannequin".visible = true
							MannequinAnimation = true
							await Globals.calltime(2)
							for light in lights:
								light.visible = true
							brrsound = true
							$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".play()
							EndOfKeypad = true
							$"../../../../Car1/TempWall/CollisionShape3D".disabled = true
							
							for button in keypad_path.get_children():
								var collider2 = button.get_node_or_null("CollisionShape3D")
								if collider2:
									collider2.disabled = true
							
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
				
				if collider.whoami() == "Keypad" and Input.is_action_just_pressed("Interact") and not keypad_active:
					enter_keypad()
					
				if collider.whoami() == "Chalkboard" and first:
					var door = $"../../../../Car2/StaticBody3D"
					if door and door.has_method("_toggle_door"):
						if door.is_open:
							door._toggle_door()   # force close if open
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
					
			
			if collider.whoami() == "Keypad" or collider.whoami() == "Chalkboard":
				label.text = "[E] To interact"
				
	else:
		label.text = ""


func _toggle_reading_mode():
	if not read_ui_container or not story_label:
		printerr("RayCast Error: ReadUI Container or Label not assigned in Inspector!")
		return

	is_reading = !is_reading
	
	if is_reading:
		print("Attempting to read...")
		if "read_text" in active_item:
			print("Found variable! The text is: ", active_item.read_text)
			story_label.text = active_item.read_text
		else:
			print("ERROR: This item does not have a 'read_text' variable!")
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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		active_item = item
		item_active = true

		if item.name == "Wallet":
			neck.wallet_picked_up()

		if item == doll:
			item_tween.finished.connect(start_doll_shake)

	elif item_active and active_item == item:
		if is_reading:
			_toggle_reading_mode()

		var orig_transform: Transform3D = item_original_transforms[path_str]["transform"]

		item_tween = create_tween()
		item_tween.tween_property(item, "global_transform", orig_transform, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if neck.standup:
			Globals.playermoveallow = true
			Crosshair.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		await Globals.calltime(1)
		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape: collider_shape.disabled = false

		if item.name == "Clipboard" and not monster_active:
			monster_active = true
			black_m.visible = true

		active_item = null
		item_active = false

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
