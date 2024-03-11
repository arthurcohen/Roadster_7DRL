@tool
extends MeshInstance3D

@export var generate: bool = false
@export var height_scale: float = 1
@export var uv_scale: Vector2 = Vector2.ONE
@export var size: int = 100
@export var weights: Array[float] = []
@export var noises: Array[FastNoiseLite] = []
@export var interest_radius: float = 0.8
@export var sand_depth: float = 0.1
@onready var collision_shape: CollisionShape3D = get_node("StaticBody3D/CollisionShape3D")
@onready var pyramid: Node3D = get_node("Pyramid")
@onready var obelisk: Node3D = get_node("Monolith")
@onready var ruins: Node3D = get_node("Ruins")

var surface_tool: SurfaceTool = SurfaceTool.new()
var interest_spots: PackedVector3Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		_generate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint() && interest_spots.size() > 0:
		DebugDraw3D.draw_points(interest_spots, DebugDraw3D.POINT_TYPE_SQUARE, 15.0, Color.DEEP_PINK)
	
	if !generate:
		return
		
	_generate()
			
	generate = false

func _generate():
	if noises.size() != weights.size():
		push_error("noises.size() != weights.size()")
		return
	
	for noise in noises:
		if noise:
			noise.seed = randi()

	var heightmap: PackedFloat32Array = []
	heightmap.resize(size * size)
	
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(size - 1):
		for z in range(size - 1):
			var i = x + z * size
		
			surface_tool.add_index(i)
			surface_tool.add_index(i+size)
			surface_tool.add_index(i+1)
			
			surface_tool.add_index(i+1)
			surface_tool.add_index(i+size)
			surface_tool.add_index(i+size+1)
			
	
	for i in range(size):
		for j in range(size):
			var position = _get_position(i, j)
			
			var accumulated = 0.0
			var totalWeight = 0.0
			for k in range(noises.size()):
				accumulated += noises[k].get_noise_2dv(position) * weights[k]
				totalWeight += weights[k]
				
			var height = accumulated / totalWeight * height_scale
			var vertex = Vector3(position.x, height, position.y)
			
			surface_tool.set_uv(position / uv_scale)
			surface_tool.add_vertex(vertex)
			
			var index = _get_index(i, j)
			heightmap[index] = height - sand_depth
 
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()

	var heightmapShape = HeightMapShape3D.new()
	
	heightmapShape.map_width = size
	heightmapShape.map_depth = size
	heightmapShape.map_data = heightmap
	
	collision_shape.shape = heightmapShape
	
	var interest_spots: Array[Vector3] = [] 
	interest_spots.clear()
	
	for i in range(1, size-1):
		for j in range(1, size-1):			
			var position = _get_position(i, j)
			
			var index = _get_index(i, j)
			var height = heightmap[index]
			
			var neighbors = [
				Vector2i(-1, -1),
				Vector2i(-1, 0),
				Vector2i(-1, 1),
				Vector2i(0, -1),
				Vector2i(0, 1),
				Vector2i(1, -1),
				Vector2i(1, 0),
				Vector2i(1, 1)
			].map(func(delta): return Vector2i(i, j) + delta)
			var lowest_height: float = height
			for neighbor in neighbors:
				var neighbor_index = _get_index(neighbor.x, neighbor.y)
				if heightmap[neighbor_index] < lowest_height:
					lowest_height = heightmap[neighbor_index]
			
			if abs(lowest_height - height) < 0.01:
				interest_spots.push_back(Vector3(position.x, height, position.y))

	pyramid.position = _closest_point(interest_spots, (Vector3.RIGHT * interest_radius * size/2.0).rotated(Vector3.UP, randf_range(0, PI/2)))
	obelisk.position = _closest_point(interest_spots, pyramid.position.rotated(Vector3.UP, 2*PI/3))
	ruins.position = _closest_point(interest_spots, pyramid.position.rotated(Vector3.UP, -2*PI/3))
	ruins.look_at(Vector3.ZERO, Vector3.UP, true)
	
	self.interest_spots = PackedVector3Array(interest_spots.map(func(point): return self.to_global(point)))

func _closest_point(points: Array[Vector3], ref: Vector3) -> Vector3:
	var closest: Vector3 = points[0]
	for point in points:
		if point.distance_to(ref) < closest.distance_to(ref) && point.length() <= interest_radius * size/2.0:
			closest = point
	return closest

func _avg_dist(from: Vector3, to1: Vector3, to2: Vector3) -> float:
	var d1 = from.distance_to(to1)
	var d2 = from.distance_to(to2)
	return 1.0/abs(d1 - d2) * (d1 + d2) / 2.0
	
func _get_index(i: int, j: int) -> int:
	return i + j * size	
				
func _get_position(i: int, j: int) -> Vector2:
	var x = i - (size - 1.0)/2.0
	var z = j - (size - 1.0)/2.0
	
	return Vector2(x, z)
