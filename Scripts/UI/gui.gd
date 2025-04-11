extends Control

# List of item nodes (populated in _ready)
var items: Array = []
@export var Player: CharacterBody3D 

# Colors (Hex to Color)
const SELECTED_COLOR = Color("4b4b4b")  # Dark Gray
const UNSELECTED_COLOR = Color("2d2d2d")  # Even Darker Gray
var var_selected_item = 0

func _ready():
	# Automatically find and store all items inside Inventory
	for i in range(1, 2):  # Adjust for max items
		var item_node = $Inventory.get_node_or_null("Item" + str(i))
		if item_node:
			items.append(item_node)

	# Set default selected item to the first one
	if items.size() > 0:
		select_item(items[0])
		var_selected_item = items[0]

	# Initialize the inventory UI with existing items
	update_inventory_display()

func _process(delta):
	for i in range(items.size()):
		if Input.is_action_just_pressed(str(i + 1)): 
			select_item(items[i])

	# Update inventory UI dynamically if needed
	update_inventory_display()
	
	if Input.is_action_just_pressed("Q"):
		drop_selected_item()
		
func drop_selected_item():
	var state = Inventory.get_state()
	var keys = state.keys()
	
	if items.size() > 0 and keys.size() > 0:
		var selected_index = items.find(var_selected_item)  # Get selected slot index
		if selected_index < keys.size():
			var item_name = keys[selected_index]
			var dropped_item = Inventory.drop_item(item_name)
			
			if dropped_item:
				Player.spawn_item(dropped_item)  # Call function to spawn dropped item
				
# Function to change selection
func select_item(selected_item):
	# Reset all items to UNSELECTED_COLOR
	for item in items:
		set_item_color(item, UNSELECTED_COLOR)

	# Set selected item to SELECTED_COLOR
	set_item_color(selected_item, SELECTED_COLOR)
	
	var state = Inventory.get_state()
	var keys = state.keys()
	var_selected_item = selected_item
	var selected_index = items.find(var_selected_item)
	if selected_index < keys.size():
			var item_name = keys[selected_index]
			var hold_item = Inventory.get_item(item_name)
			
			if hold_item:
				Player.hold_item(hold_item) 

# Function to modify StyleBoxFlat
func set_item_color(item, color):
	var stylebox = item.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox:
		stylebox = stylebox.duplicate()  # Prevent modifying the theme directly
		stylebox.bg_color = color
		item.add_theme_stylebox_override("panel", stylebox)  # Apply the modified style

# Function to update UI based on inventory state
func update_inventory_display():
	var state = Inventory.get_state()  # Get current inventory state
	var keys = state.keys()  # Get all stored items

	# Iterate through item slots (Item1, Item2, Item3)
	for i in range(items.size()):
		var item_slot = items[i]  # Reference to item slot node
		var item_name_node = item_slot.get_node_or_null("ItemName")  # Name label node
		var item_amount_node = item_slot.get_node_or_null("ItemAmount")  # Amount label node

		# Assign inventory data if available, otherwise set empty values
		if i < keys.size():
			var key = keys[i]  # Get item key from inventory
			var amount = state[key]  # Get item amount from inventory

			if item_name_node:
				item_name_node.text = key  # Set item name

			if item_amount_node:
				item_amount_node.text = str(amount)  # Set item amount
		else:
			# Empty slot
			if item_name_node:
				item_name_node.text = ""

			if item_amount_node:
				item_amount_node.text = ""
