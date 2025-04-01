class Test extends BattleState:

    func enter(battle_context):
        battle_context.scene.enter_pokemon_by_index(0,true)
        battle_context.scene.enter_pokemon_by_index(0,false)