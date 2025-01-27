extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("Coin collected by: ", body.name)
	Controller.add_coin()
	queue_free()
