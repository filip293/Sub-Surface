extends Node3D
var first = true
var first2 = true
var MusicBoxFinish = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if first:
		$MusicBoxFall.play("MusicBoxFall")
		await Globals.calltime(3)
		$AnimationPlayer.play("MusicBox")
		$Song.play()
		first = false
		await Globals.calltime(10)
		$AnimationPlayer.play("MusicBox")
		await Globals.calltime(10)
		$AnimationPlayer.play("MusicBox")
		await Globals.calltime(10)
		$AnimationPlayer.play("MusicBox")
		await Globals.calltime(10)
		$AnimationPlayer.play("MusicBox")
		await Globals.calltime(10)
		$AnimationPlayer.play("MusicBox")
		MusicBoxFinish = true


func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if first2 and MusicBoxFinish:
		$"../Area3D2/ChildrenLaugh".play()
		await Globals.calltime(0.4)
		$"../Area3D2/ChildrenLaugh2".play()
		first2 = false
