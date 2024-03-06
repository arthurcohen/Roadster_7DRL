extends Camera3D

@export var target: Node3D
@export var nodeQuery: String
@export var distance = 7
@export var height = 4

var targetNode

# Called when the node enters the scene tree for the first time.
func _ready():
	targetNode = target.get_node(nodeQuery)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if targetNode != null:
		var desiredPosition = targetNode.global_position - ((targetNode.global_position - global_position).normalized() * distance)
		var newPosition = lerp(global_position, Vector3(target.global_position.x + desiredPosition.x, targetNode.global_position.y + height, target.global_position.z + desiredPosition.z), 0.07)
		global_position = newPosition
		
		look_at(targetNode.global_position)
