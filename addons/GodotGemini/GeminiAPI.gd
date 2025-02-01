@tool
class_name GeminiAPI
extends HTTPRequest

# Remove the signal declaration since HTTPRequest already has request_completed
var gemini_api_key = ProjectSettings.get_setting("application/config/project_settings_override", "")
var model_name = "gemini-2.0-flash-thinking-exp"

func _ready():
	# Connect to the built-in request_completed signal
	request_completed.connect(_on_request_completed)

func chat(prompt: String) -> void:
	if gemini_api_key.is_empty():
		push_error("Gemini API key not set")
		return
		
 	# Updated URL to use the correct endpoint
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" + gemini_api_key
	
	# Updated request body format according to Gemini API specs
	var body = {
		"contents": [
			{
				"parts": [
					{
						"text": prompt
					}
				]
			}
		],
		"generationConfig": {
			"temperature": 0.7,
			"topP": 0.8,
			"topK": 40,
			"maxOutputTokens": 2048
		}
	}

	# Convert body to JSON string
	var json = JSON.new()
	var body_text = json.stringify(body)

	# Set up headers
	var headers = ["Content-Type: application/json"]

	# Make the request
	var error = request(url, headers, HTTPClient.METHOD_POST, body_text)
	if error != OK:
		push_error("Failed to make HTTP request: " + str(error))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != HTTPClient.RESPONSE_OK:
		push_error("Request failed with code: " + str(response_code))
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		push_error("Failed to parse response JSON")
		return

	var response = json.get_data()
	
	# Extract the response text and pass it back through the signal
	if response.has("candidates") and response["candidates"].size() > 0:
		var candidate = response["candidates"][0]
		if candidate.has("content") and candidate["content"].has("parts"):
			var text = candidate["content"]["parts"][0]["text"]
			# The signal is already built into HTTPRequest, so we can use it directly
			return
	
	push_error("Invalid response format")
