
func create_pokemon(pokemon_name: String) -> Pokemon:
	var pokemon =  Pokemon.new()
	var species = _get_specie(pokemon_name)
	pokemon.species = species
	pokemon.name = species.name
	pokemon.level = 50
	pokemon.species_name = species.species
	pokemon.primary_type = species.primaryType
	pokemon.secondary_type = species.secondaryType

	pokemon.calculate_stats()
	_learn_movements_by_level(pokemon)

	print(pokemon)
	return pokemon
	
func _get_specie(specie_name: String):

	var file_string = FileAccess.open("res://pbs/species/%s.json" % specie_name.to_upper(), FileAccess.READ).get_as_text()
	var json = JSON.new()
	var error = json.parse(file_string)
	if error == OK:
		return DynamicObject.new(json.data)
	else:
		return null

func _learn_movements_by_level(pokemon: Pokemon):
	var moveset = []
	for temp in pokemon.species.moves:
		var required_level = temp[0]
		var move = temp[1]
		
		if pokemon.level < required_level: break
		if required_level < 1: continue

		if moveset.size() < 4: moveset.append(move)
		else: moveset[randi_range(0,3)] = move
	pokemon.moves = moveset

func create_random_pokemon():
	var dir = DirAccess.open("res://pbs/species/")
	var seletedPokemonIndex = randi_range(0,1024) 
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			seletedPokemonIndex -= 1
			if !dir.current_is_dir() && seletedPokemonIndex <= 0:
				return create_pokemon(file_name.split(".")[0])
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

	return create_pokemon("charmander")
