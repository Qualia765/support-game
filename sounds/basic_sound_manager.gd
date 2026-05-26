extends AudioStreamPlayer

@export var sounds: Dictionary[StringName, AudioStream]

func play_specific(which: StringName):
	stream = sounds[which]
	play()
