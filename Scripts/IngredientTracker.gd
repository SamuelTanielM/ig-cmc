extends Node

# Raw sliced ingredients
var ingredients: Array[String] = []

# Cooked ingredients
var cooked_ingredients: Array[String] = []

# Finished ingredients (e.g. garnished or final processed)
var finished_ingredients: Array[String] = []

# ==== Raw Ingredients Methods ====
func add_ingredient(name: String) -> void:
	if name not in ingredients:
		ingredients.append(name)

func has_ingredient(name: String) -> bool:
	return name in ingredients

func has_all(required) -> bool:
	for item in required:
		if item not in ingredients:
			return false
	return true

# ==== Cooked Ingredients Methods ====
func add_cooked_ingredient(name: String) -> void:
	if name not in cooked_ingredients:
		cooked_ingredients.append(name)

func has_cooked_ingredient(name: String) -> bool:
	return name in cooked_ingredients

func has_all_cooked(required) -> bool:
	for item in required:
		if item not in cooked_ingredients:
			return false
	return true

# ==== Finished Ingredients Methods ====
func add_finished_ingredient(name: String) -> void:
	if name not in finished_ingredients:
		finished_ingredients.append(name)

func has_finished_ingredient(name: String) -> bool:
	return name in finished_ingredients

func has_all_finished(required) -> bool:
	for item in required:
		if item not in finished_ingredients:
			return false
	return true

# ==== Reset All Collections ====
func reset_all() -> void:
	ingredients.clear()
	cooked_ingredients.clear()
	finished_ingredients.clear()
