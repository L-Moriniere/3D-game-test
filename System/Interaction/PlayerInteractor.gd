extends Interactor

@export var player : CharacterBody3D

var cached_closest : Interactable

func _ready():
	controller = player
	
func _physics_process(delta):
	var new_closest : Interactable = get_closest_interactable()
	if new_closest != cached_closest:
		if is_instance_valid(cached_closest):
			unfocus(cached_closest)
		if new_closest:
			focus(new_closest)
		cached_closest = new_closest

func _input(event):
	if event.is_action_pressed("Interact"):
		if cached_closest:
			interact(cached_closest)

			


func _on_area_exited(area):
	if cached_closest == area:
		unfocus(area)
