@tool
extends Node

@export var generate: bool = false
@export var height_scale: float
@export var uv_scale: Vector2
@export var size: int = 100
@export var terrain_mesh: MeshInstance3D
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
			
	
	for x in range(size):
		for z in range(size):
			var height = noise.get_noise_2d(x, z) * height_scale
			var vertex = Vector3(x, height, z)
			
			surface_tool.set_uv(Vector2(x, z) / uv_scale)
			surface_tool.add_vertex(vertex)
 
	surface_tool.generate_normals()
	
	terrain_mesh.mesh = surface_tool.commit()

