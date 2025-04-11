extends Node

var state: Dictionary = {}
const MAX_KEYS = 1  # Maximum number of keys allowed in the dictionary

func get_state():
	return state
	
func add_to_state(key, value = 1):
	#if key in state:
		#state[key] += value
		#print(state)
		#return true  # Item successfully added

	# Check if adding a new key exceeds the limit
	if state.size() >= MAX_KEYS:
		print("Inventory full! Cannot add", key)
		return false  # Indicate failure to add item
	
	# Add new item if there's space
	state[key] = value
	print(state)
	return true  # Item successfully added
	
func remove_from_state(key, value = 1):
	if key in state:
		state[key] -= value
		if state[key] <= 0:
			state.erase(key)
	else:
		print("Warning: Tried to remove from a non-existent key:", key)
	
func get_from_state(key: String, default_value = null):
	return state.get(key, default_value)
	
func drop_item(key):
	if key in state:
		var amount = state[key]
		if amount > 0:
			remove_from_state(key, 1)  # Remove 1 item from inventory
			return key  # Return the dropped item name
	return null

func get_item(key):
	if key in state:
		var amount = state[key]
		if amount > 0:
			return key  # Return the dropped item name
	return null

func reset():
	state = {}
