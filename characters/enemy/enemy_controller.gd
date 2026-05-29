extends Node

const ANIMATION_SPEED_CHANGE: float = 5.
const DISTANCE_NEEDED_TO_ATTACK: float = 3
const ATTACK_ANIMATION_LENGTH: float = 1.4583

@onready var agent: NavigationAgent3D = $"../NavigationAgent3D"
@onready var body: Character = $".."
@onready var eye: Node3D = $"../eye"
@onready var shape_cast_3d: ShapeCast3D = $"../ShapeCast3D"
@onready var knight_girl: Node3D = $"../KnightGirl"
@onready var animation_tree: AnimationTree = $"../AnimationTree"

## -1 mean not attacking
## 0+ means attacking, where the number is how far along in the animation it is
var attack_state: float = -1

var time_till_recalculate: float = 0.
var was_actually_grounded_last_frame: bool = false

func _ready():
	body.movement_vector = func(): return Vector2(-1.5, 0)


func _physics_process(delta: float) -> void:
	var is_actually_grounded: bool = shape_cast_3d.is_colliding()
	var became_actually_grounded_this_frame: bool = not was_actually_grounded_last_frame and is_actually_grounded
	var target: Vector3 =  get_tree().get_first_node_in_group(&"player").global_position
	
	# every 2 seconds set the target to be where the body is
	time_till_recalculate -= delta
	if time_till_recalculate < 0 or became_actually_grounded_this_frame:
		time_till_recalculate = 2. + randf()
		agent.target_position = target
	
	body.facing = (agent.get_next_path_position() - body.global_position).normalized()
	
	
	var basis_y = Vector3.UP
	var basis_x = -body.facing.cross(basis_y).normalized()
	var basis_z = basis_x.cross(basis_y).normalized()
	knight_girl.basis = Basis(basis_x, basis_y, basis_z) * 0.265
	
	if randf() < 0.002 or (
		body.off_edge_recently < body.JUMP_MISS_TIMING_FORGIVNESS_FRAMES
		and body.off_edge_recently != 0
		and not is_actually_grounded
	):
		body.jump()
	
	was_actually_grounded_last_frame = is_actually_grounded
	
	var blend_idle_walk_down_up: Vector2 = animation_tree.get("parameters/IdleWalkDownUp/blend_position")
	blend_idle_walk_down_up = blend_idle_walk_down_up.move_toward(Vector2(1 if is_actually_grounded else -1, 1), delta * ANIMATION_SPEED_CHANGE)
	animation_tree.set("parameters/IdleWalkDownUp/blend_position", blend_idle_walk_down_up)
	
	if target.distance_to(body.global_position) < DISTANCE_NEEDED_TO_ATTACK and attack_state == -1:
		
		attack_state = 0
		animation_tree.set("parameters/AttackSeek/seek_request", 0.)
	
	
	var attack_blend_amount: float
	if attack_state == -1:
		attack_blend_amount = 0
	else:
		attack_blend_amount = attack_state
		attack_blend_amount = min(attack_blend_amount, ATTACK_ANIMATION_LENGTH - attack_state)
		attack_blend_amount = clampf(attack_blend_amount * ANIMATION_SPEED_CHANGE, 0., 1.)
		attack_state += delta
		if attack_state > ATTACK_ANIMATION_LENGTH:
			attack_state = -1
	animation_tree.set("parameters/AttackBlend/blend_amount", attack_blend_amount)
	
