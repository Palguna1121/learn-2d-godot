extends CharacterBody2D


const SPEED = 250.0
const JUMP_VELOCITY = -450.0
@onready var player_ui: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ui: CollisionShape2D = $"../StaticBody2D/CollisionShape2D"

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		player_ui.animation = "jump"

	# Handle jump.
	if (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Movement with arrow key / (a/d).
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		player_ui.flip_h = direction < 0
		velocity.x = direction * SPEED
		player_ui.animation = "run"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		player_ui.animation = "idle"

	# activate movement.
	move_and_slide()
