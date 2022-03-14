extends Node2D

export (int) var value
var move_tween
var matched  =false

func _ready():
	move_tween = $move_tween

func move(target,duration):
	move_tween.interpolate_property(self, "position", position, target, duration, Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	move_tween.start()
	
func pop(duration):
	$offset.scale = Vector2(0,0)
	move_tween.interpolate_property($offset, "scale", Vector2(0,0), Vector2(1,1), duration, Tween.TRANS_BOUNCE,Tween.EASE_OUT)
	move_tween.start()

func destroy(duration):
	$reduce_tween.interpolate_property($offset, "scale", Vector2(1,1), Vector2(0.2,0.2), duration, Tween.TRANS_BOUNCE,Tween.EASE_OUT)
	$reduce_tween.start()

#change la couleur. Appelé quand on match
func dim():
	$offset/back.modulate = Color(1,1,1,0.5)

func _on_Node2D_input_event(viewport, event, shape_idx):
	pass
###	print (event.button_index)
###	print (event.is_pressed())
#	if event.is_action_pressed("ui_touch"):
##	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
#		print (self)
#		print( get_parent().find_piece(self))
		
