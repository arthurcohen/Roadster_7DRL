@tool
class_name NoiseGeneration
extends Node

@export var generate: bool = false
@export var xdim: int = 100
@export var zdim: int = 100
@export var grid_map: GridMap
@export var noise: FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !generate:
		return
		
	_generate()
			
	generate = false

func _generate():
	for i in range(xdim):
		for j in range(zdim):
			var normalized_x: float = i * 1.0/xdim
			var normalized_z: float = j * 1.0/zdim	
			var noise_value: float = noise.get_noise_2d(normalized_x, normalized_z)
			
			var tile: int = 0
			if noise_value < -0.2:
				tile = 1
			elif noise_value > 0.2:
				tile = 2
			
			grid_map.set_cell_item(Vector3i(i, 0, j), tile)
