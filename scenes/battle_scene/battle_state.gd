class_name BattleState 

var _message: String
var _animation
var ctx: BattleContext


# Método abstracto que implementarán las subclases
func enter() -> void:
	pass

func exit() -> void:
	ctx.scene.next_state()

func handle_input(_event):
	pass

func update(_delta):
	
	pass
