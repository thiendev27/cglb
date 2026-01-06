tool
extends HBoxContainer


enum ACTION {
	SAVE = 0,
	EXIT = 1,
	DELETE = 2
}

onready var save_btn = get_node("Save")
onready var exit_btn = get_node("Exit")
onready var delete_btn = get_node("Delete")

func connect_signal(action, to, method):
	match action:
		ACTION.SAVE:
			save_btn.connect("pressed", to, method)
		ACTION.EXIT:
			exit_btn.connect("pressed", to, method)
		ACTION.DELETE:
			delete_btn.connect("pressed", to, method)
