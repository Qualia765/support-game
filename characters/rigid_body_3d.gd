class_name Character extends RigidBody3D

var facing: Vector3 = Vector3.FORWARD
var movement_vector: Callable = func(): return Vector2(0, -1)
var alt_impact_sound: bool = false

signal actually_jumped

## call when the player/ai wanna jump
func jump():
	if off_edge_recently > 0:
		jump_pressed_recently = -1
	else:
		jump_pressed_recently = JUMP_MISS_TIMING_FORGIVNESS_FRAMES

# Public API
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# Internals

const ACCELERATION: float = 0.3
const SPEED: float = 6
const JUMP_AMOUNT: float = 8
const JUMP_MISS_TIMING_FORGIVNESS_FRAMES: int = 5
## used for the maximum climbable slope
## eg: cos(36deg) = 0.8
const MIN_DOT_NORMAL: float = 0.8
const MIN_COLLISION_SPEED_FOR_IMPACT: float = 2.
const MAX_COLLISION_SPEED_FOR_IMPACT: float = 12.
const MIN_WIND_SPEED: float = 4.
const MAX_WIND_SPEED: float = 16.
## any collisions below this are considered part of foot collisions
## for determining if movement is allowed
const MAX_FOOT_LOCATION: float = -0.46

@onready var sound_wind: Node = $SoundWind
@onready var sound_big_doing: Node = $SoundBigDoing

const SOFT_IMPACT = preload("uid://dn018lwvhepwn")
const MEDIUM_IMPACT = preload("uid://deweykc4qspfs")
const HARD_IMPACT = preload("uid://28qwnsxmorew")
const DOING = preload("uid://cnq4aimj0bwjf")

## positive number is number of frames before contact must be made to instant jump (reverse coyote time)
## a positive number counts down each frame
## 0 means no jump
## -1 means jump right now regardless of circumstance (set when jumping if you press a little too late)
var jump_pressed_recently: int = 0
## when your on the edge this is JUMP_MISS_TIMING_FORGIVNESS_FRAMES
## when your off it counts down
## while it is positive (cyocoyotetee time)
var off_edge_recently: int = 0

## store the current/previous normal to be used for jumping
var collision_normal: Vector3
## used for impact sounds
var previous_velocity: Vector3 = Vector3(0, 0, 0)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#region impact
	if linear_velocity.distance_to(previous_velocity) > MIN_COLLISION_SPEED_FOR_IMPACT and state.get_contact_count() != 0:
		var impact_amount: float = inverse_lerp(
			MIN_COLLISION_SPEED_FOR_IMPACT, MAX_COLLISION_SPEED_FOR_IMPACT,
			linear_velocity.distance_to(previous_velocity)
		)
		var volume: float = lerp(-25, 0, tanh(impact_amount))
		var scene: PackedScene
		if impact_amount > 1.:
			scene = HARD_IMPACT
		elif impact_amount > 0.5:
			scene = MEDIUM_IMPACT
		else:
			scene = SOFT_IMPACT
		
		var impact_nodes := scene.instantiate()
		impact_nodes.position = global_basis .inverse() * state.get_contact_local_position(0)
		impact_nodes.volume = volume
		impact_nodes.alt_style = alt_impact_sound
		var basis_z = global_basis.inverse() * state.get_contact_local_normal(0)
		var basis_x = Vector3(1.238947,0.1967823,0.78234).cross(basis_z).normalized()
		var basis_y = basis_x.cross(basis_z).normalized()
		impact_nodes.basis = Basis(basis_x, basis_y, basis_z)
		impact_nodes.position += basis_z * 0.2
		get_tree().root.add_child(impact_nodes)
	#endregion
	#region wind sounds
	var should_make_sounds: bool = linear_velocity.length() > MIN_WIND_SPEED
	if should_make_sounds != sound_wind.playing:
		sound_wind.playing = should_make_sounds
	if should_make_sounds:
		var intensity = tanh(inverse_lerp(
			MIN_WIND_SPEED, MAX_WIND_SPEED,
			linear_velocity.length()
		))
		sound_wind.pitch_scale = sqrt(linear_velocity.length() / MAX_WIND_SPEED)
		sound_wind.volume_db = lerpf(-50, -10, intensity)
	#endregion
	
	var gotta_jump: bool = false
	
	# if u pressed it just a little late
	if jump_pressed_recently == -1:
		jump_pressed_recently = 0
		gotta_jump = true
	
	if state.get_contact_count() != 0:
		collision_normal = Vector3.ZERO
		var foot_collision_normal := Vector3.ZERO
		for i in range(state.get_contact_count()):
			collision_normal += state.get_contact_local_normal(i)
			if state.get_contact_collider_position(i).y - global_position.y < MAX_FOOT_LOCATION:
				foot_collision_normal += state.get_contact_local_normal(i)
		collision_normal = collision_normal.normalized()
		foot_collision_normal = foot_collision_normal.normalized()
		
		# if you press it on time or early
		if jump_pressed_recently > 0:
			jump_pressed_recently = 0
			gotta_jump = true
		
		if not foot_collision_normal.is_zero_approx():
			if foot_collision_normal.y > MIN_DOT_NORMAL:
				var foward := facing.cross(Vector3.UP).normalized()
				var left := foward.cross(Vector3.UP).normalized()
				var current_movement_vector: Vector2 = movement_vector.call()
				var goal_velocity := (left * current_movement_vector.x + foward * current_movement_vector.y) * SPEED
				linear_velocity -= (linear_velocity - goal_velocity).normalized() * ACCELERATION
		
		off_edge_recently = JUMP_MISS_TIMING_FORGIVNESS_FRAMES
	else:
		if off_edge_recently > 0:
			off_edge_recently -= 1
		
		if jump_pressed_recently > 0:
			jump_pressed_recently -= 1
	
	if gotta_jump:
		linear_velocity += collision_normal * JUMP_AMOUNT
		jump_pressed_recently = 0
		off_edge_recently = 0
		
		var impact_nodes := DOING.instantiate()
		impact_nodes.position = global_position
		var basis_z = -collision_normal
		var basis_x = Vector3(1.238947,0.1967823,0.78234).cross(basis_z).normalized()
		var basis_y = basis_x.cross(basis_z).normalized()
		impact_nodes.basis = Basis(basis_x, basis_y, basis_z)
		get_tree().root.add_child(impact_nodes)
		
		actually_jumped.emit()
	
	if position.y == NAN or not position.is_finite():
		position = Vector3(0, 10, 0)
		linear_velocity = Vector3.ZERO
	
	if position.y < -10:
		if position.x > 24:
			linear_velocity = -position.normalized() * 10
			linear_velocity.y += 20
		else:
			linear_velocity = Vector3(15, 15, 0)
		position.y = -10
		sound_big_doing.play()
	
	previous_velocity = linear_velocity
