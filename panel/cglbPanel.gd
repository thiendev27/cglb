tool
extends PanelContainer

# Tín hiệu
signal glb_dropped(path)


const empty = "< Thả file (.glb) vào đây >"

# Biến chứa đối tượng plugin chính
var plugin = null

# Empty label
onready var empty_label = get_node("CenterContainer/EmptyLabel")
# Edit panel
onready var edit_panel = get_node("MarginContainer/EditPanel")

onready var top_bar = get_node("MarginContainer/EditPanel/TopBar")
# Body
onready var body = get_node("MarginContainer/EditPanel/Body")

## Filename

## Mesh information
onready var selected_info = get_node("MarginContainer/EditPanel/Body/InfoPanel/SelectedNode")

var is_edit_mode = false

# Merge mesh button
onready var merge_mesh_btn = get_node("MarginContainer/EditPanel/Body/InfoPanel/MergeMesh")

# Mesh selection panel
onready var mesh_selection_panel = get_node("MeshSelectionPanel")


# General Function

func edit_mode():
	is_edit_mode = true
	edit_panel.show()
	print(get_node("MarginContainer/EditPanel"))
	empty_label.hide()

func empty_mode():
	is_edit_mode = false
	edit_panel.hide()
	empty_label.show()
	

func set_selected_node_list(selected_node):
	if selected_node:
		selected_info.text = "Node đang chọn: {0}".format(["\n".join(selected_node)])
	else:
		selected_info.text = "Không có node nào được chọn."
	
func merge_all_meshes():
	emit_signal("merge_all_meshes")

func _on_mesh_container_updated(mesh_container):
	mesh_selection_panel.update_mesh_list(mesh_container.get_children())

# Ready!
func _on_cglb_started():
	# Topbar signal
	top_bar.connect_signal(top_bar.ACTION.SAVE, plugin, "save_scene")
	top_bar.connect_signal(top_bar.ACTION.EXIT, self, "empty_mode")
	top_bar.connect_signal(top_bar.ACTION.DELETE, plugin, "delete_scene")
	
	
	# Body signal
	body.connect("apply_new_root", plugin, "apply_new_root")
	body.get_add_collision_btn().connect("pressed", self, "add_collision")
	mesh_selection_panel.connect("mesh_selected", plugin, "add_collision_to_mesh")
	
	connect("glb_dropped", plugin, "_on_glb_dropped")
	merge_mesh_btn.connect("pressed", plugin, "_on_merge_mesh_btn_pressed")
	

func add_collision():
	mesh_selection_panel.popup_centered()
	
func _ready():
	empty_mode()

# Save scene
func save_scene():
	emit_signal("save_scene")

func can_drop_data(position, data):
	if not is_edit_mode and data.type == "files" and len(data.files) == 1:
		if not data.files[0].ends_with(".glb"): return false
		return true
	return false


func drop_data(position, data):
	var path = data.files[0]
	emit_signal("glb_dropped", path)
	edit_mode()
