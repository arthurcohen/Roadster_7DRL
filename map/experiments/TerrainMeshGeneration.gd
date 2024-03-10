@tool
extends MeshInstance3D

@export var generate: bool = false
@export var collision_shape: CollisionShape3D
@export var height_scale: float = 1
@export var uv_scale: Vector2 = Vector2.ONE
@export var size: int = 100
@export var noise: FastNoiseLite

var surface_tool = SurfaceTool.new()

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
			var x = i - (size - 1.0)/2.0
			var z = j - (size - 1.0)/2.0
			
			var height = noise.get_noise_2d(x, z) * height_scale
			var vertex = Vector3(x, height, z)
			
			surface_tool.set_uv(Vector2(x, z) / uv_scale)
			surface_tool.add_vertex(vertex)
			
			var index = i + j * size
			heightmap[index] = height
 
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()

	var heightmapShape = HeightMapShape3D.new()
	
	heightmapShape.map_width = size
	heightmapShape.map_depth = size
	heightmapShape.map_data = heightmap
	
	collision_shape.shape = heightmapShape

