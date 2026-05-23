@tool
@icon("res://addons/q_image_processor/icon.svg")
class_name QImageProcessor extends Resource

@export_tool_button("Manually Process") var reprocess_action = func():
	associated = true
	if associated:
		var processors = load("res://addons/q_image_processor/processors.tres")
		processors.run_processor(self)

enum ExportMode {PNG, EXR, EXR_GRAYSCALE, JPG, WEBP, WEBP_LOSSY, DDS}
@export var export_mode: ExportMode
@export_range(0., 1., 0.001, "prefer_slider") var quality: float
@export var resolution: Vector2i
@export var shader_material: ShaderMaterial

@export var associated: bool = true:
	set(val):
		if is_built_in():
			associated = false
			return
		if not ResourceLoader.exists("res://addons/q_image_processor/processors.tres"):
			push_error("res://addons/q_image_processor/processors.tres is missing!!!!")
			associated = false
			return
		var processors = load("res://addons/q_image_processor/processors.tres")
		associated = self in processors.processors
		if not self in processors.processors:
			processors.processors.push_back(self)
			processors.save()
			associated = self in processors.processors


func _init(
	export_mode_: ExportMode = ExportMode.PNG,
	quality_: float = 0.9,
	resolution_: Vector2i = Vector2i(128, 128),
	shader_material_: ShaderMaterial = null,
	associated_ = true,
):
	export_mode = export_mode_
	quality = quality_
	resolution = resolution_
	if shader_material_ == null:
		shader_material = ShaderMaterial.new()
	else:
		shader_material = shader_material_
	associated = associated_


func get_file_extension_string() -> String:
	match export_mode:
		ExportMode.PNG: return ".png"
		ExportMode.EXR: return ".exr"
		ExportMode.EXR_GRAYSCALE: return ".exr"
		ExportMode.JPG: return ".jpg"
		ExportMode.WEBP: return ".webp"
		ExportMode.WEBP_LOSSY: return ".webp"
		ExportMode.DDS: return ".dds"
		_: assert(false, "unreachable"); return ".png"


func get_shader_uniform_resource_names() -> Dictionary[String, bool]:
	var shader_uniform_resource_names: Dictionary[String, bool] = {}
	var uniform_list: Array = shader_material.shader.get_shader_uniform_list()
	for uniform in uniform_list:
		var pram := shader_material.get_shader_parameter(uniform.name)
		if pram is Resource and not pram.is_built_in():
			shader_uniform_resource_names[pram.resource_path] = false
	return shader_uniform_resource_names


func get_result_path() -> String:
	return resource_path.substr(0, (resource_path).length() - 5) + get_file_extension_string() 
	


## shader_uniform_resource_names should be the exact thing returned from get_shader_uniform_resource_names()
func is_valid(shader_uniform_resource_names: Dictionary[String, bool]) -> bool:
	if shader_material == null:
		push_error("Expected Shader")
		return false
	if get_result_path() in shader_uniform_resource_names:
		push_error("can not export to something that it depends on")
		return false
	if is_built_in():
		push_error("should not be built in!")
		return false
	return true


func save_image(image: Image):
	var save_result: Error
	
	match export_mode:
		ExportMode.PNG: save_result = image.save_png(get_result_path())
		ExportMode.EXR: save_result = image.save_exr(get_result_path(), false)
		ExportMode.EXR_GRAYSCALE: save_result = image.save_exr(get_result_path(), true)
		ExportMode.JPG: save_result = image.save_jpg(get_result_path(), quality)
		ExportMode.WEBP: save_result = image.save_webp(get_result_path(), false, quality)
		ExportMode.WEBP_LOSSY: save_result = image.save_webp(get_result_path(), true, quality)
		ExportMode.DDS: save_result = image.save_dds(get_result_path())
		_: assert(false, "unreachable"); return Error.FAILED
	
	if save_result != OK:
		push_error("Save error ", save_result)
