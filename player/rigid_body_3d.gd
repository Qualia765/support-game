extends RigidBody3D

@export var ACCELERATION: float = 0.3
@export var SPEED: float = 6
@export var MOUSE_SENSITIVITY: float = 0.005
@export var JUMP_AMOUNT: float = 8
@export var JUMP_MISS_TIMING_FORGIVNESS_FRAMES: int = 5
@export var ZOOM_SPEED: float = 8
@export var ZOOM_FOV: float = 30
@export var NORMAL_FOV: float = 90
@export var MIN_DOT_NORMAL: float = 0.9

@onready var camera_3d: Camera3D = $Camera3D
@onready var max_foot_loation: Marker3D = $max_foot_loation

var jump_pressed_recently: int = 0
var off_edge_recently: int = 0
var collision_normal: Vector3


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var b: Vector3 = camera_3d.rotation - Vector3(event.screen_relative.y, event.screen_relative.x, 0) * MOUSE_SENSITIVITY
			b.x = clampf(b.x, -1.5, 1.5)
			b.y = fmod(b.y + PI, TAU)-PI
			camera_3d.rotation = b
	if event.is_action_pressed("jump"):
		if off_edge_recently > 0:
			jump_pressed_recently = -1
		else:
			jump_pressed_recently = JUMP_MISS_TIMING_FORGIVNESS_FRAMES


func _process(delta: float) -> void:
	var goal_fov := ZOOM_FOV if Input.is_action_pressed("zoom") else NORMAL_FOV
	camera_3d.fov = lerpf(camera_3d.fov, goal_fov, delta * ZOOM_SPEED)



func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if jump_pressed_recently == -1:
		jump(state)
		jump_pressed_recently = 0
	
	if state.get_contact_count() != 0:
		collision_normal = Vector3.ZERO
		var foot_collision_normal := Vector3.ZERO
		for i in range(state.get_contact_count()):
			collision_normal += state.get_contact_local_normal(i)
			if state.get_contact_collider_position(i).y - global_position.y < max_foot_loation.position.y:
				foot_collision_normal += state.get_contact_local_normal(i)
		collision_normal = collision_normal.normalized()
		foot_collision_normal = foot_collision_normal.normalized()
		
		if jump_pressed_recently > 0:
			jump_pressed_recently = 0
			jump(state)
		
		if not foot_collision_normal.is_zero_approx():
			if foot_collision_normal.y > MIN_DOT_NORMAL:
				var foward := camera_3d.basis.x.cross(Vector3.UP).normalized()
				var left := foward.cross(Vector3.UP).normalized()
				var goal_velocity := (left * Input.get_axis("right", "left") + foward * Input.get_axis("foward", "back")) * SPEED
				linear_velocity -= (linear_velocity - goal_velocity).normalized() * ACCELERATION
			else:
				print("too much!")
		
		off_edge_recently = JUMP_MISS_TIMING_FORGIVNESS_FRAMES
	else:
		if off_edge_recently > 0:
			off_edge_recently -= 1
		
		if jump_pressed_recently > 0:
			jump_pressed_recently -= 1
	
	if position.y == NAN or not position.is_finite():
		position = Vector3(0, 10, 0)
		linear_velocity = Vector3.ZERO
	
	if position.y < -10:
		linear_velocity = -position.normalized() * 10
		linear_velocity.y += 20
		position.y = -10


func jump(state: PhysicsDirectBodyState3D):
	linear_velocity += collision_normal * JUMP_AMOUNT
