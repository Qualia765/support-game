extends Node

@export var MOUSE_SENSITIVITY: float = 0.005
@export var ZOOM_SPEED: float = 6
@export var ZOOM_FOV: float = 30
@export var NORMAL_FOV: float = 90

@onready var player: Character = $".."
@onready var camera_3d: Camera3D = $"../Camera3D"
@onready var sound_zoom: AudioStreamPlayer = $"../SoundZoom"

func _ready():
	player.movement_vector = func(): return Input.get_vector("right", "left", "foward", "back")

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
			player.facing = camera_3d.basis.x
	if event.is_action_pressed("jump"):
		player.jump()
	if event.is_action_pressed("zoom"):
		sound_zoom.play_specific(&"open")
	if event.is_action_released("zoom"):
		sound_zoom.play_specific(&"close")

func _process(delta: float) -> void:
	var goal_fov := ZOOM_FOV if Input.is_action_pressed("zoom") else NORMAL_FOV
	camera_3d.fov = lerpf(camera_3d.fov, goal_fov, delta * ZOOM_SPEED)
