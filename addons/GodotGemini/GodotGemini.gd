@tool
extends EditorPlugin

var panel: PanelContainer
var text_field: LineEdit
var button: Button
var checkbox: CheckBox
var checkbox_all_code: CheckBox
var checkbox_explanation: CheckBox
var response_box: CodeEdit
var copy_button: Button
var selection: String = ""

func _enter_tree() -> void:
	add_panel()

func _exit_tree() -> void:
	remove_panel()

func add_panel() -> void:
	panel = PanelContainer.new()
	panel.set_custom_minimum_size(Vector2(200, 600))
	panel.set_name("GodotGemini")
	
	add_control_to_dock(DOCK_SLOT_LEFT_UL, panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Gemini Request Panel"
	vbox.add_child(label)
	
	text_field = LineEdit.new()
	text_field.placeholder_text = "Enter your prompt here..."
	vbox.add_child(text_field)
	
	checkbox = CheckBox.new()
	checkbox.text = "Include Context (Scene & Signatures)"
	vbox.add_child(checkbox)
	
	checkbox_all_code = CheckBox.new()
	checkbox_all_code.text = "Include All Script"
	vbox.add_child(checkbox_all_code)
	
	checkbox_explanation = CheckBox.new()
	checkbox_explanation.text = "Explanation"
	vbox.add_child(checkbox_explanation)
	
	button = Button.new()
	button.text = "Send Request"
	button.pressed.connect(send_request)
	vbox.add_child(button)
	
	response_box = CodeEdit.new()
	response_box.custom_minimum_size = Vector2(180, 600)
	response_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	response_box.caret_changed.connect(selection_changed)
	vbox.add_child(response_box)
	
	copy_button = Button.new()
	copy_button.text = "EXPERIMENTAL +10: Run Selected snippet"
	copy_button.pressed.connect(copy_text)
	vbox.add_child(copy_button)

func selection_changed() -> void:
	selection = response_box.get_selected_text()

func copy_text() -> void:
	if selection.is_empty():
		return
		
	var code_editor = get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
	evaluate(selection)

func evaluate(input: String) -> void:
	var script = GDScript.new()
	script.source_code = """@tool
extends Node

func _enter_tree():
	eval()
	print_debug("executing")

func eval():
%s""" % input
	
	script.reload()
	
	var obj = Node.new()
	obj.set_script(script)
	
	get_editor_interface().get_edited_scene_root().add_child(obj)

func remove_panel() -> void:
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()

func compile_function_signatures(sig_in: Array) -> String:
	var signatures = ""
	for item in sig_in:
		signatures += "func " + item["name"] + "("
		var nparam = 0
		for param in item["args"]:
			signatures += param["name"]
			nparam += 1
			if nparam < len(item["args"]):
				signatures += ", "
		signatures += ")\n"
	return signatures

func send_request() -> void:
	response_box.text = "Request...\n\nWait"
	
	var request_text = text_field.text
	var include_signatures = checkbox.button_pressed
	
	var editor = get_editor_interface().get_script_editor()
	var prompt = "You are a GDScript 2.0 and Godot 4 Expert."
	
	if checkbox_explanation.button_pressed:
		prompt += " Be clear and specific on your explanation. Use examples if needed."
	else:
		prompt += " GDScript Code only with comments!."
	
	prompt += "\n\n" + text_field.text
	
	if editor:
		var script = editor.get_current_script()
		
		if include_signatures and script:
			prompt += "\n\nConsider the complete and existing function signatures: \n"
			prompt += compile_function_signatures(script.get_script_method_list())
			prompt += compile_scene_tree(get_scene_tree())
	
	var code_editor = get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
	var sel_text = code_editor.get_selected_text() if code_editor else ""
	
	if checkbox_all_code.button_pressed and editor.get_current_script():
		sel_text = editor.get_current_script().source_code
	
	if not sel_text.is_empty():
		prompt += "\n\nOriginal snippet:\n'" + sel_text + "'\n"
		
		if checkbox_explanation.button_pressed:
			prompt += "\n\nSnippet explanation:\n"
		else:
			prompt += "\n\nNew snippet:\n"
	else:
		if checkbox_explanation.button_pressed:
			prompt += "\n\nAnswer:\n"
		else:
			prompt += "\n\nCode Snippet:\n"
	
	# Create GeminiAPI instance
	var gemini_api = GeminiAPI.new()
	add_child(gemini_api)
	# Connect to the built-in request_completed signal
	gemini_api.request_completed.connect(_on_response)
	gemini_api.chat(prompt)

func _on_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())
		if error == OK:
			var response = json.get_data()
			if response.has("candidates") and response["candidates"].size() > 0:
				var text = response["candidates"][0]["content"]["parts"][0]["text"].strip_edges()
				response_box.text = text
	else:
		response_box.text = "Error: Failed to get response (Code: %d)" % response_code

func compile_scene_tree(tree_structure: Dictionary) -> String:
	var structure_text = "\n\nConsider the current scene tree:"
	for item in tree_structure:
		if tree_structure[item] != null:
			structure_text += "\n'" + str(item) + "' with type '" + str(tree_structure[item]) + "'"
	return structure_text

func get_scene_tree() -> Dictionary:
	var tree_structure = {}
	var root_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	for root_node in root_nodes:
		_traverse_tree("/", root_node, tree_structure)
	
	return tree_structure

func _traverse_tree(prefix: String, node: Node, tree_structure: Dictionary) -> void:
	var node_path = prefix + node.get_name()
	var node_type = node.get_class()
	
	tree_structure[node_path] = node_type
	
	for child in node.get_children():
		_traverse_tree(node_path + "/", child, tree_structure)
