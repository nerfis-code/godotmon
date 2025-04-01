class Test extends BattleState:

    func enter(battle_context):
        battle_context.scene.enter_pokemon_by_index(0,true)
        battle_context.scene.enter_pokemon_by_index(0,false)

class AllyEntry extends BattleState:
    
    func enter(context):
        if context.has("pokemon_entry_idx"):
            context.scene.enter_pokemon_by_index(context.pokemon_entry_idx,true)
            context.erase("pokemon_entry_idx")
        else:
            context.scene.enter_pokemon_by_index(0,true)
        
        exit(context)

class EnemyEntry extends BattleState:
    
    func enter(context):
        if context.has("pokemon_entry_idx"):
            context.scene.enter_pokemon_by_index(context.pokemon_entry_idx,false)
            context.erase("pokemon_entry_idx")
        else:
            context.scene.enter_pokemon_by_index(0,false)