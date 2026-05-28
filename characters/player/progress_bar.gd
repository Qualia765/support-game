extends ProgressBar

func _on_health_componant_health_changed(current_health: float, max_heatlh: float) -> void:
	value = current_health / max_heatlh
