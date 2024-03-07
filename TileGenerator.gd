@tool
extends Node

@export var generate: bool = false
@export var num_tiles: int = 10
@export var colors: Array[Color] = [
	Color.AQUA,
	Color.BLUE_VIOLET,
	Color.LIGHT_CORAL,
	Color.DARK_GREEN,
	Color.DARK_ORANGE,
	Color.FIREBRICK,
	Color.CADET_BLUE,
	Color.BEIGE,
	Color.DEEP_PINK,
	Color.BLACK
]


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
	_clear()
	
	for i in range(num_tiles):
		var material = StandardMaterial3D.new()
		material.albedo_color = _get_color(i)
		
		var mesh = PlaneMesh.new()
		mesh.material = material
		
		var tile = MeshInstance3D.new()
		tile.mesh = mesh
		
		add_child(tile, true)
		tile.owner = self
		tile.transform.origin.x = 2*i
		
		
func _clear():
	for n in get_children():
		remove_child(n)
		n.queue_free()

func _get_color(index: int) -> Color:
	return colors[index]
