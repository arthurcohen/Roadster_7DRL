extends Node3D

@export var cpuAwareness = 1.0 			# how cpu responds to player positioning and movement in reltion to its own position and movement
@export var cpuAgressiviness = 0.0 		# how much the cpu tends to hit the player
@export var cpuFOV = PI / 3
@export var cpuSightDistance = 40
@export var cpuAgressivinessDecayRate = 0.2 		# how much the cpu tends to hit the player
@export var cpuSafeRadius = 15.0		# distance that a non-agressive cpu will keep from player
@export var cpuSkills = 1.0 			# how good the cpu handles the car

var cpuCarWrapper: CarWrapper
var cpuCarBody: RigidBody3D
var cpuVisionArea: Area3D
var playerNode: Node3D
var playerCarWrapper: CarWrapper
var playerCarBody: RigidBody3D
var playerOnSight: bool = false

var spaceState: PhysicsDirectSpaceState3D 

func _ready():
	cpuCarWrapper = get_node("CarWrapper")
	cpuCarBody = cpuCarWrapper.get_node("Body")
	cpuVisionArea = cpuCarBody.get_node("Area3D")
	
#	cpuVisionArea.body_entered.connect(onBodyEntered)
#	cpuVisionArea.body_exited.connect(onBodyExited)
	
	playerNode = get_parent().get_node("Player")
	playerCarWrapper = playerNode.get_node("CarWrapper")
	playerCarBody = playerCarWrapper.get_node("Body")
	
	spaceState = get_world_3d().direct_space_state
	
func _physics_process(delta):
	var distanceToPlayer = cpuCarBody.global_position.distance_to(playerCarBody.global_position)
	
	var playerCarBodyEstimatedPosition = playerCarBody.global_position
	playerCarBodyEstimatedPosition += (playerCarBody.global_transform.basis.z * distanceToPlayer * playerCarBody.linear_velocity.dot(playerCarBody.global_transform.basis.z) / 30) * cpuAwareness
	
	DebugDraw3D.draw_sphere(playerCarBodyEstimatedPosition, 0.5, Color.RED)
	
	var playerDirection = cpuCarBody.global_transform.basis.z.signed_angle_to(playerCarBodyEstimatedPosition - cpuCarBody.global_position , Vector3.DOWN)
	cpuCarWrapper.steeringAxis = clamp(playerDirection, -1, 1)
	
	if abs(playerDirection) < cpuFOV and distanceToPlayer < cpuSightDistance:
		var query = PhysicsRayQueryParameters3D.create(cpuCarBody.global_position, playerCarBody.global_position)
		var result = spaceState.intersect_ray(query)
		playerOnSight = result.collider.get_collision_layer_value(4)
	else: 
		playerOnSight = false
	
	# TODO: 
	# if facingPlayerDirectly, be agro
	# if backFacingPlayer, be passive

	#var gasAxis = ((playerDirection / PI) ** 2) + cpuAgressiviness - (1 if distanceToPlayer < cpuSafeRadius else 0)
	cpuCarWrapper.gasAxis = cpuAgressiviness
	
	if playerOnSight:
		cpuAgressiviness = 1
	elif cpuAgressiviness > 0:
		cpuAgressiviness = clamp(cpuAgressiviness - (cpuAgressivinessDecayRate * delta), 0, 1)
#
	print(cpuAgressiviness)
	
#	DebugDraw3D.draw_line(cpuCarBody.global_position, playerCarBody.global_position, Color.LAWN_GREEN)
#	DebugDraw3D.draw_sphere((cpuCarBody.global_position + playerCarBody.global_position * 4) / 5, 0.5, Color.RED)

func onBodyEntered(target):
	cpuAgressiviness = 1
	playerOnSight = true

func onBodyExited(target):
	playerOnSight = false
