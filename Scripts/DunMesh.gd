@tool
extends Node3D

@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)
@onready var lantern_instance = preload("res://Scenes/Lantern.tscn")
@export_range(0,1) var survival_chance : float = 0.15

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
	

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	for cell in  grid_map.get_used_cells():
		var cell_index : int = grid_map.get_cell_item(cell)
		#si la cell n'est pas vide ou en border
		if cell_index <= 2 && cell_index >=0 :
			var dun_cell : Node3D = dun_cell_scene.instantiate()
			dun_cell.position = Vector3(cell) + Vector3(0.5, 0, 0.5)
			#ajouter lantern dans les salles uniquement
			if cell_index == 0:
				var kill : float = randf()
				if survival_chance> kill:
					var lantern : Node3D = lantern_instance.instantiate()
					dun_cell.add_child(lantern)
			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t += 1
			for i in 4:
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				#si vide ou border
				if cell_n_index == -1 || cell_n_index == 3:
					handle_all(dun_cell, directions.keys()[i], "")
				else:
					var key : String = str(cell_index) + str(cell_n_index)
					handle_all(dun_cell, directions.keys()[i], key)
		if t%10 == 9 : await get_tree().create_timer(0).timeout
				
				
