extends Node
class_name cglb_state

#const panel_res = preload("res://addons/cglb/cglbPanel.tscn")
var panel: PanelContainer = null


func clear_panel():
	panel.queue_free()
	panel = null
