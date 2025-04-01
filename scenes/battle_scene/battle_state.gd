class_name BattleState 

var _message: String
var _animation


func _init(message: String = "", animation = null) -> void:
	_message = message
	_animation = animation


# Método abstracto que implementarán las subclases
func enter(_context: BattleContext) -> void:
	pass

func exit(context: BattleContext) -> void:
	context.scene.next_state()

func handle_input(_event):
	pass

func update(_delta):
	
	pass
