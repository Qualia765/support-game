extends Node

const MOUSE_SENSITIVITY: float = 0.005
const ZOOM_SPEED: float = 6
const ZOOM_FOV: float = 20
const NORMAL_FOV: float = 90
const ANIMATION_SPEED_CHANGE: float = 5.

@onready var player: Character = $".."
@onready var camera_3d: Camera3D = $"../CenterOfYRotation/Camera3D"
@onready var sound_zoom: AudioStreamPlayer = $"../SoundZoom"
@onready var animation_tree: AnimationTree = $"../AnimationTree"
@onready var supportgirl: Node3D = $"../CenterOfYRotation/supportgirl"
@onready var center_of_y_rotation: Node3D = $"../CenterOfYRotation"


func _ready():
	player.movement_vector = func(): return Input.get_vector("right", "left", "foward", "back")
	player.alt_impact_sound = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var real_sensitivity: float = camera_3d.fov / NORMAL_FOV * MOUSE_SENSITIVITY
			center_of_y_rotation.rotation.y -= event.screen_relative.x * real_sensitivity
			camera_3d.rotation.x = clampf(camera_3d.rotation.x - event.screen_relative.y * real_sensitivity, -1.5, 1.5)
			player.facing = camera_3d.global_basis.x
	if event.is_action_pressed("jump"):
		player.jump()
	if event.is_action_pressed("zoom"):
		sound_zoom.play_specific(&"open")
	if event.is_action_released("zoom"):
		sound_zoom.play_specific(&"close")

func _process(delta: float) -> void:
	var goal_fov := ZOOM_FOV if Input.is_action_pressed("zoom") else NORMAL_FOV
	camera_3d.fov = lerpf(camera_3d.fov, goal_fov, delta * ZOOM_SPEED)
	var goal_fall_blend = 0.99
	if player.is_grounded:
		goal_fall_blend = 0.01
	goal_fall_blend = move_toward(animation_tree.get("parameters/_FallBlend/blend_amount"), goal_fall_blend, delta * ANIMATION_SPEED_CHANGE)
	animation_tree.set("parameters/_FallBlend/blend_amount", goal_fall_blend)
	#print(animation_tree.tree_root.set.set)
	
	animation_tree.set("parameters/IdleWalkBlend/blend_amount", tanh(player.linear_velocity.length()/ 4))


func _on_player_actually_jumped() -> void:
	animation_tree.set("parameters/JumpShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	animation_tree.set("parameters/_FallBlend/blend_amount", 0.99)


func _on_health_componant_hurt(previous_health: float, current_health: float) -> void:
	pass # Replace with function body.
