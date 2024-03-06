extends Node3D

var carWrapper: CarWrapper

func _ready():
	carWrapper = get_node("CarWrapper")


func _process(delta):
	var gasAxis = Input.get_axis("reverse", "gas")
	carWrapper.gasAxis = gasAxis
	
	var steeringAxis = Input.get_axis("left", "right")
	carWrapper.steeringAxis = steeringAxis
	
	carWrapper.parkBreak = Input.is_action_pressed("parkBreak")
	
	carWrapper.turbo = Input.is_action_pressed("turbo")
