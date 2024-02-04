@tool
extends Node3D

@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)
@onready var lantern_instance = preload("res://Scenes/Lantern.tscn")
@export_range(0,1) var survival_chance_lantern : float = 0.05

@export var number_object_to_place : int = 20
@export var min_distance_object : float = 3.0
var decoration_floor_pool : Array[PackedScene] = [preload("res://Scenes/Coffin.tscn"), preload("res://Scenes/Sphinx.tscn"),\
 preload("res://Scenes/Hourglass.tscn"), preload("res://Scenes/Lantern.tscn"), preload("res://Scenes/Column.tscn")]


@export var start : bool = false : set = set_start
func set_start(val : bool )->void:
	if Engine.is_editor_hint():
		create_dungeon()
	
	
var dun_cell_scene : PackedScene = preload("res://Scenes/DunCell.tscn")

var directions : Dictionary = {
	"up" : Vector3i.FORWARD, "down" : Vector3i.BACK,
	"left" : Vector3i.LEFT, "right" : Vector3i.RIGHT
}
#si la cellule voisine n'appartient pas un des 3 types concernés
func handle_all(cell : Node3D, dir : String, key : String):
	match key:
		"" : cell.call("remove_door_"+dir)
		"00" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		"01" : cell.call("remove_door_"+dir)
		"02" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		"10" : cell.call("remove_door_"+dir)
		"11" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		"12" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		"20" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		"21" : cell.call("remove_wall_"+dir)
		"22" : cell.call("remove_wall_"+dir); cell.call("remove_door_"+dir)
		#40 ou 04
		"40": cell.call("remove_door_"+dir); cell.call("remove_wall_"+dir)
		"04": cell.call("remove_door_"+dir); cell.call("remove_wall_"+dir)

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	#var number_cell_room : int = grid_map.get_used_cells_by_item(0).size()
	#var rand_cell : int = randi_range(0, number_cell_room)
	#var count_cell : int = 0
	var array_doors_3vi : Array[Vector3i] = grid_map.get_used_cells_by_item(4)
	var array_doors_3v : Array[Vector3] = []
	for door in array_doors_3vi:
		array_doors_3v.append(Vector3(door)+ Vector3(0.5, 0, 0.5))

	for cell in  grid_map.get_used_cells():
		var cell_index : int = grid_map.get_cell_item(cell)
		#si la cell n'est pas vide ou en border ou une porte
		if cell_index <= 2 && cell_index >=0 || cell_index == 4:
			var dun_cell : Node3D = dun_cell_scene.instantiate()
			dun_cell.position = Vector3(cell) + Vector3(0.5, 0, 0.5)
			#si c'est une salle
			#if cell_index == 0:
				#ajout lanterne
				#var kill : float = randf()
				#if survival_chance_lantern > kill:
					#var lantern : Node3D = lantern_instance.instantiate()
					#dun_cell.add_child(lantern)
					#
							
			
			t += 1
			for i in 4:
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				#si vide ou border
				if cell_n_index == -1 || cell_n_index == 3:
					handle_all(dun_cell, directions.keys()[i], "")				
				else:
					var key : String = str(cell_index) + str(cell_n_index)
					#error positionnement
					handle_all(dun_cell, directions.keys()[i], key)
				
			
			if array_doors_3v[0] == dun_cell.position:
					var dir : String = dun_cell.get_children()[1].name.get_slice("_", 1)
					dun_cell.call("add_exit_door_"+dir)
					if array_doors_3v.size() != 1:
						array_doors_3v.remove_at(0)
			
			
			add_child(dun_cell)
			dun_cell.set_owner(owner)
		if t%10 == 9 : await get_tree().create_timer(0).timeout
	place_objects()
	
	
func place_objects():
	var object_placed : int = 0
	
	while object_placed < number_object_to_place:
		var selected_decoration_floor : PackedScene = decoration_floor_pool[randi() % decoration_floor_pool.size()]
		var grid_position : Vector3i = Vector3i(grid_map.get_used_cells_by_item(0)[randi() % grid_map.get_used_cells_by_item(0).size()])
		var position_object : Vector3 = grid_map.map_to_local(grid_position)
		if check_min_distance_object(position_object):
			var new_deco : Node3D = selected_decoration_floor.instantiate()
			new_deco.position = position_object
			add_child(new_deco)
			object_placed += 1
				
				
func check_min_distance_object(new_position)->bool:
	for child in get_children():
		if child.is_in_group("decoration"):
			var distance = new_position.distance_to(child.position)
			if distance < min_distance_object:
				return false
	return true
