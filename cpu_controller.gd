extends Node3D

@export var cpuAwareness = 1.0 			# how cpu responds to player positioning and movement in reltion to its own position and movement
@export var cpuAgressiviness = 0.0 		# how much the cpu tends to hit the player
@export var cpuSafeRadius = 15.0		# distance that a non-agressive cpu will keep from player
@export var cpuSkills = 1.0 			# how good the cpu handles the car

var cpuCarWrapper: CarWrapper
var cpuCarBody: RigidBody3D
var playerNode: Node3D
var playerCarWrapper: CarWrapper
var playerCarBody: RigidBody3D

func _ready():
	cpuCarWrapper = get_node("CarWrapper")
	cpuCarBody = cpuCarWrapper.get_node("Body")
	
	playerNode = get_parent().get_node("Player")
	playerCarWrapper = playerNode.get_node("CarWrapper")
	playerCarBody = playerCarWrapper.get_node("Body")
	
func _process(delta):
	
	var distanceToPlayer = cpuCarBody.global_position.distance_to(playerCarBody.global_position)
	
	var playerCarBodyEstimatedPosition = playerCarBody.global_position
	playerCarBodyEstimatedPosition += (playerCarBody.global_transform.basis.z * distanceToPlayer * playerCarBody.linear_velocity.dot(playerCarBody.global_transform.basis.z) / 30) * cpuAwareness
	
	DebugDraw3D.draw_sphere(playerCarBodyEstimatedPosition, 0.5, Color.RED)
	
	var playerDirection = cpuCarBody.global_transform.basis.z.signed_angle_to(playerCarBodyEstimatedPosition - cpuCarBody.global_position , Vector3.DOWN)
	cpuCarWrapper.steeringAxis = clamp(playerDirection, -1, 1)
	
	# TODO: 
	# if facingPlayerDirectly, be agro
	# if backFacingPlayer, be passive

	#var gasAxis = ((playerDirection / PI) ** 2) + cpuAgressiviness - (1 if distanceToPlayer < cpuSafeRadius else 0)
	cpuCarWrapper.gasAxis = 1 - (1 - cpuAgressiviness) * 0.5
	
#	DebugDraw3D.draw_line(cpuCarBody.global_position, playerCarBody.global_position, Color.LAWN_GREEN)
#	DebugDraw3D.draw_sphere((cpuCarBody.global_position + playerCarBody.global_position * 4) / 5, 0.5, Color.RED)
