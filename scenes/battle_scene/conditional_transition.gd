class_name ConditionalTransition

var _condition: Callable
var _true_state: BattleState
var _false_state: BattleState

func _init(condition: Callable, true_state: BattleState, false_state: BattleState = null) -> void:
	_condition = condition
	_true_state = true_state
	_false_state = false_state

func evaluate(context) -> BattleState:
	if _condition.call(context):
		return _true_state
	return _false_state
