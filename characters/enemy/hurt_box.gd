extends Area3D

@export var damange: float = 1

const BLOODY = preload("uid://jggvomseysbf")
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _on_body_entered(body: Node3D) -> void:
	if "health_componant" in body and body.health_componant != null:
		var impact_nodes := BLOODY.instantiate()
		impact_nodes.position = global_position
		var basis_z = -collision_shape_3d.global_basis.y
		var basis_x = Vector3(1.238947,0.1967823,0.78234).cross(basis_z).normalized()
		var basis_y = basis_x.cross(basis_z).normalized()
		impact_nodes.basis = Basis(basis_x, basis_y, basis_z)
		get_tree().root.add_child(impact_nodes)
		body.health_componant.health -= damange
