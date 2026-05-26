extends Node3D
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var sound: AudioStreamPlayer3D = $Sound
@export var volume: float
@export var alt_style: bool = false
@export var alt_stream: AudioStream

func _ready() -> void:
	particles.emitting = true
	sound.volume_db = volume
	if alt_style:
		sound.stream = alt_stream
	sound.play()

func _on_gpu_particles_3d_finished() -> void:
	queue_free()
