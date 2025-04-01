class End extends BattleState:
	func enter():
		print_rich("Se acabo la ejecucion")

class DefaulStart extends BattleState:
	
	func enter():
		
		var battle_type = ctx.battle_type
		var state_queue = ctx.state_queue
		var factory = BattleStateFactory.get_instance()

		match battle_type:
			BattleType.WILD:
				state_queue.enqueue(factory.create_enemy_entry())
				state_queue.enqueue(factory.create_ally_entry())
				state_queue.enqueue(factory.create_start_turn())
			_:
				pass
		exit()

class AllyEntry extends BattleState:

	var _idx : int
	
	func enter():
		ctx.scene.enter_pokemon_by_index(_idx,true)
		exit()

class EnemyEntry extends BattleState:
	
	var _idx : int

	
	func enter():
		ctx.scene.enter_pokemon_by_index(_idx,false)
		exit()

class StartTurn extends BattleState:

	func enter():
		ctx.state_queue.enqueue(HandleInput.new())


class HandleInput extends BattleState:

	func enter():
		ctx.state_queue.enqueue(Order.new())

class Order extends BattleState:
	func enter():
		ctx.state_queue.enqueue(ExecuteMove.new())
		exit()

class ExecuteMove extends BattleState:
	func enter():
		ctx.state_queue.enqueue(EndTurn.new())
		exit()
	
class EndTurn extends BattleState:
	func enter():
		ctx.state_queue.enqueue(StartTurn.new())
		exit()
