@tool
class_name VoronoiGeneration
extends Node

@export var generate: bool = false
@export var num_cells: int = 10
@export var balancing_iterations: int = 5
@export var balancing_factor: float = 2.0
@export var balancing_padding: float = 15.0
@export var xdim: int = 100
@export var zdim: int = 100
@export var grid_map: GridMap

var rng = RandomNumberGenerator.new()

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
	var cells: Array[Vector3] = []
	for i in range(num_cells):
		cells.append(_random_point())
		
	_balance(cells)
	
	#var regions: Array[int] = []
	#for i in range(num_cells):
	#	regions.append(rng.randi_range(0, 2))
	
	for x in range(xdim):
		for z in range(zdim):
			var point = Vector3(x, 0, z)
			var index = _find_nearest(cells, point)
			grid_map.set_cell_item(point, index)
	
func _random_point():
	var x = rng.randi_range(0, xdim)
	var z = rng.randi_range(0, zdim)
	return Vector3(x, 0, z)

func _find_nearest(cells: Array[Vector3], point: Vector3):
	var index: int = 0
	var min_distance: int = -1
	for i in range(cells.size()):
		var current_distance = _norm(cells[i] - point) 
		if min_distance < 0 || current_distance < min_distance:
			index = i
			min_distance = current_distance
	return index
		
func _norm(a: Vector3):
	return abs(a.x) + abs(a.y) + abs(a.z)

func _balance(cells: Array[Vector3]):
	for n in range(balancing_iterations):
		for i in range(cells.size()):
			var displacement: Vector3 = Vector3.ZERO
			for j in range(cells.size()):
				if i == j:
					continue
				var delta = cells[i] - cells[j]
				displacement += balancing_factor/(_norm(delta) + 0.1) * delta.normalized()
			cells[i] += displacement
			cells[i].x = clamp(cells[i].x, balancing_padding, xdim - balancing_padding)
			cells[i].z = clamp(cells[i].z, balancing_padding, zdim - balancing_padding)
