extends RayCast3D

@onready var label = $"../../../../POV/CanvasLayer/Label"
@onready var neck := $"../.."
@onready var Crosshair = $"../../../../POV/CanvasLayer/Crosshair"

var item_original_transforms: Dictionary = {}
var active_item: Node3D = null
var item_active: bool = false
var item_tween: Tween = null

func _physics_process(delta: float) -> void:
	# If holding an item, allow putting it back without raycast
	if item_active:
		label.text = "[E] Put back"
		if Input.is_action_just_pressed("Interact"):
			handle_item_interaction(active_item, Vector3.ZERO)
		return

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
			label.text = "[E] To interact"
	else:
		label.text = ""

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
