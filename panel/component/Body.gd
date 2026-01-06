tool
extends HBoxContainer

signal apply_new_root(root_type)

onready var root_option = get_node("Functional/ChooseRoot/OptionButton")
onready var apply_root_btn = get_node("Functional/ChooseRoot/Button")

onready var add_collision_btn = get_node("Functional/AddCollision/Button")

func _ready():
	apply_root_btn.connect("pressed", self, "apply_new_root")

func apply_new_root():
	emit_signal("apply_new_root", root_option.get_selected_id())

func get_add_collision_btn():
	return add_collision_btn
