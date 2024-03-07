class_name CarWrapper
extends Node3D

@export var bodyMass = 100
@export var wheelRadius = 0.5
@export var suspensionRestLength = 0.5
@export var suspensionMaxLength = suspensionRestLength * 2
@export var suspensionMinLength = suspensionRestLength / 1.5
@export var suspensionFrequency = 1250.0
@export var suspensionDamper = 50.0
@export var suspensionHorizontalOffset = 0.1
@export var maxSpeed = 20.0
@export var turboMaxSpeedModifier = 1.5
@export var maxTorque = 2200.0
@export var turboTorqueModifier = 1.2
@export var steeringAngle = PI / 3
@export var steeringSpeed: float = 0.1
@export var steeringAssist: float = PI / 5

var flWheel: RayCast3D
var frWheel: RayCast3D
var rlWheel: RayCast3D
var rrWheel: RayCast3D
var wheels: Array[Dictionary]
var body: RigidBody3D
var gasAxis: float = 0
var steeringAxis: float = 0
var parkBreak: bool = false
var turbo: bool = false

func _ready():
	body = get_node("Body")
	body.mass = bodyMass
	
	flWheel = get_node("Body/Wheels/FL")
	flWheel.target_position = Vector3.DOWN * suspensionMaxLength
	flWheel.position = flWheel.position - Vector3.LEFT * suspensionHorizontalOffset
	frWheel = get_node("Body/Wheels/FR")
	frWheel.target_position = Vector3.DOWN * suspensionMaxLength
	frWheel.position = frWheel.position - Vector3.RIGHT * suspensionHorizontalOffset
	rlWheel = get_node("Body/Wheels/RL")
	rlWheel.target_position = Vector3.DOWN * suspensionMaxLength
	rlWheel.position = rlWheel.position - Vector3.LEFT * suspensionHorizontalOffset
	rrWheel = get_node("Body/Wheels/RR")
	rrWheel.target_position = Vector3.DOWN * suspensionMaxLength
	rrWheel.position = rrWheel.position - Vector3.RIGHT * suspensionHorizontalOffset
	
	flWheel.get_node("Wheel").scale = flWheel.get_node("Wheel").scale * wheelRadius
	frWheel.get_node("Wheel").scale = frWheel.get_node("Wheel").scale * wheelRadius
	rlWheel.get_node("Wheel").scale = rlWheel.get_node("Wheel").scale * wheelRadius
	rrWheel.get_node("Wheel").scale = rrWheel.get_node("Wheel").scale * wheelRadius
	
	wheels = [
		{"raycast": flWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 100, "parkBreakGripModifier": 1},
		{"raycast": frWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 100, "parkBreakGripModifier": 1},
		{"raycast": rlWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 80, "parkBreakGripModifier": 0.6},
		{"raycast": rrWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 80, "parkBreakGripModifier": 0.6},
	]
	
	
	pass # Replace with function body.

func _process(delta):
	DebugDraw3D.draw_sphere(body.center_of_mass + body.global_position, wheelRadius, Color.GREEN_YELLOW)

func _physics_process(delta):
	resolveSteering()
	for wheel in wheels:
		resolveWheelPositions(wheel)
		if wheel.raycast.is_colliding():
			resolveSuspensionForces(wheel, delta)
			resolveAccelerationForces(wheel, delta)
			resolveFrictionForces(wheel, delta)
			
func resolveWheelPositions(wheel):
	var raycast: RayCast3D = wheel.raycast
	if raycast.is_colliding():
		raycast.get_node("Wheel").global_position = lerp(raycast.get_node("Wheel").global_position, raycast.get_collision_point() + body.global_transform.basis.y * wheelRadius, 0.15)
	else:
		raycast.get_node("Wheel").global_position = lerp(raycast.get_node("Wheel").global_position, raycast.global_position - body.global_transform.basis.y * suspensionMaxLength + body.global_transform.basis.y * wheelRadius, 0.15)

func resolveSteering():
	if steeringAxis != 0:
		var velocity = body.linear_velocity.length()
		var steeringAssistFactor = velocity / maxSpeed * steeringAssist * steeringAxis
		
		frWheel.rotation.y = lerp(frWheel.rotation.y, (-steeringAngle * steeringAxis) + steeringAssistFactor , steeringSpeed)
		flWheel.rotation.y = lerp(flWheel.rotation.y, (-steeringAngle * steeringAxis) + steeringAssistFactor, steeringSpeed)
	else:
		frWheel.rotation.y = lerp(frWheel.rotation.y, 0.0, steeringSpeed)
		flWheel.rotation.y = lerp(flWheel.rotation.y, 0.0, steeringSpeed)

func resolveFrictionForces(wheel: Dictionary, delta: float):
	var direction = wheel.raycast.global_transform.basis.z
	var velocity = getPointVelocity(body, wheel.raycast.global_position)
	var z_force = clamp(direction.dot(velocity) * body.mass / 10, 0, wheel.grip)
	
	if parkBreak:
		z_force = z_force * wheel.parkBreakGripModifier
	
	body.apply_force(-direction * z_force, wheel.raycast.get_collision_point() - body.global_position)
#	DebugDraw3D.draw_arrow(wheel.raycast.get_collision_point(), wheel.raycast.get_collision_point() + (-direction * z_force), Color.CORAL, 0.1, true)
	
	direction = wheel.raycast.global_transform.basis.x
	
	var lateralVelocity = direction.dot(velocity)
	var x_force = -lateralVelocity * wheel.grip
	
	if parkBreak:
		x_force = x_force * wheel.parkBreakGripModifier
	
	body.apply_force(direction * x_force, wheel.raycast.get_collision_point() - body.global_position)
#	DebugDraw3D.draw_arrow(wheel.raycast.get_collision_point(), wheel.raycast.get_collision_point() + direction * x_force, Color.CORAL, 0.1, true)

func resolveAccelerationForces(wheel: Dictionary, delta: float):
	var destination = wheel.raycast.get_collision_point()
	var direction = wheel.raycast.global_transform.basis.z
	var point = Vector3(destination.x, destination.y, destination.z)
	
	var force = gasAxis * maxTorque / wheels.filter(func(wheel): return wheel.traction).size() * (turboTorqueModifier if turbo else 1)
	
	if wheel.traction and body.linear_velocity.length() <= maxSpeed * (turboMaxSpeedModifier if turbo else 1):
		body.apply_force(direction * force, point - body.global_position)
		
#		DebugDraw3D.draw_arrow(point, point + (direction * force), Color.TURQUOISE, 0.1, true)
	
#	DebugDraw3D.draw_arrow(point, point + (direction * force), Color.GREEN, 0.1, true)
	
var mino = 1
var minl = 1

func resolveSuspensionForces(wheel: Dictionary, delta: float):
	var raycast: RayCast3D = wheel.raycast
	var suspensionDirection = raycast.global_transform.basis.y
	var origin = raycast.global_position
	var destination = raycast.get_collision_point()
	var distance = raycast.get_collision_point().distance_to(raycast.global_position)
	
	var contact = destination - body.global_position
	
	var length = distance - wheelRadius
	
	var offset = suspensionRestLength - length 
	var springForce = (offset * suspensionFrequency)
	
	var point = Vector3(destination.x, destination.y + wheelRadius, destination.z)
	
	var velocity = (wheel.lastLength - length) / delta
	wheel.lastLength = length
	var damperForce = (velocity * suspensionDamper)
	var force = basis.y * (springForce + damperForce)
	
	body.apply_force(suspensionDirection * force, point - body.global_position)
#	DebugDraw3D.draw_line(raycast.global_position, raycast.global_position + Vector3.UP * force, Color.PURPLE)
#	DebugDraw3D.draw_line(raycast.global_position, raycast.global_position - suspensionDirection * 3, Color.DEEP_PINK)
#
#	DebugDraw3D.draw_sphere(raycast.global_position, wheelRadius, Color.ORANGE)
#	DebugDraw3D.draw_sphere(raycast.get_collision_point() + Vector3.UP * wheelRadius, wheelRadius, Color.BLUE)
#	DebugDraw3D.draw_sphere(raycast.global_position + (Vector3.UP * offset), wheelRadius, Color.YELLOW)
#	DebugDraw3D.draw_sphere(raycast.global_position + (Vector3.DOWN * suspensionRestLength) + Vector3.UP * wheelRadius, wheelRadius, Color.DARK_GOLDENROD)

func getPointVelocity(object: RigidBody3D, point: Vector3):
	return object.linear_velocity + object.angular_velocity.cross(point - object.global_position)
