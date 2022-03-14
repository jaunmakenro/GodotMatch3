extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset

var tile = preload ("res://prefabs/tile.tscn") #tile prefab
export(Array, Color) var possible_color #liste des couleurs

var all_pieces = [] #pieces dans la scene

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

func spawn_pieces():
	for i in width:
		for j in height:
#			print ("i: %s j: %s"% [i,j])
			var rand = floor(rand_range(0,possible_color.size())) #choix de la couleur
			#on change de couleur tant qu'on match
			var loops = 0
			while(match_at(i,j, possible_color[rand]) && loops <100 ):
				rand = floor(rand_range(0,possible_color.size())) #choix de la couleur
				loops +=1
			
			#création de la piece
			var piece = tile.instance()
			add_child(piece)
			piece.position = grid_to_pixel(i,-1)
			piece.move (grid_to_pixel(i,j),1.5)
			piece.get_node("front").modulate = possible_color[rand]
			piece.color = possible_color[rand]
			all_pieces[i][j] = piece

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
		print ("first touch")
		first_touch = get_global_mouse_position()
#		print (first_touch)
		var grid_position = pixel_to_grid(first_touch.x,first_touch.y)
		print (grid_position) 
		print (is_in_grid(grid_position.x,grid_position.y))
		if is_in_grid(grid_position.x,grid_position.y) :
			controlling = true
		else :
			controlling = false
	if Input.is_action_just_released("ui_touch"):
		print ("final touch")
		final_touch = get_global_mouse_position()
		var grid_position = pixel_to_grid(final_touch.x,final_touch.y)
		print (grid_position) 
		print (is_in_grid(grid_position.x,grid_position.y))
		if is_in_grid(grid_position.x,grid_position.y) && controlling:
			print ("swipe")
			touch_difference(pixel_to_grid(first_touch.x,first_touch.y),grid_position)
			controlling = false

func swap(column, row, direction):
	var first_piece = all_pieces[column][row]
	var initial_pos = first_piece.position
	var other_piece = all_pieces[column+direction.x][row+direction.y]
	if first_piece != null && other_piece!= null:
		all_pieces[column][row] = other_piece
		all_pieces[column+direction.x][row+direction.y] = first_piece
		first_piece.move (other_piece.position,.5)
		other_piece.move (initial_pos,.5)
		find_matches()
	
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
	
	
func _process(delta):
#	touch_input()
	pass

#parcour de toute les pieces pour détecter les matchs
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i>0 && i<width -1:
					if all_pieces[i-1][j] != null && all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							all_pieces[i][j].matched = true
							all_pieces[i-1][j].matched = true
							all_pieces[i+1][j].matched = true
							all_pieces[i][j].dim()
							all_pieces[i-1][j].dim()
							all_pieces[i+1][j].dim()
				if j>0 && j< height -1:
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							all_pieces[i][j].matched = true
							all_pieces[i][j-1].matched = true
							all_pieces[i][j+1].matched = true
							all_pieces[i][j].dim()
							all_pieces[i][j-1].dim()
							all_pieces[i][j+1].dim()
	get_parent().get_node("destroy_timer").start()

#on vérifie si on a 3 piece de la meme couleur
#en allant uniquement vérifier a gauche et en bas
func match_at(i,j,color):
	if i > 1:
		var gauche = all_pieces[i-1][j].color
		var gauche2 = all_pieces[i-2][j].color
		if gauche == color && gauche2 == color:
			return true
			
	if j > 1:
		var bas = all_pieces[i][j-1].color
		var bas2 = all_pieces[i][j-2].color
		if bas == color && bas2 == color:
			return true

func destroy_matched():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	get_parent().get_node("collapse_timer").start()
	
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
	get_parent().get_node("refill_timer").start()

func refill_collumns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand = floor(rand_range(0,possible_color.size())) #choix de la couleur
				#on change de couleur tant qu'on match
				var loops = 0
				while(match_at(i,j, possible_color[rand]) && loops <100 ):
					rand = floor(rand_range(0,possible_color.size())) #choix de la couleur
					loops +=1
				
				#création de la piece
				var piece = tile.instance()
				add_child(piece)
				piece.position = grid_to_pixel(i,0)
				piece.move (grid_to_pixel(i,j),1.0)
				piece.get_node("front").modulate = possible_color[rand]
				piece.color = possible_color[rand]
				all_pieces[i][j] = piece
	find_matches()

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_collumns()

func _on_refill_timer_timeout():
	refill_collumns()
