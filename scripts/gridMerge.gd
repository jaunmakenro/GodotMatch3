extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset

var tile = preload ("res://prefabs/tileNumber.tscn") #tile prefab

var all_pieces = [] #pieces dans la scene
var match_groups = [] #liste des groupes de match

var controlling = false #user is moving pieces

var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	all_pieces= make_2d_array()
	spawn_pieces()
#	print (all_pieces)

func make_2d_array():
	var array= []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func find_piece(piece):
	for i in width:
		var j = all_pieces[i].find(piece)
		if j != -1:
			return Vector2(i,j);
	return Vector2(-1,-1);

func find_match_group(piece_to_find):
	for group in match_groups:
		for piece in group:
			if piece == piece_to_find:
				var group_index = match_groups.find(group) 
				if group_index != -1:
					return group_index
	return null;

#création
func spawn_pieces():
	for i in width:
		for j in height:
			all_pieces[i][j] = create_piece(i,j,-1,"fall")

#création d'une piece a la place spécifié et avec la valeur spécifié
#si la vealur n'est pas passé, elle est choisi aléatoirement
func create_piece(column, row,value,kind):
#	print ("i: %s j: %s"% [i,j])
	#si valeur aléatoire
	var rand = int(rand_range(1,5)) #choix de la couleur
	if value == -1 :
		#on change de couleur tant qu'on match
		var loops = 0
		while(match_at(column,row, rand) && loops <100 ):
			rand = int(rand_range(1,5)) #choix de la couleur
			loops +=1
	
	value = rand
	#création de la piece
	var piece = tile.instance()
	add_child(piece)
	if kind == "fall" :
		piece.position = grid_to_pixel(column,height+row)
		piece.move (grid_to_pixel(column,row),.5)
	elif kind == "pop":
		piece.position = grid_to_pixel(column,row)
		piece.pop (.5)
	piece.get_node("offset/Label").text = str(value)
	piece.value = value
	piece.name = "tile C" + str(column) + " R" + str(row)
	return piece

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + - offset * row
	return Vector2(new_x,new_y);

func pixel_to_grid(pixel_x, pixel_y):
	var column = floor((pixel_x-x_start)/  offset) 
	var line = floor((pixel_y-y_start)/ -offset)
	return Vector2(column,line);

func is_in_grid(column,row): 
	if column >= 0 && column < width:
		if row >= 0 && row < height:
			return true
	return false

func  _input(event):
	if Input.is_action_just_pressed("ui_touch"):
		first_touch = get_global_mouse_position()
		var grid_position = pixel_to_grid(first_touch.x,first_touch.y)
		if is_in_grid(grid_position.x,grid_position.y) :
			controlling = true
		else :
			controlling = false
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position()
		var grid_position = pixel_to_grid(final_touch.x,final_touch.y)
		if is_in_grid(grid_position.x,grid_position.y) && controlling:
			touch_difference(pixel_to_grid(first_touch.x,first_touch.y),grid_position)
			controlling = false
			print("control: {first} -> final".format({"first": first_touch,"final":final_touch}))

func touch_difference(pos1,pos2):
	var diff = pos2 - pos1
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			swap(pos1.x,pos1.y,Vector2(1,0))
		if diff.x < 0:
			swap(pos1.x,pos1.y,Vector2(-1,0))
	if abs(diff.y) > abs(diff.x):
		if diff.y > 0:
			swap(pos1.x,pos1.y,Vector2(0,1))
		if diff.y < 0:
			swap(pos1.x,pos1.y,Vector2(0,-1))

func swap(column, row, direction):
	var first_piece = all_pieces[column][row]
	var initial_pos = first_piece.position
	var other_piece = all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece!= null:
		all_pieces[column][row] = other_piece
		all_pieces[column+direction.x][row+direction.y] = first_piece
		first_piece.move (other_piece.position,.5)
		other_piece.move (initial_pos,.5)
		get_parent().get_node("match_timer").start()

func _on_match_timer_timeout():
	find_matches()

#parcour de toute les pieces pour détecter les matchs
func find_matches():
	for i in range(0,width):
		for j in range(0,height):
			if all_pieces[i][j] != null:
				var current_value = all_pieces[i][j].value
				#horyzontal
				if i>0 and i<width-1:
					if all_pieces[i-1][j] != null && all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].value == current_value && all_pieces[i+1][j].value == current_value:
							all_pieces[i][j].matched = true
							all_pieces[i-1][j].matched = true
							all_pieces[i+1][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i-1][j].dim()
							all_pieces[i+1][j].dim()
							
							var finded_match_group = find_match_group(all_pieces[i][j])
							if  finded_match_group != null:
								match_groups[finded_match_group].append(all_pieces[i+1][j])
							else:
								var newgroup = []
								newgroup.append(all_pieces[i][j])
								newgroup.append(all_pieces[i-1][j])
								newgroup.append(all_pieces[i+1][j])
								match_groups.append(newgroup)
					#vertical
				if j>0 and j<height-1:
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].value == current_value && all_pieces[i][j+1].value == current_value:
							all_pieces[i][j].matched = true
							all_pieces[i][j-1].matched = true
							all_pieces[i][j+1].matched = true
							all_pieces[i][j].dim()
							all_pieces[i][j-1].dim()
							all_pieces[i][j+1].dim()
							
							var finded_match_group = find_match_group(all_pieces[i][j])
							if  finded_match_group != null:
								match_groups[finded_match_group].append(all_pieces[i][j+1])
							else:
								var newgroup = []
								newgroup.append(all_pieces[i][j])
								newgroup.append(all_pieces[i][j-1])
								newgroup.append(all_pieces[i][j+1])
								match_groups.append(newgroup)
	get_parent().get_node("merge_timer").start()

func _on_merge_timer_timeout():
	start_merge_matched()

#on vérifie si on a 3 piece de la meme couleur
#en allant uniquement vérifier a gauche et en bas
func match_at(i,j,value):
	if i > 1:
		var gauche = all_pieces[i-1][j].value
		var gauche2 = all_pieces[i-2][j].value
		if gauche == value && gauche2 == value:
			return true
	if j > 1:
		var bas = all_pieces[i][j-1].value
		var bas2 = all_pieces[i][j-2].value
		if bas == value && bas2 == value:
			return true

func start_merge_matched():
	#pour chaque groupe a détruire
	for group in match_groups:
		#choix de la position de la nouvelle piece a créer
		var rand = int(rand_range(0,group.size()))
		var value = group[0].value
		var spawnpos = find_piece(group[rand])
		var newpiece = create_piece(spawnpos.x,spawnpos.y,value+1,"pop")
		#suppresion des pieces du groupe
		for piece in group:
			piece.move(grid_to_pixel(spawnpos.x,spawnpos.y),0.5)
		all_pieces[spawnpos.x][spawnpos.y] = newpiece
	get_parent().get_node("destroy_timer").start()

func _on_destroy_timer_timeout():
	destroy_matched()

func destroy_matched():
	#pour chaque groupe a détruire
	for group in match_groups:
		#choix de la position de la nouvelle piece a créer
#		var rand = int(rand_range(0,group.size()))
#		var value = group[0].value
#		var spawnpos = find_piece(group[rand])
#		var newpiece = create_piece(spawnpos.x,spawnpos.y,value+1,"pop")
		#suppresion des pieces du groupe
		for piece in group:
			var pos = find_piece(piece)
			all_pieces[pos.x][pos.y].queue_free()
			all_pieces[pos.x][pos.y] = null
#			#todo : creer une seule tile 
#			all_pieces[pos.x][pos.y] = create_piece(pos.x,pos.y,6)
#		all_pieces[spawnpos.x][spawnpos.y] = newpiece
	match_groups = []
	get_parent().get_node("collapse_timer").start()

func _on_collapse_timer_timeout():
	collapse_collumns()
	
func collapse_collumns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j+1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j),1.5)
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
#	get_parent().get_node("refill_timer").start()

func _on_refill_timer_timeout():
	refill_collumns()

func refill_collumns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				all_pieces[i][j] = create_piece(i,j,-1,"fall")
#	find_matches()

