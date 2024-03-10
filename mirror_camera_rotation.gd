extends Node3D

@onready var camera: Camera3D = get_viewport().get_camera_3d()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_rotation = camera.global_rotation
