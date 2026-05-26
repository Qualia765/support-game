extends Node3D
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var sound: AudioStreamPlayer3D = $Sound
@export var volume: float

func _ready() -> void:
	particles.emitting = true
	sound.volume_db = volume
	sound.play()

func _on_gpu_particles_3d_finished() -> void:
	queue_free()
