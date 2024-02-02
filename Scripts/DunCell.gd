@tool
extends Node3D


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
func remove_door_exit_up():
	$wall_up/DoorExit.free()
func remove_door_exit_down():
	$wall_down/DoorExit.free()
func remove_door_exit_left():
	$wall_left/DoorExit.free()
func remove_door_exit_right():
	$wall_right/DoorExit.free()
