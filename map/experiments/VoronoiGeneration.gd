@tool
class_name VoronoiGeneration
extends Node

@export var generate: bool = false
@export var padding: int = 10
@export var xdim: int = 100
@export var zdim: int = 100
@export var grid_map: GridMap

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	_generate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !generate:
		return
		
	_generate()
			
	generate = false

func _generate():
	var cells: Array[Vector3] = []
	
	var grass_region_start = _random_point(Vector2(xdim/5, zdim/5), 5)
	var grass_region_boss = _random_point(Vector2(xdim/3, zdim/3), 10)
	var sand_region_start = _random_point(Vector2(4*xdim/5, 3*zdim/5), 10) 
	var sand_region_boss = _random_point(Vector2(4*xdim/5, zdim/5), 10)
	var mountain_region_start = _random_point(Vector2(3*xdim/5, 4*zdim/5), 10)
	var mountain_region_boss = _random_point(Vector2(xdim/5, 4*zdim/5), 10)
	
	cells.append(grass_region_start)
	cells.append(grass_region_boss)
	cells.append(sand_region_start)
	cells.append(sand_region_boss)
	cells.append(mountain_region_start)
	cells.append(mountain_region_boss)
	
	for x in range(xdim):
		for z in range(zdim):
			var point = Vector3(x, 0, z)
			var index = _find_nearest(cells, point)
			grid_map.set_cell_item(point, index)
	
func _random_point(center: Vector2, radius: float) -> Vector3:
	var diag = Vector2(radius, radius)
	var bottom_left = center - diag
	var top_right = center + diag
	var x = rng.randf_range(bottom_left.x, top_right.x)
	var z = rng.randf_range(bottom_left.y, top_right.y)
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
