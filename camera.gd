extends Camera3D

@export var targetToFollow: Node3D
@export var targetToFollowLookWeight: float = 3.0
@export var targetsToLook: Array[Node3D]
@export var nodeQuery: String
@export var distance = 7
@export var height = 4

var targetToFollowNode: Node3D
var targetsToLookNodes: Array[Node3D] = []
var lockedOn: bool = false

func _ready():
	targetToFollowNode = targetToFollow.get_node(nodeQuery)
	
	for index in range(targetsToLook.size()):
		targetsToLookNodes.append(targetsToLook[index].get_node(nodeQuery))
		
func _process(delta):
	if Input.is_action_just_pressed("change_camera"):
		lockedOn = !lockedOn

func _physics_process(delta):
	var lookAxis = Input.get_axis("look_left", "look_right")
	
#	var lockedOn = targetsToLookNodes.size() > 0

	if targetToFollowNode != null:
		var lookAtPosition = targetToFollowNode.global_position * targetToFollowLookWeight # add weight to the target to follow
		
		if lockedOn:
			for targetToLookNode in targetsToLookNodes:
				lookAtPosition += targetToLookNode.global_position
			
		var desiredPosition = targetToFollowNode.global_position - global_position													# position camera relative to target to follow
		desiredPosition -= (lookAtPosition if lockedOn else Vector3.ZERO)															# offset by targets to look
		desiredPosition += global_transform.basis.x * lookAxis * 10 																# rotate if axis
		desiredPosition = targetToFollowNode.global_position - desiredPosition.normalized() * distance * (2 if lockedOn else 1) 	# normalize by distance
		desiredPosition.y = targetToFollowNode.global_position.y + height * (2 if lockedOn else 1)									# add height
		
		var newPosition = lerp(global_position, Vector3(desiredPosition.x, desiredPosition.y, desiredPosition.z), 0.07)
		global_position = newPosition # positionate camera

		lookAtPosition /= (targetsToLookNodes.size() if lockedOn else 0) + targetToFollowLookWeight
		look_at(lookAtPosition) # rotate camera
