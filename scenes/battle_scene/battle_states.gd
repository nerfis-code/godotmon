class Test extends BattleState:

	func enter(battle_context):
		battle_context.scene.enter_pokemon_by_index(0,true)
		battle_context.scene.enter_pokemon_by_index(0,false)
		

class End extends BattleState:

	func enter(context):
		print_rich("Se acabo la ejecucion")

class DefaulStart extends BattleState:
	
	func enter(context):
		
		var battle_type = context.battle_type
		var state_queue = context.state_queue
		var factory = BattleStateFactory.new()

		match battle_type:
			BattleType.WILD:
				state_queue.enqueue(factory.create_enemy_entry())
				state_queue.enqueue(factory.create_ally_entry())
				state_queue.enqueue(factory.create_start_turn())
			_:
				pass
		exit(context)

class AllyEntry extends BattleState:

	var _idx : int

	func _init(idx=0,message="",animation=null) -> void:
		super(message,animation)
		_idx= idx
	
	func enter(context):
		context.scene.enter_pokemon_by_index(_idx,true)
		exit(context)

class EnemyEntry extends BattleState:
	
	var _idx : int

	func _init(idx=0,message="",animation=null) -> void:
		super(message,animation)
		_idx= idx
	
	func enter(context):
		context.scene.enter_pokemon_by_index(_idx,false)
		exit(context)

class StartTurn extends BattleState:

	func enter(context):
		context.state_queue.enqueue(HandleInput.new())

		exit(context)

class HandleInput extends BattleState:

	func enter(context):
		context.state_queue.enqueue(Order.new())
# start_turn -> handle_input -> order -> execute_move -> end_turn -> start_turn

class Order extends BattleState:
	func enter(context):
		context.state_queue.enqueue(ExecuteMove.new())
		exit(context)

class ExecuteMove extends BattleState:
	func enter(context):
		context.state_queue.enqueue(EndTurn.new())
		exit(context)
	
class EndTurn extends BattleState:
	func enter(context):
		context.state_queue.enqueue(StartTurn.new())
		exit(context)
