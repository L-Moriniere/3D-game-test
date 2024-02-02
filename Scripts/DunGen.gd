@tool
extends Node3D

@onready var grid_map : GridMap = $GridMap


@export var start : bool = false : set = set_start
func set_start(val : bool)->void:
	if Engine.is_editor_hint():
		generate()
		$DunMesh.create_dungeon()
	
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	#si on est à l'interieur de l'editeur
	if Engine.is_editor_hint():
		visualize_border()
	
@export_range(0,1) var survival_chance : float = 0.25
@export var room_number : int = 4
@export var room_margin : int = 1
@export var room_recursion : int = 15
@export var min_room_size: int = 2
@export var max_room_size: int = 4
@export_multiline var custom_seed : String = "" : set = set_seed
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())

@onready var exit_door_instance : PackedScene = preload("res://Scenes/ExitDoor.tscn")
@export var exit_doors_number : int = 2
var exit_door_count : int = 0



var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []




func visualize_border():
	#faire les bordure selon la taille indiquée
	grid_map.clear()
	for i in range(-1, border_size+1):
		grid_map.set_cell_item( Vector3(i, 0, -1), 3)
		grid_map.set_cell_item( Vector3(i, 0, border_size), 3)
		grid_map.set_cell_item( Vector3(border_size, 0, i), 3)
		grid_map.set_cell_item( Vector3(-1, 0, i), 3)
	
func generate():
	room_tiles.clear()
	room_positions.clear()
	if custom_seed : set_seed(custom_seed)
	var random_room_exit_doors : Array[int] = get_random_rooms()
	visualize_border()
	print("----")
	make_start_room()
	for i in room_number:
		make_room(room_recursion, random_room_exit_doors)
		
	print("room_pos : %s"%room_positions)
		
	#pour faire les couloirs il faut utiliser la fonction de triangulation de delauney qui se fait sur des vector2
	var room_pos_v2 : PackedVector2Array = []
	
	var del_graph : AStar2D = AStar2D.new()
	var min_spanning_tree_graph : AStar2D = AStar2D.new()
	
	for p in room_positions:
		room_pos_v2.append(Vector2(p.x,p.z))
		del_graph.add_point(del_graph.get_available_point_id(), Vector2(p.x,p.z))
		min_spanning_tree_graph.add_point(min_spanning_tree_graph.get_available_point_id(), Vector2(p.x,p.z))
		
	#
	var delauney : Array = Array(Geometry2D.triangulate_delaunay(room_pos_v2))
	
	for i in delauney.size()/3:
		var p1 : int = delauney.pop_front()
		var p2 : int = delauney.pop_front()
		var p3 : int = delauney.pop_front()
		del_graph.connect_points(p1, p2)
		del_graph.connect_points(p2, p3)
		del_graph.connect_points(p1, p3)
		
	var visited_points : PackedInt32Array = []
	visited_points.append(randi() % room_positions.size())
	while visited_points.size() != min_spanning_tree_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in del_graph.get_point_connections(vp):
				#check que le point n'a pas déjà été visité
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp, c]
					possible_connections.append(con)
		var connection : PackedInt32Array = possible_connections.pick_random()
		#verifier que la connection est bien la plus courte
		for pc in possible_connections:
			if room_pos_v2[pc[0]].distance_squared_to(room_pos_v2[pc[1]]) < room_pos_v2[connection[0]].distance_squared_to(room_pos_v2[connection[1]]):
				connection = pc
				
		visited_points.append(connection[1])
		min_spanning_tree_graph.connect_points(connection[0], connection[1])
		del_graph.disconnect_points(connection[0], connection[1])
				
	var hallway_graph : AStar2D = min_spanning_tree_graph
	
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c>p:
				var kill : float = randf()
				if survival_chance > kill:
					hallway_graph.connect_points(p,c)
			
	create_hallways(hallway_graph)
		
#pour chaque connection entre 2 salles, trouver 2 door tiles et store les positions
func create_hallways(hallway_graph : AStar2D):
	var hallways : Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c>p:
				#on recupere les tiles de deux salles
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				
				#on check la distance la plus courte
				for t in room_from:
					if t.distance_squared_to(room_positions[c]) < tile_from.distance_squared_to(room_positions[c]):
						tile_from = t
						
				for t in room_to:
					if t.distance_squared_to(room_positions[p]) < tile_to.distance_squared_to(room_positions[p]):
						tile_to = t

				var hallway : PackedVector3Array = [tile_from, tile_to]
				hallways.append(hallway)
				
				#ajout des portes
				grid_map.set_cell_item(tile_from, 2)
				grid_map.set_cell_item(tile_to, 2)

	#Construction des couloirs
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2.ONE * border_size
	astar.update()
	
	#pour ne pas avoir des couloirs en diagonale
	astar.diagonal_mode =AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x, t.z))
	
	#trouver les chemins
	for h in hallways:
		var pos_from : Vector2i = Vector2i(h[0].x, h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x, h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from, pos_to)
		
		#les tranformer en v3
		for t in hall:
			var pos : Vector3i = Vector3i(t.x, 0, t.y)
				#si la cellule est vide
			if grid_map.get_cell_item(pos) < 0:
				grid_map.set_cell_item(pos, 1)
			
			
			
func make_start_room():
	#calcul de la longeur et largeur d'une piece
	var width : int = 5
	var height : int = 3
	
	#calcul de starting position
	var start_pos : Vector3i

	start_pos.x = 0
	start_pos.z = 0
	
	#creation de la salle
	var room : PackedVector3Array = []
	
	#ajout des tiles room
	for row in height:
		for column in width:
			var pos : Vector3i = start_pos + Vector3i(column, 0, row)
			#index 0 car c'est l'index de la room tile
			grid_map.set_cell_item(pos, 0)
			#store la position
			room.append(pos)
	#une fois placé on ajoute la salle
	room_tiles.append(room)
	
	#avoir le centre de la salle
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)

func make_room(recursion : int, random_room_exit_doors : Array[int]):
	if !recursion>0:
		return
	
	#calcul de la longeur et largeur d'une piece
	var width : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	
	#calcul de starting position
	var start_pos : Vector3i
	#+1 pour eviter division par 0
	start_pos.x = randi() % (border_size - width + 1)
	start_pos.z = randi() % (border_size - height + 1)
	
	#creation de la salle
	#ajout de la marge entre chaque salle
	for row in range(-room_margin, height+room_margin):
		for column in range(-room_margin, width+room_margin):
			var pos : Vector3i = start_pos + Vector3i(column, 0, row)
			#si la cellule n'est pas une salle
			if grid_map.get_cell_item(pos) == 0:
				make_room(recursion-1, random_room_exit_doors)
				return
	
	var room : PackedVector3Array = []
	
	if random_room_exit_doors[0] == room_positions.size():
		var exit_door_pos = get_exit_door_position(width, height)
		for row in height:
			for column in width:
				var pos : Vector3i = start_pos + Vector3i(column, 0, row)
				#index 0 car c'est l'index de la room tile
				if row == exit_door_pos.z && column == exit_door_pos.x:
					print("ok")
					grid_map.set_cell_item(pos, 4)
				else : 
					grid_map.set_cell_item(pos, 0)
				#store la position
				room.append(pos)
		printt("exit pos : %s"% str(exit_door_pos) , "rooms : %s" % str(random_room_exit_doors))
				
		if random_room_exit_doors.size() != 1:
			random_room_exit_doors.remove_at(0)
			
			
	#ajout des tiles room
	else:
		for row in height:
			for column in width:
				var pos : Vector3i = start_pos + Vector3i(column, 0, row)
				#index 0 car c'est l'index de la room tile
				grid_map.set_cell_item(pos, 0)
				#store la position
				room.append(pos)
	#une fois placé on ajoute la salle
	room_tiles.append(room)
	
	#avoir le centre de la salle
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)

	
	
func get_random_rooms()->Array[int]:
	var array_rooms : Array[int] = []

	while array_rooms.size() < exit_doors_number:
		var r : int = randi_range(1, room_number)

		# Assurez-vous que la nouvelle valeur est distincte des valeurs déjà présentes dans le tableau
		if r not in array_rooms:
			array_rooms.append(r)
	array_rooms.sort()
	return array_rooms

func get_exit_door_position(width, height):
	# Choisissez aléatoirement une des quatre bordures (0: haut, 1: droite, 2: bas, 3: gauche)
	var border_room : int = randi_range(0, 3)

	var x : int = 1
	var z : int = 1

	# Générez une coordonnée le long de la bordure choisie
	match border_room:
		0:  # Haut
			x = randi_range(1, width - 1)
			z = 0
		1:  # Droite
			x = width - 1
			z = randi_range(1, height - 1)
		2:  # Bas
			x = randi_range(1, width - 1)
			z = height - 1 
		3:  # Gauche
			x = 0
			z = randi_range(1, height - 1)
			
	return Vector3i(x,0,z)
