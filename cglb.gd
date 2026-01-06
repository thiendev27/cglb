tool
extends EditorPlugin


signal cglb_started
signal mesh_container_updated(mesh_container)
const cglbAPI = preload("./cglbAPI.gd")
const panel_res = preload("res://addons/cglb/panel/cglbPanel.tscn")
const save_path = "res://testcglb/"
var editor = get_editor_interface()
var current_edited_root = null

func get_current_state():
	return get_editor_interface().get_base_control().get_node_or_null(cglbAPI.NAME.state)

func get_current_panel():
	return get_current_state().panel


func get_edited_root():
	return editor.get_edited_scene_root()

func get_current_glb_path():
	return get_edited_root().editor_description


func _enter_tree():
	
	# Xử lí thêm xóa panel
	var state = get_current_state()
	if not state:
		var state_scene = cglb_state.new()
		state_scene.name = cglbAPI.NAME.state

		get_editor_interface().get_base_control().add_child(state_scene)
		state = get_current_state()
	if not state.panel:
		state.panel = panel_res.instance()
		add_control_to_bottom_panel(state.panel, "cglb")
		
		
	connect("scene_changed", self, "_edited_root_changed")
	
	var panel = get_current_panel()
	connect("mesh_container_updated", panel, "_on_mesh_container_updated")
	connect("cglb_started", panel, "_on_cglb_started")
	editor.get_selection().connect("selection_changed", self, "_node_selection_change")
	
	panel.plugin = self
	emit_signal("cglb_started")
	
	


func get_selection_mesh_list():
	var meshes = []
	var selection = editor.get_selection()
	var selected_nodes = selection.get_selected_nodes()

	for node in selected_nodes:
		if node is MeshInstance:
			meshes.append(node)

	return meshes
	
func _node_selection_change():
	get_current_panel().set_selected_node_list(editor.get_selection().get_selected_nodes())


func _edited_root_changed(scene_root):
	var panel = get_current_panel()
	if get_mesh_container() == null:
		panel.empty_mode()
	else:
		panel.edit_mode()
# Hàm chức năng cho thao tác trên node GLB và mesh thuộc GLB

func get_current_model():
	return get_edited_root().get_node_or_null(cglbAPI.NAME.model)

func get_mesh_container():
	return get_edited_root().get_node_or_null(cglbAPI.NAME.mesh)

func mesh_container_children_changed(child=null):
	emit_signal("mesh_container_updated", get_mesh_container())

func apply_new_root(new_root_type):
	var glb_path = get_current_glb_path()
	var tscn_path = cglbAPI.get_packed_scene_path(glb_path)
	print("[Apply New Root] Tscn path: ", tscn_path)
	var root = Spatial.new()
	match new_root_type:
		cglbAPI.ROOT_TYPE.SPATIAL:
			pass
		cglbAPI.ROOT_TYPE.RIGID_BODY:
			root = RigidBody.new()
		cglbAPI.ROOT_TYPE.KINEMATIC_BODY:
			root = KinematicBody.new()
		cglbAPI.ROOT_TYPE.STATIC_BODY:
			root = StaticBody.new()
	root.editor_description = glb_path
	cglbAPI.replace_packed_scene_root(tscn_path, root)
	editor.reload_scene_from_path(tscn_path)
	editor.save_scene()

	
func save_scene():
	editor.save_scene()

func delete_scene():
	var dir = Directory.new()
	var tscn_path = cglbAPI.get_packed_scene_path(get_current_glb_path())
	
	var file_system = editor.get_resource_filesystem()
	if dir.file_exists(tscn_path):
		var ok = dir.remove(tscn_path)
		
		file_system.update_file(tscn_path)
		if ok == OK:
			print("[Delete Scene] Successfully delete scene")
		else:
			print("[Delete Scene] Cannot delete scene, error code: ", ok)
	

func _apply_change(data):
	var root_type = Spatial.new()
	var glb_path = data.glb_path
	var tscn_path = cglbAPI.get_packed_scene_path(glb_path)

func create_collision(parent, collision_name):
	if not parent.has_node(collision_name):
		var collision = CollisionShape.new()
		collision.name = collision_name
		parent.add_child(collision)
		collision.owner = get_edited_root()
		
		return collision
	return null

func add_collision_to_mesh(mesh_name, collision_type):
	var mesh_container = get_mesh_container()
	var mesh = mesh_container.get_node(mesh_name)
	var mesh_aabb = mesh.get_aabb()
	if mesh_container:
		var edited_root = get_edited_root()
#		print("[Add collision][Current Mesh Container] ", mesh_container)
#		print("[Add collision][collision type] ", collision_type)
		
		var shape_name = cglbAPI.SHAPE_NAME.box_shape
		var is_custom_shape = true
		
		match collision_type:
			cglbAPI.COLLISION_TYPE.BOX:
				is_custom_shape = false
				
				var collision = create_collision(mesh, "cglb-" + mesh_name + cglbAPI.SHAPE_NAME.box_shape)
				if mesh_aabb and collision:
					var shape = BoxShape.new()
					collision.global_position = mesh.global_position + mesh_aabb.get_center()
					shape.extents = mesh_aabb.size / 2
					collision.shape = shape
				
				
			cglbAPI.COLLISION_TYPE.CYLINDER:
				is_custom_shape = false
				var collision = create_collision(mesh, "cglb-" + mesh_name + cglbAPI.SHAPE_NAME.cylinder_shape)
				if collision and mesh_aabb:
					var shape = CylinderShape.new()
					collision.global_position = mesh.global_position + mesh_aabb.get_center()
					shape.height = mesh_aabb.size.y
					shape.radius = sqrt(pow(mesh_aabb.size.x, 2) + pow(mesh_aabb.size.z, 2)) / 2
					collision.shape = shape

			cglbAPI.COLLISION_TYPE.TRIMESH:
				shape_name = cglbAPI.SHAPE_NAME.trimesh
				mesh.create_trimesh_collision()

			## dup_mesh.create_convex_collision(clean: true, simplified: false)
			cglbAPI.COLLISION_TYPE.SIMPLIFIED:
				shape_name = cglbAPI.SHAPE_NAME.simplified
				mesh.create_convex_collision(true, true)

			cglbAPI.COLLISION_TYPE.SINGLE:
				shape_name = cglbAPI.SHAPE_NAME.single
				mesh.create_convex_collision(true, false)

			cglbAPI.COLLISION_TYPE.MULTIPLE:

				shape_name = cglbAPI.SHAPE_NAME.multiple
				mesh.create_multiple_convex_collisions()
		
		
		if is_custom_shape:
			shape_name = mesh_name + shape_name
			var shape_parent = mesh.get_child(mesh.get_child_count() - 1)
			print("Mesh ", mesh, " has children: ", mesh.get_children())
			print("Shape parent ", shape_parent,  " has children: ", shape_parent.get_children())
			for shape in shape_parent.get_children():
				shape.name = shape_name

				shape_parent.remove_child(shape)
				mesh.add_child(shape)
				shape.owner = get_edited_root()
			
			shape_parent.queue_free()
				
		
		save_scene()

func _on_merge_mesh_btn_pressed():
	merge_all_meshes()

	
	
func merge_all_meshes():
	if get_mesh_container() and get_mesh_container().get_children():
		var surface_tool = SurfaceTool.new()
		var mesh_list = get_mesh_container().get_children()
		var edited_root = get_edited_root()
		
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for m in mesh_list:
			surface_tool.append_from(m.mesh, 0, m.global_transform)
		surface_tool.index()
		
		var merged_mesh = MeshInstance.new()
		merged_mesh.mesh = surface_tool.commit()
		merged_mesh.name = "clgb-merged-mesh"
		
		get_mesh_container().add_child(merged_mesh)
		merged_mesh.owner = edited_root
	

func create_packed_scene_from_glb(glb_path):
	var root = Spatial.new()
	var ok = cglbAPI.save_packed_scene(glb_path, root)
	root.queue_free()

func extract_mesh_instance_from(node, container):
	for child in node.get_children():
		if child is MeshInstance:
			var dup_child = child.duplicate()
			container.add_child(dup_child)
			dup_child.owner = get_edited_root()
			
			dup_child.global_transform = child.global_transform
		extract_mesh_instance_from(child, container)
	
	if node.get_child_count() == 0:
		return

func export_mesh(glb_path):
	var edited_root = get_edited_root()
	
	var new_glb = load(glb_path).instance()
	new_glb.name = cglbAPI.NAME.original_glb + "-" + new_glb.name
	new_glb.visible = false
	edited_root.add_child(new_glb)
	new_glb.owner = edited_root
	
	var mesh_container = Spatial.new()
	mesh_container.name = cglbAPI.NAME.mesh
	edited_root.add_child(mesh_container)
	mesh_container.owner = edited_root
	
	extract_mesh_instance_from(new_glb, mesh_container)
	
	
	print("[Export Mesh] Mesh list ", mesh_container.get_children())
	print("[Export Mesh] Mesh was exported from glb <- ", glb_path)

func _on_glb_dropped(glb_path):
	open_glb(glb_path)

func open_glb(glb_path):
	var save_to = cglbAPI.get_packed_scene_path(glb_path)
	editor.set_main_screen_editor("3D")
	
	var is_scene_exist = ResourceLoader.exists(save_to)
	if not is_scene_exist:
		create_packed_scene_from_glb(glb_path)
	editor.open_scene_from_path(save_to)
	print("[Open GLB] Open scene from path: ", save_to)
	
	if not get_mesh_container():
		export_mesh(glb_path)
	emit_signal("mesh_container_updated", get_mesh_container())
	var mesh_container = get_mesh_container()
	if not mesh_container.is_connected("child_entered_tree", self, "mesh_container_children_changed"):
		print("[Open GLB] Mesh Selection Signal connected!")
		mesh_container.connect("child_entered_tree", self, "mesh_container_children_changed")
		mesh_container.connect("child_exiting_tree", self, "mesh_container_children_changed")
		mesh_container.connect("child_order_changed", self, "mesh_container_children_changed")
	
	editor.save_scene()
	
	get_edited_root().editor_description = glb_path
	
func _exit_tree():
	var state_panel = get_current_state().panel
	if state_panel:
		remove_control_from_bottom_panel(state_panel)
		get_current_state().clear_panel()

