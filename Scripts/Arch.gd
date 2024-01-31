extends Area3D

@onready var start_position : Node3D = $"../PositionPlayerEnter"
@onready var player : CharacterBody3D = $"../Character"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_interactable_focused(interactor):
	pass # Replace with function body.


func _on_interactable_interacted(interactor):
	await get_tree().create_timer(1.5).timeout
	player.global_position = start_position.global_position


func _on_interactable_unfocused(interactor):
	pass # Replace with function body.
