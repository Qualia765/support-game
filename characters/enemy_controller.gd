extends Node

@onready var agent: NavigationAgent3D = $"../NavigationAgent3D"
@onready var player: Character = $".."
@onready var eye: Node3D = $"../eye"

var time_till_recalculate: float = 0.

func _ready():
	player.movement_vector = func(): return Vector2(-1, 0)
	#player.movement_vector = func(): return Input.get_vector("right", "left", "foward", "back")


func _physics_process(delta: float) -> void:
	# every 2 seconds set the target to be where the player is
	time_till_recalculate -= delta
	if time_till_recalculate < 0:
		time_till_recalculate = 2. + randf()
		agent.target_position = get_tree().get_first_node_in_group(&"player").global_position
	
	player.facing = (agent.get_next_path_position() - player.global_position).normalized()
	var basis_z = -player.facing
	var basis_x = Vector3(1.238947,0.1967823,0.78234).cross(basis_z).normalized()
	var basis_y = basis_x.cross(basis_z).normalized()
	eye.basis = Basis(basis_x, basis_y, basis_z)
	
	if randf() < 0.002 or player.off_edge_recently == player.JUMP_MISS_TIMING_FORGIVNESS_FRAMES - 2:
		player.jump()
