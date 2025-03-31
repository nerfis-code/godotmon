extends BattleState

func enter(battle_context):
	print("El jugador %s ha entrado al combate" % battle_context.player.trainer_name)
