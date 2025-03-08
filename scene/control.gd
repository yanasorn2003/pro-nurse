extends Control

@onready var Question = $Label
@onready var ListItem = $ItemList
@onready var Next = $Button

@onready var NameTag = $MarginContainer
@onready var Name = $Name
@onready var UserNameField = $MarginContainer/LineEdit
@onready var Start = $Start

var items: Array = []  # Holds all questions
var user_results: Array = []  # Stores user answers & scores
var item: Dictionary
var indexItem: int = 0
var total_score: int = 0
var UserName: String = ""
var selected_indices : Array = []

func _ready() -> void:
	Question.hide()
	ListItem.hide()
	Next.hide()
	Start.connect("pressed", _on_start_pressed)

func _on_start_pressed() -> void:
	UserName = UserNameField.text.strip_edges()  # Get username from input
	if UserName.is_empty():
		print("Username cannot be empty!")
		return  # Stop if no username is provided
	Question.show()
	ListItem.show()
	Next.show()
	
	Name.hide()
	NameTag.hide()
	Start.hide()
	
	items = read_json_file("res://scene/question.json")  # Load questions
	ListItem.select_mode = ItemList.SELECT_MULTI  # Enable multi-selection
	ListItem.connect("item_selected", _on_item_selected)  # FIXED: Use "multi_selected"

	if items.size() > 0:
		load_question(indexItem)  # Load first question
		Next.connect("pressed", _on_next_pressed)  # Connect button click event

func load_question(index: int) -> void:
	if index < items.size():
		item = items[index]  # Get current question
		Question.text = item.get("question", "No question found")  # Display question
		ListItem.clear()  # Clear previous options

		for answer in item.get("options", []):
			ListItem.add_item(answer)  # Populate ItemList
	else:
		Question.text = "Quiz Finished! Answers saved."
		ListItem.clear()
		Next.disabled = true  # Disable button when quiz is finished
		save_user_results()  # Save user results to JSON

func _on_item_selected(index: int, selected: bool) -> void:
	if index in selected_indices:
		selected_indices.erase(index)  # Deselect if already selected
		ListItem.deselect(index)
	else:
		selected_indices.append(index)  # Select if not already selected
		ListItem.select(index)

func _on_next_pressed() -> void:
	var selected_answers = get_selected_indices()
	var correct_answers = []
	
	for ans in item.get("answer", []):
		correct_answers.append(int(ans))
		
	# Calculate score
	var question_score = 0
	for selected in selected_answers:
		if selected in correct_answers:
			question_score += 1  # 1 point per correct answer

	total_score += question_score  # Update total score

	# Store user response
	user_results.append({
		"question": item.get("question", ""),
		"options": item.get("options", []),
		"selected_answers": selected_answers,
		"correct_answers": correct_answers,
		"score": question_score
	})

	print("User Results:", user_results)  # Debugging

	indexItem += 1  # Move to the next question
	load_question(indexItem)  # Load next question

func get_selected_indices() -> Array:
	return ListItem.get_selected_items()  # Returns indices of selected items

func save_user_results() -> void:
	# Create a new file with a unique name based on the current timestamp
	#var timestamp = str(Time.get_time_dict_from_system())  # Get current Unix timestamp for unique filename
	var file_path = "user://user_results_" + UserName + ".json"  # New file name
	print("Saving results to:", file_path)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		var json_data = {
			"username": UserName,  # Store username inside JSON file
			"results": user_results
		}
		var json_text = JSON.stringify(json_data, "    ")  # Use 4 spaces for indentation
		file.store_string(json_text)
		file.close()
		print("Results saved to", file_path)
	else:
		print("Failed to save user results.")

func read_json_file(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var parsed_data = JSON.parse_string(content)
		if parsed_data is Array:
			return parsed_data
		else:
			print("Error: JSON is not an array")
			return []
	else:
		print("Failed to load JSON file:", path)
		return []
