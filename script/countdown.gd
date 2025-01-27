extends Label
@onready var timer: Timer = $Timer

var count: int = 35

func textCount() -> void:
	text = str(count)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textCount()
	timer.start()
	timer.wait_time = 1
	timer.autostart = true
	
func _on_timer_timeout() -> void:
	if count > 0:
		count -= 1
		textCount()
	else:
		timer.stop()
		get_tree().reload_current_scene()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
