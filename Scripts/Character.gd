extends CharacterBody3D


const SPEED = 3.0
const  CROUCH_SPEED = 2.0
const JUMP_VELOCITY = 4.5
@export var sensitivity = 3
var crouched : bool =  false
var lanternIsOut : bool = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#var gravity = 0

func _ready():
	#enlever le curseur de la souris et la capturer 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = SPEED

	if Input.is_action_pressed("Crouch"):
		speed = CROUCH_SPEED
		if !crouched:
			$AnimationPlayer.play("crouch")
			crouched = true
	else:
		if crouched:
			var space_state = get_world_3d().direct_space_state
			#verifie qu'il n'y a pas de collisions au dessus, si il n'y en le character peut se relever
			var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(position, position + Vector3(0,2,0), 1, [self]))
			if result.size() == 0:
				$AnimationPlayer.play("uncrouch")
				crouched = false
				
	if Input.is_action_just_pressed("Flashlight"):
		if lanternIsOut:
			$AnimationPlayer.play("lantern_hide")
		else :
			$AnimationPlayer.play("lantern_show")
		lanternIsOut = !lanternIsOut
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		#event.relative.x pour pouvoir avoir les coordonnées de la souris sur l'axe horizontal
		#si event.relative.y prend les coordonnées sur l'axe vertical
		rotation.y -= event.relative.x/1000 * sensitivity
		#on ne veut pas rotate le joueur sinon pb collision
		$Camera3D.rotation.x -= event.relative.y/1000 * sensitivity
		#pour que la rotation reste sensisblement la meme
		rotation.x = clamp(rotation.x, PI/-2, PI/2)
		#eviter de faire des tours complets
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -2, 2)
