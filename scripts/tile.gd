extends Node2D

export (Color) var color
var move_tween
var matched  =false

func _ready():
	move_tween = $move_tween

func move(target,duration):
	move_tween.interpolate_property(self, "position", position, target, duration, Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	move_tween.start()

#change la couleur. Appelé quand on match
func dim():
	$front.modulate = Color(1,1,1,0.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
