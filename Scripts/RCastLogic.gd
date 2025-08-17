extends RayCast3D

@onready var label = $"../../../../POV/CanvasLayer/Label"
@onready var neck := $"../.."
@onready var Crosshair = $"../../../../POV/CanvasLayer/Crosshair"
@onready var SKeyPadText = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/TextKeypad"
@onready var KeypadAudio = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/Sound"
@onready var keypad_path = $"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad"
var item_original_transforms: Dictionary = {}
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null

var keypad_active := false
var brrsound := true
var EndOfKeypad := false
var MannequinAnimation := false

var keypad_sounds = [
	preload("res://Sounds/ButtonPress.mp3"),
	preload("res://Sounds/Accept.mp3"),
	preload("res://Sounds/Wrong.mp3")
]

func _physics_process(delta: float) -> void:
	if MannequinAnimation and not $"../../../../Car1/mannequin/AnimationPlayer".is_playing():
		$"../../../../Car1/mannequin/AnimationPlayer".play("mixamo_com")
	
	
	
	if item_active:
		label.text = "[E] Put back"
		if Input.is_action_just_pressed("Interact"):
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

		# Special items
		if collider.specialcheck():
			label.text = "[E] Examine " + collider.whoami()
			if Input.is_action_just_pressed("Interact") and collider.has_method("get_interaction_node") and collider.has_method("get_offset"):
				var item_node: Node3D = collider.get_interaction_node()
				var offset: Vector3 = collider.get_offset()
				if item_node:
					handle_item_interaction(item_node, offset)
				else:
					push_warning("get_interaction_node() returned null")

		# Other interactables
		elif collider.has_method("whoami") and not collider.special:
			if Input.is_action_just_pressed("Interact"):
				if collider.get_group() == "Keypad":
					if collider.whoami() == "OK":
						if SKeyPadText.mesh.text.length() < 4 or int(SKeyPadText.mesh.text) != 0814:
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
							$"../../../Player".play_backwards("Fov")
							Globals.mouse_sensitivity *= 4
							Globals.playermoveallow = true
							await Globals.calltime(1)
							$"../../../../Car1/TempWall/CollisionShape3D".disabled = false
							$"../../../../Car1/Security Keypad/Security Keypad Pivot/Security Keypad/Fall".play("Fall")
							await Globals.calltime(2)
							$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".stop()
							var lights = [
							$"../../../../Car1/body003_Body_0/OmniLight3D", 
							$"../../../../Car1/body003_Body_0/OmniLight3D2", 
							$"../../../../Car1/body003_Body_0/OmniLight3D3", 
							$"../../../../Car1/body003_Body_0/OmniLight3D4", 
							$"../../../../Car1/body003_Body_0/OmniLight3D5", 
							$"../../../../Car1/body003_Body_0/OmniLight3D6", 
							$"../../../../Car1/body003_Body_0/OmniLight3D7", 
							$"../../../../Car1/body003_Body_0/OmniLight3D8", 
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

				
				
				
				
				
				
							
			label.text = "[E] To interact"
	else:
		label.text = ""



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

	# Store original transform first time
	if not item_original_transforms.has(path_str):
		item_original_transforms[path_str] = { "transform": item.global_transform }

	# Picking up
	if not item_active:
		var player = get_tree().get_root().get_node("Node3D/Player")
		if not player:
			return
		var camera = player.get_node_or_null("Neck/Camera")
		if not camera:
			return

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

		# Disable collision
		var collider_shape = item.find_child("CollisionShape3D", true, false)
		if collider_shape:
			collider_shape.disabled = true

		Globals.playermoveallow = false
		Crosshair.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		active_item = item
		item_active = true

		# --- Wallet dialogue trigger ---
		if item.name == "Wallet":
			neck.wallet_picked_up()

	# Putting back
	elif item_active and active_item == item:
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
		if collider_shape:
			collider_shape.disabled = false

		active_item = null
		item_active = false

		# --- Wallet stand-up trigger, first time only ---
		if item.name == "Wallet":
			await neck.wallet_put_down()


func _RemoveDoll(body: Node3D) -> void:
	if $"../../../../Car1/mannequin".visible == true and EndOfKeypad:
		$"../../../../Car1/mannequin/Head".play("HeadLookBack")
		await Globals.calltime(1.9)
		$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".stop()
		var lights = [
		$"../../../../Car1/body003_Body_0/OmniLight3D", 
		$"../../../../Car1/body003_Body_0/OmniLight3D2", 
		$"../../../../Car1/body003_Body_0/OmniLight3D3", 
		$"../../../../Car1/body003_Body_0/OmniLight3D4", 
		$"../../../../Car1/body003_Body_0/OmniLight3D5", 
		$"../../../../Car1/body003_Body_0/OmniLight3D6", 
		$"../../../../Car1/body003_Body_0/OmniLight3D7", 
		$"../../../../Car1/body003_Body_0/OmniLight3D8", 
		$"../../../../Car1/body003_Body_0/OmniLight3D9"
		]
		for light in lights:
			light.visible = false
		brrsound = false
		await Globals.calltime(0.1)
		$"../../../../Car1/mannequin".visible = false
		MannequinAnimation = false
		$"../../../../Car1/body003_Body_0/StaticBody3D/Bulbs".play()
		for light in lights:
			light.visible = true
		brrsound = true
