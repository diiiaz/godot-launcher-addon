@tool
extends EditorPlugin

const ERROR_PREFFIX: String = "[Godot Launcher addon] "
const LAUNCHER_NOT_FOUND_ERROR: String = "Launcher not detected, download it (https://github.com/diiiaz/godot-launcher) and launch it before adding this addon."
const LAUNCHER_PATH_INCORRECT_ERROR: String = "Launcher path is incorrect, relaunch the launcher to update the path."

var project_popup_menu: PopupMenu
var quit_to_launcher_index: int = -1
var launcher_user_path: String = ""


func _enter_tree() -> void:
	project_popup_menu = get_tree().root.get_child(0).get_child(4).get_child(0).get_child(0).get_child(0).get_child(1)
	
	var user_path: String = OS.get_user_data_dir()
	user_path = user_path.replace(user_path.get_slice("/", user_path.get_slice_count("/") - 1), "")
	launcher_user_path = user_path.path_join("Godot Launcher")
	
	if not DirAccess.dir_exists_absolute(launcher_user_path):
		EditorInterface.get_editor_toaster().push_toast(ERROR_PREFFIX + LAUNCHER_NOT_FOUND_ERROR, EditorToaster.SEVERITY_ERROR)
		push_error(ERROR_PREFFIX + LAUNCHER_NOT_FOUND_ERROR)
		return
	
	var launcher_uri: String = get_latest_opened_launcher_path()
	project_popup_menu.add_item("Quit to Launcher")
	quit_to_launcher_index = project_popup_menu.item_count - 1
	project_popup_menu.set_item_disabled(quit_to_launcher_index, not FileAccess.file_exists(launcher_uri))
	project_popup_menu.id_pressed.connect(
		func(id: int):
			if id != quit_to_launcher_index:
				return
			if not FileAccess.file_exists(launcher_uri):
				EditorInterface.get_editor_toaster().push_toast(ERROR_PREFFIX + LAUNCHER_PATH_INCORRECT_ERROR, EditorToaster.SEVERITY_ERROR)
				push_error(ERROR_PREFFIX + LAUNCHER_PATH_INCORRECT_ERROR)
				return
			OS.create_process(ProjectSettings.globalize_path(launcher_uri), [])
			EditorInterface.get_base_control().get_tree().quit()
	)


func _exit_tree() -> void:
	if quit_to_launcher_index == project_popup_menu.item_count - 1:
		project_popup_menu.remove_item(quit_to_launcher_index)


func get_latest_opened_launcher_path() -> String:
	var file_path: String = launcher_user_path.path_join("latest_opened_launcher_path.json")
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	var dict: Dictionary = JSON.parse_string(file.get_as_text())
	
	if dict == null:
		return ""
	
	return dict.path
