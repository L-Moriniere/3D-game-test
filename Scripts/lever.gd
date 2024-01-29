extends Area3D

var is_actionned : bool = false
@onready var player : CharacterBody3D = $"../Character"
@onready var start_position : Node3D = $"../PositionPlayerEnter"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	


func _on_interactable_focused(interactor):
	pass

func _on_interactable_interacted(interactor):
	if !is_actionned:
		$AnimationPlayer.play("action")
		is_actionned = true
		await get_tree().create_timer(1).timeout
		player.global_position = start_position.global_position
		


func _on_interactable_unfocused(interactor):
	if is_actionned:
		$AnimationPlayer.play("back_to_default")
		is_actionned = false
