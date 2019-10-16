tool
extends EditorPlugin

var mm_button = null
var material_maker = null
var importer = null
var renderer = null

func _enter_tree():
	add_tool_menu_item("Material Maker", self, "open_material_maker")
	add_tool_menu_item("Register Material Maker Import", self, "register_material_maker_import")
	renderer = preload("res://addons/material_maker/engine/renderer.tscn").instance()
	add_child(renderer)

func register_material_maker_import(__):
	importer = preload("res://addons/material_maker/import_plugin/ptex_import.gd").new(self)
	add_import_plugin(importer)
	remove_tool_menu_item("Register Material Maker Import")

func _exit_tree():
	remove_tool_menu_item("Material Maker")
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null
	if importer != null:
		remove_import_plugin(importer)
		importer = null

func _get_state():
	var s = { mm_button=mm_button, material_maker=material_maker }
	return s

func _set_state(s):
	mm_button = s.mm_button
	material_maker = s.material_maker

func open_material_maker(__):
	if material_maker == null:
		material_maker = preload("res://addons/material_maker/window_dialog.tscn").instance()
		var panel = material_maker.get_node("MainWindow")
		panel.editor_interface = get_editor_interface()
		panel.connect("quit", self, "close_material_maker")
		add_child(material_maker)
	material_maker.popup_centered()

func close_material_maker():
	if material_maker != null:
		material_maker.hide()
		material_maker.queue_free()
		material_maker = null

func generate_material(ptex_filename: String) -> Material:
	var generator = MMGenLoader.load_gen(ptex_filename)
	add_child(generator)
	if generator.has_node("Material"):
		var gen_material = generator.get_node("Material")
		if gen_material != null:
			var return_value = gen_material.render_textures(renderer)
			while return_value is GDScriptFunctionState:
				return_value = yield(return_value, "completed")
			var prefix = ptex_filename.left(ptex_filename.rfind("."))
			return gen_material.export_textures(prefix, get_editor_interface())
	return null
