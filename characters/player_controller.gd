extends Node

@export var MOUSE_SENSITIVITY: float = 0.005
@export var ZOOM_SPEED: float = 6
@export var ZOOM_FOV: float = 30
@export var NORMAL_FOV: float = 90

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
			center_of_y_rotation.rotation.y -= event.screen_relative.x * MOUSE_SENSITIVITY
			camera_3d.rotation.x = clampf(camera_3d.rotation.x - event.screen_relative.y * MOUSE_SENSITIVITY, -1.5, 1.5)
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


#func _on_player_actually_jumped() -> void:
	#animation_tree.tree_root.set_parameter("parameters/JumpShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#animation_tree.tree_root.set_parameter("parameters/_FallBlend/request", 0.99)
	
