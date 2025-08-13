extends Node3D

@export var crouch_height := 0
@export var stand_height := 0.5
@export var stand_duration := 0.8
@export var forward_distance := 0.4
@export var forward_duration := 0.8

var wallet_dialogue_played := false
var wallet_standup_done := false
var standup:= false

func _ready():
	position.y = crouch_height

# Call this immediately when the wallet is picked up
func wallet_picked_up():
	if not wallet_dialogue_played:
		wallet_dialogue_played = true
		await Globals.calltime(1) # wait 1 second for head movement
		await DialogueManager.show_dialogue_balloon(
			load("res://Dialogue/Dialogue.dialogue"), "Id"
		)
		await DialogueManager.dialogue_ended

# Call this once, the first time the wallet is put down
func wallet_put_down():
	if not wallet_standup_done:
		wallet_standup_done = true
		await exit_seat()

func exit_seat():
	var player = get_node("/root/Node3D/Player")
	if not player:
		push_warning("Player node not found")
		return
	
	var tween = create_tween()
	tween.set_parallel(true)

	# --- Step 1: Rotate player to 180° ---
	if abs(player.rotation_degrees.y - 180) > 0.1:
		tween.tween_property(player, "rotation_degrees:y", 180.0, 0.5)

	# Wait for rotation to finish
	await tween.finished
	await Globals.calltime(1)  # 1-second delay after head turns

	# --- Step 2: Stand up and move forward ---
	tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position:y", stand_height, stand_duration).from(crouch_height)

	var forward_vector = -player.transform.basis.z * forward_distance
	var target_position = player.global_transform.origin + forward_vector
	tween.tween_property(player, "global_transform:origin", target_position, forward_duration).from(player.global_transform.origin)

	await tween.finished
	standup = true
	Globals.playermoveallow = true
	$"../../Car1/body003_side_chair_0/StaticBody3D/CollisionShape3D".set_deferred("disabled", false)
