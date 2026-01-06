tool
extends PopupPanel


signal mesh_selected(mesh_name, collision_type)

onready var confirm_btn = get_node("VBoxContainer/Button/Confirm")
onready var cancel_btn = get_node("VBoxContainer/Button/Cancel")

onready var item_list = get_node("VBoxContainer/ItemList")

onready var collision_option = get_node("VBoxContainer/ChooseCollision/OptionButton")

func _ready():
	confirm_btn.connect("pressed", self, "confirm_selection")
	cancel_btn.connect("pressed", self, "hide")

func confirm_selection():
	var item_id = item_list.get_selected_items()[0]
	var mesh_name = item_list.get_item_text(item_id)
	if (item_id and mesh_name):
		var collision_type = collision_option.get_selected_id()
		hide()
		emit_signal("mesh_selected", mesh_name, collision_type)
	

func update_mesh_list(mesh_list):
	item_list.clear()
	for mesh in mesh_list:
		var mesh_name = mesh.name
		var texture = get_icon("MeshInstance", "EditorIcons")
		item_list.add_item(mesh_name, texture)
