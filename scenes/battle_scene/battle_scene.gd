extends Node2D

enum { WILD, TRAINER}

var _current_state: BattleState
var _context: DynamicObject

func init(context: DynamicObject):
	_context = context
	_context.scene = self

func change_state(new_state: BattleState):
	_current_state = new_state
	_current_state.enter(_context)

func _enter_tree() -> void:
	update()

func next_state():
	change_state(_context.state_queue.dequeue())
	
func update():
	if _context.state_queue.front() != _current_state:
		change_state(_context.state_queue.dequeue())
