class_name HealthComponant extends Node

@export var max_health: float = 1
signal dead
signal health_changed(current_health: float, max_heatlh: float)
signal hurt(previous_health: float, current_health: float)

@onready var health: float = max_health:
	set(val):
		var actual_new_health: float = max(val, 0)
		if actual_new_health < health:
			hurt.emit(actual_new_health, health)
		health_changed.emit(actual_new_health, max_health)
		health = actual_new_health
		if health <= 0:
			dead.emit()
