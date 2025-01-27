extends Label
@onready var timer: Timer = $Timer

var count: int = 60

func textCount() -> void:
	text = str(count)

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
		Controller.dead()
		
