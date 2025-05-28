extends Node

class_name Interactable

signal interacted(body)

@export var prompt_message = "Interact"
@export var prompt_input = "F"
@export var Soup_content = "Soup"
	
func get_prompt():
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
			
	return prompt_message + "  ["+ key_name + "]"
	
func get_prompt_message():
	return prompt_message

func interact(body):
	interacted.emit(body)
