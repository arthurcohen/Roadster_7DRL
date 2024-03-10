class_name CarWrapper
extends Node3D

@export var health = 3
@export var bodyMass = 100
@export var wheelRadius = 0.5
@export var suspensionRestLength = 0.9
@export var suspensionMaxLength = suspensionRestLength * 2
@export var suspensionMinLength = suspensionRestLength / 1.5
@export var suspensionFrequency = 1950.0
@export var suspensionDamper = 75.0
@export var suspensionHorizontalOffset = 0.1
@export var maxSpeed = 40.0
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
var frontBumper: Area3D
var rearBumper: Area3D
var roof: Area3D
var crashSFX: AudioStreamPlayer3D
var hitSFX: AudioStreamPlayer3D
var criticalHitSFX: AudioStreamPlayer3D
var engineSFX: AudioStreamPlayer3D
var wheelsSFX: AudioStreamPlayer3D
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
		{"raycast": rlWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 70, "parkBreakGripModifier": 0.6},
		{"raycast": rrWheel, "lastLength": suspensionRestLength - wheelRadius, "traction": true, "grip": 70, "parkBreakGripModifier": 0.6},
	]
	
	frontBumper = body.get_node("FrontBumperArea")
	rearBumper = body.get_node("RearBumperArea")
	roof = body.get_node("RoofArea")
	
	crashSFX = body.get_node("CrashSFX")
	hitSFX = body.get_node("HitSFX")
	criticalHitSFX = body.get_node("CriticalHitSFX")
	engineSFX = body.get_node("EngineSFX")
	wheelsSFX = body.get_node("WheelsSFX")
	
	engineSFX.pitch_scale = randf_range(0.8, 0.9)
	
	body.body_entered.connect(onBodyCollision)


func _process(delta):
#	DebugDraw3D.draw_sphere(body.center_of_mass + body.global_position, wheelRadius, Color.GREEN_YELLOW)
	for wheel in wheels:
		resolveWheelPositions(wheel)

func _physics_process(delta):
	resolveSteering()
	
	var wheelsOnTheGround = 0

	for wheel in wheels:
		if wheel.raycast.is_colliding():
			wheelsOnTheGround += 1
			resolveSuspensionForces(wheel, delta)
			resolveFrictionForces(wheel, delta)
			resolveAccelerationForces(wheel, delta)
			
	if wheelsOnTheGround == 0:
		body.apply_torque(body.global_rotation.z * body.global_transform.basis.z * 200 * -1)
		body.apply_torque(body.global_rotation.x * body.global_transform.basis.x * 300 * -1)
		body.apply_torque(body.global_transform.basis.y * 200 * steeringAxis * -1)
	
	if wheelsOnTheGround > 0 && body.linear_velocity.length_squared() > 0:
		play_wheels_sfx()
	else:
		stop_wheels_sfx()
	

func resolveWheelPositions(wheel):
	var raycast: RayCast3D = wheel.raycast
	if raycast.is_colliding():
		raycast.get_node("Wheel").global_position = lerp(raycast.get_node("Wheel").global_position, raycast.get_collision_point() + body.global_transform.basis.y * wheelRadius, 0.2)
	else:
		raycast.get_node("Wheel").global_position = lerp(raycast.get_node("Wheel").global_position, raycast.global_position - body.global_transform.basis.y * suspensionMaxLength + body.global_transform.basis.y * wheelRadius, 0.1)

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
	if health <= 0:
		return

	var destination = wheel.raycast.get_collision_point()
	var direction = wheel.raycast.global_transform.basis.z
	var point = Vector3(destination.x, destination.y, destination.z)
	
	var force = gasAxis * maxTorque / wheels.filter(func(wheel): return wheel.traction).size() * (turboTorqueModifier if turbo else 1)
	
	if wheel.traction and body.linear_velocity.length() <= maxSpeed * (turboMaxSpeedModifier if turbo else 1):
		body.apply_force(direction * force, point - body.global_position)

func resolveSuspensionForces(wheel: Dictionary, delta: float):
	if health <= 0:
		return
		
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
	
func onBodyCollision(node: Node3D):
	var collidingCar = node.get_parent()
	var collidingSpeed = Vector3.ZERO
	
	if collidingCar is CarWrapper:
		collidingSpeed -= node.linear_velocity
		
		if body.linear_velocity.length_squared() < node.linear_velocity.length_squared():
			var velocityDifference = body.linear_velocity - node.linear_velocity
			# play hit sound
			if velocityDifference.length() > 15:
				# got hit hard
				play_hit_sfx()
				health -= 1
			elif rearBumper.get_overlapping_areas().size() > 0 and velocityDifference.length() > 5:
				# hit from behind
				# play critical hit sound
				play_critical_hit_sfx()
				health -= 1
		else:
			# hit another car
			# play hit sound
			play_crash_sfx()
			# maybe force car who hit to the ground to avoid self flipping
			body.apply_impulse(Vector3.DOWN * 100)
			pass
	
		
	elif body.linear_velocity.length() > 10 and roof.get_overlapping_bodies().size() > 0:
		play_hit_sfx()
		# roof hit
		health -= 1
		
	print(health)
	
func play_crash_sfx():
	_play_sfx(crashSFX, 0.65, 0.8)

func play_hit_sfx():
	_play_sfx(hitSFX, 1.2, 1.3)

func play_critical_hit_sfx():
	_play_sfx(criticalHitSFX, 1.2, 1.3)
	
func play_wheels_sfx():
	if not wheelsSFX.playing:
		wheelsSFX.play(0)
		
	var t = inverse_lerp(0, maxSpeed, body.linear_velocity.length())
	wheelsSFX.pitch_scale = lerp(0.9, 2.0, t)
	
func stop_wheels_sfx():
	wheelsSFX.stop()
		
func _play_sfx(sfx: AudioStreamPlayer3D, min_pitch: float, max_pitch: float):
	if not sfx.playing:
		sfx.pitch_scale = randf_range(min_pitch, max_pitch)
		sfx.play(0)
