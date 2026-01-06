extends Node
enum ROOT_TYPE {
	SPATIAL = 0,
	RIGID_BODY = 1,
	KINEMATIC_BODY = 2,
	STATIC_BODY = 3,
}
enum COLLISION_TYPE {
	BOX = 0,
	TRIMESH = 1,
	SIMPLIFIED = 2,
	SINGLE = 3,
	MULTIPLE = 4,
	CYLINDER = 5
}

const NAME = {
	state = "cglb-state",
	model = "cglb-model",
	mesh = "cglb-mesh",
	original_glb = "cglb-original",
	
	scene_folder = "cglb_scene"
}

const SHAPE_NAME = {
	box_shape = "-BoxShape",
	trimesh = "-TrimeshShape",
	simplified = "-SimplifiedShape",
	single = "-SingleShape",
	multiple = "-MultipleShape",
	cylinder_shape = "-CylinderShape"
}


static func get_filename_from(path):
	return path.get_file().get_slice(".", 0)
	
static func get_packed_scene_path(glb_path):
	return glb_path.get_base_dir() + "/" + get_filename_from(glb_path) + ".tscn"

static func save_packed_scene(glb_path, root):
	var save_path = get_packed_scene_path(glb_path)
	root.name = get_filename_from(glb_path)
#	root.owner = root
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)

	var ok = ResourceSaver.save(save_path, packed_scene)
	root.queue_free()
	
	if ok == OK: print("[Save] Saved to ", save_path)
	else: print("[Error] Code: ", ok)
	return ok
	
static func replace_packed_scene_root(packed_scene_path, replace_root):
	print("[Replace] PackedScene Path ", packed_scene_path)
	var packed_scene = load(packed_scene_path)
	var old_root = packed_scene.instance()
	
	print("[Replace][OLD] ", old_root, " has children: ", old_root.get_children())
	replace_root.name = old_root.name
	old_root.replace_by(replace_root)
	
	
	print("[Replace][NEW] ", replace_root, " has children: ", replace_root.get_children())

	var replaced = PackedScene.new()

	replaced.pack(replace_root)

	var ok = ResourceSaver.save(packed_scene_path, replaced)
	if ok == OK: print("[Replace] Saved to ", packed_scene_path)
	else: print("[Error] Code: ", ok)
	old_root.queue_free()
	replace_root.queue_free()
	return ok
	




