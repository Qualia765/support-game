@tool extends Resource

@export_tool_button("Manually Reprocess All") var regen_action = _manual_regen_pressed
@export var processors: Array[QImageProcessor]


func save():
	ResourceSaver.save(self, "res://addons/q_image_processor/processors.tres")


func _init(processors_: Array[QImageProcessor] = []):
	processors = processors_
	EditorInterface.get_resource_filesystem().resources_reimported.connect(_resource_changed)


func _manual_regen_pressed():
	save()
	delete_built_in_processors()
	run_processors(processors)


func _resource_changed(resource_paths: PackedStringArray):
	delete_built_in_processors()
	var processors_to_run := determine_which_to_reprocess(resource_paths)
	run_processors(processors_to_run)


func delete_built_in_processors():
	var new_processors:Array[QImageProcessor] = []
	for processor in processors:
		if not processor.is_built_in():
			new_processors.push_back(processor)
	if len(processors) != len(new_processors):
		processors = new_processors
		save()


## takes array of modified input resoruce
## return an array of QImageProcessor to run
func determine_which_to_reprocess(resource_paths: PackedStringArray) -> Array[QImageProcessor]:
	var result: Array[QImageProcessor] = []
	for processor in processors:
		var shader_uniform_resource_names: Dictionary[String, bool] = processor.get_shader_uniform_resource_names()
		if not processor.is_valid(shader_uniform_resource_names): continue
		var reprocess: bool = false
		for resource in resource_paths:
			if resource in shader_uniform_resource_names:
				result.push_back(processor)
				break
	return result


# called by QImageProcessor
# for some reason godot has type errors when calling run_processors from QImageProcessor 
func run_processor(processor: QImageProcessor):
	run_processors([processor])

## takes an array of processors and generates the output one by one
func run_processors(processors: Array[QImageProcessor]):
	if len(processors) == 0: return
	
	var color_rect := ColorRect.new()
	var subviewport := SubViewport.new()
	subviewport.disable_3d = true
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.add_child(color_rect)
	var subviewport_container := SubViewportContainer.new()
	subviewport_container.add_child(subviewport)
	EditorInterface.get_base_control().add_child(subviewport_container)
	
	for processor in processors:
		color_rect.size = processor.resolution
		color_rect.material = processor.shader_material
		subviewport.size = processor.resolution
		await RenderingServer.frame_post_draw
		processor.save_image(subviewport.get_texture().get_image())
	
	EditorInterface.get_base_control().remove_child(subviewport_container)
	subviewport_container.queue_free()
	
	EditorInterface.get_resource_filesystem().scan()
