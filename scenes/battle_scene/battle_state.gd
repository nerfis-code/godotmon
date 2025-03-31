class_name BattleState

var message: String
var animation

func enter(battle_context):
	pass

func exit(battle_context):
	battle_context.scene.next_state()

func handle_input(_event):
	pass

func update(_delta):
	
	pass
