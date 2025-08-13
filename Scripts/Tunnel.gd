extends Node3D

@export var segment_length := 7.0
@export var speed := 10.0
@export var initial_z_offset := 2.4  # New variable to control initial Z offset

var tunnel_segments: Array[Node3D] = []
var total_tunnel_length: float

func _ready():
	# Initialize tunnel segments
	for i in range(1, 33):
		var name = "TunnelSegment%d" % i
		if has_node(name):
			var segment = get_node(name) as Node3D
			
			# Position segments along X as before, but add initial Z offset
			segment.position = Vector3(-segment_length * (i - 1), 0, initial_z_offset)
			
			tunnel_segments.append(segment)
		else:
			push_error("Missing tunnel segment: %s" % name)
	
	if not tunnel_segments.is_empty():
		total_tunnel_length = segment_length * tunnel_segments.size()

func _process(delta):
	if tunnel_segments.is_empty():
		return

	for segment in tunnel_segments:
		# Move each segment forward along +X
		segment.position.x += speed * delta

		# Recycle the segment as soon as its origin passes x=0.
		while segment.position.x > 0:
			segment.position.x -= total_tunnel_length
