extends Node2D

enum { WILD, TRAINER }

var _current_state: BattleState
var _context: DynamicObject

var battlers
var battle_field
var background

func init(context: DynamicObject):
	_context = context
	_context.scene = self

func change_state(new_state: BattleState):
	_current_state = new_state
	_current_state.enter(_context)

func _enter_tree() -> void:
	
	battlers = get_node("BattleField/Battlers")
	battle_field = get_node("BattleField")
	background = get_node("BattleField/Background")

	next_state()

func next_state():
	change_state(_context.state_queue.dequeue())
	
func update():
	if _context.state_queue.front() != _current_state:
		change_state(_context.state_queue.dequeue())

func enter_pokemon_by_index(idx, is_ally):
	var current_party = _context.player_party if is_ally else _context.enemy_party
	var current_pokemon = current_party[idx]
	var pos = Vector2(100,800) if is_ally else Vector2(800,100)
	var current_battler = Battler.new(DynamicObject.new({
			"pokemon": current_pokemon,
			"scene": self,
			"is_ally": is_ally,
			"position": pos
	}))
	battlers.add_child(current_battler)
