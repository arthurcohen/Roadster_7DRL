@tool
extends MeshInstance3D

@export var generate: bool = false
@export var mesh_grid_size: int = 100

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
	_generate_terrain()
	
	var temperature_map = _generate_blobs(5)
	var altitude_map = _generate_blobs(5)
	var humidity_map = _generate_blobs(5)
	
	var environment_map = _to_image(temperature_map, altitude_map, humidity_map)
	
	var shader_material = self.material_override as ShaderMaterial
	shader_material.set_shader_parameter("environment_map", environment_map)

func _to_image(channel1: Array[float], channel2: Array[float], channel3: Array[float]) -> ImageTexture:
	var image = Image.create(mesh_grid_size, mesh_grid_size, false, Image.FORMAT_RGB8)
	
	for i in range(mesh_grid_size):
		for j in range(mesh_grid_size):
			var index = _get_index(Vector2(i, j))
			var color = Color(channel1[index], channel2[index], channel3[index])
			image.set_pixel(i, j, color)
			
	return ImageTexture.create_from_image(image)

func _generate_blobs(num_blobs: int, falloff: float = 0.95) -> Array[float]:
	var accumulated_map: Array[float] = []
	accumulated_map.resize(mesh_grid_size * mesh_grid_size)
	
	var lower_limit = 0;
	var upper_limit = mesh_grid_size-1;
	
	for n in range(num_blobs):
		var x = randi_range(lower_limit, upper_limit)
		var z = randi_range(lower_limit, upper_limit)
		_expand_blob(Vector2i(x, z), accumulated_map, falloff)
	
	return accumulated_map

func _expand_blob(center: Vector2i, map: Array[float], falloff: float):
	var queue = []
	queue.push_back(center)

	while queue.size() > 0:
		var coord = queue.pop_front()
		var strength = falloff ** _norm(center - coord)
		var index = _get_index(coord)		
		map[index] += strength

		for i in range(-1, 2):
			for j in range(-1, 2):
				var neighbor = coord + Vector2i(i, j)
				
				# skip invalid neighbors
				if !_valid_position(neighbor):
					continue
				
				# skip already processed neighbors
				if map[index] > 0.0 || queue.find(neighbor) >= 0:
					continue
									
				queue.push_back(neighbor)

func _norm(v: Vector2i) -> float:
	return v.length()	
			
func _valid_position(coords: Vector2i) -> bool:
	return coords.x >= 0 && coords.x < mesh_grid_size && coords.y >= 0 && coords.y < mesh_grid_size

func _get_index(coords: Vector2i) -> int:
	return coords.x + mesh_grid_size * coords.y

func _generate_terrain():
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(mesh_grid_size - 1):
		for z in range(mesh_grid_size - 1):
			var i = x + z * mesh_grid_size
		
			surface_tool.add_index(i)
			surface_tool.add_index(i+mesh_grid_size)
			surface_tool.add_index(i+1)
			
			surface_tool.add_index(i+1)
			surface_tool.add_index(i+mesh_grid_size)
			surface_tool.add_index(i+mesh_grid_size+1)
			
	
	for x in range(mesh_grid_size):
		for z in range(mesh_grid_size):
			var vertex = Vector3(x, 0, z)
			
			surface_tool.set_uv(Vector2(x, z))
			surface_tool.add_vertex(vertex)
 
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
