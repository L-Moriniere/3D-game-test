@tool
extends Node3D
var exit_door_instance : PackedScene = preload("res://Scenes/ExitDoor.tscn")

func remove_wall_up():
	$wall_up.free()
func remove_wall_down():
	$wall_down.free()
func remove_wall_left():
	$wall_left.free()
func remove_wall_right():
	$wall_right.free()
func remove_door_up():
	$door_up.free()
func remove_door_down():
	$door_down.free()
func remove_door_left():
	$door_left.free()
func remove_door_right():
	$door_right.free()
	
func add_exit_door_up():
	var door : Area3D = exit_door_instance.instantiate()
	door.position = Vector3(0,0,-0.43)
	door.rotation_degrees = Vector3(0,-90,0)
	add_child(door)
	
func add_exit_door_left():
	var door : Area3D = exit_door_instance.instantiate()
	door.position = Vector3(-0.43,0,0)
	add_child(door)
	
func add_exit_door_down():
	var door : Area3D = exit_door_instance.instantiate()
	door.position = Vector3(0,0,0.43)
	door.rotation_degrees = Vector3(0,90,0)
	add_child(door)

func add_exit_door_right():
	var door : Area3D = exit_door_instance.instantiate()
	door.position = Vector3(0.43,0,0)
	door.rotation_degrees = Vector3(0,180,0)
	add_child(door)
	
