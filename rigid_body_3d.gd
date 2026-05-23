extends RigidBody3D

@export var speed: float

@onready var camera_3d: Camera3D = $Camera3D

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	linear_velocity += basis * Vector3(Input.get_axis("left", "right"), 0, Input.get_axis("foward", "back")) * speed
