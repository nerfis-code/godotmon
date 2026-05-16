extends TestSuite

func test_battle_processes_messages_properly() -> void:
	var battle = Battle.new({
		"debug": true,
		"log": [
			"|init|battle",
			"|title|FOO vs. BAR",
			"|j|FOO",
			"|j|BAR",
			"|request|",
			"|player|p1|FOO|169",
			"|player|p2|BAR|265",
			"|teamsize|p1|6",
			"|teamsize|p2|6",
			"|gametype|singles",
			"|gen|7",
			"|tier|[Gen 7] Random Battle",
			"|rated|",
			"|seed|",
			"|rule|Sleep Clause Mod: Limit one foe put to sleep",
			"|rule|HP Percentage Mod: HP is shown in percentages",
			"|",
			"|start",
			"|switch|p1a: Leafeon|Leafeon, L83, F|100/100",
			"|switch|p2a: Gliscor|Gliscor, L77, F|242/242",
			"|turn|1",
		],
	})

	var p1 = battle.sides[0]
	var p2 = battle.sides[1]

	# Test p1 side
	expect(p1.name).to_be("FOO")
	
	var p1_leafeon = p1.pokemon[0]
	expect(p1_leafeon.ident).to_be("p1: Leafeon")
	expect(p1_leafeon.details).to_be("Leafeon, L83, F")
	expect(p1_leafeon.hp).to_be(100)
	expect(p1_leafeon.maxhp).to_be(100)
	expect(p1_leafeon.is_active()).to_be_truthy()
	expect(p1_leafeon.move_track).to_have_length(0)

	# Test p2 side
	expect(p2.name).to_be("BAR")
	
	var p2_gliscor = p2.pokemon[0]
	expect(p2_gliscor.ident).to_be("p2: Gliscor")
	expect(p2_gliscor.details).to_be("Gliscor, L77, F")
	expect(p2_gliscor.hp).to_be(242)
	expect(p2_gliscor.maxhp).to_be(242)
	expect(p2_gliscor.is_active()).to_be_truthy()
	expect(p2_gliscor.move_track).to_have_length(0)

	# Add more lines to the battle log
	var additional_lines = [
		"|",
		"|switch|p2a: Kyurem|Kyurem-White, L73|303/303",
		"|-ability|p2a: Kyurem|Turboblaze",
		"|move|p1a: Leafeon|Knock Off|p2a: Kyurem",
		"|-damage|p2a: Kyurem|226/303",
		"|-enditem|p2a: Kyurem|Leftovers|[from] move: Knock Off|[of] p1a: Leafeon",
		"|",
		"|upkeep",
		"|turn|2",
		"|inactive|Time left: 150 sec this turn | 740 sec total",
	]
	
	for line in additional_lines:
		battle.add(line)

	# Test that Gliscor is no longer active
	expect(p2_gliscor.is_active()).to_be_falsy()
	
	# Test that Kyurem was added to p2's team
	var p2_kyurem = p2.pokemon[1]
	expect(p2_kyurem.ident).to_be("p2: Kyurem")
	expect(p2_kyurem.details).to_be("Kyurem-White, L73")
	expect(p2_kyurem.hp).to_be(226)
	expect(p2_kyurem.maxhp).to_be(303)
	expect(p2_kyurem.is_active()).to_be_truthy()
	expect(p2_kyurem.item).to_be("")
	expect(p2_kyurem.prev_item).to_be("Leftovers")

	# Test that Leafeon's move track was updated
	expect(p1_leafeon.move_track).to_equal([["Knock Off", 1]])


func test_pokemon_hp_damage_tracking() -> void:
	var battle = Battle.new({
		"debug": true,
		"log": [
			"|init|battle",
			"|title|ALICE vs. BOB",
			"|j|ALICE",
			"|j|BOB",
			"|request|",
			"|player|p1|ALICE|100",
			"|player|p2|BOB|100",
			"|teamsize|p1|3",
			"|teamsize|p2|3",
			"|gametype|singles",
			"|gen|7",
			"|tier|[Gen 7] Random Battle",
			"|rated|",
			"|seed|",
			"|",
			"|start",
			"|switch|p1a: Charizard|Charizard, L80, M|280/280",
			"|switch|p2a: Dragonite|Dragonite, L78, M|269/269",
			"|turn|1",
		],
	})

	var p1 = battle.sides[0]
	var p2 = battle.sides[1]

	var p1_charizard = p1.pokemon[0]
	var p2_dragonite = p2.pokemon[0]

	expect(p1_charizard.hp).to_be(280)
	expect(p2_dragonite.hp).to_be(269)

	var damage_lines = [
		"|",
		"|move|p1a: Charizard|Fire Punch|p2a: Dragonite",
		"|-damage|p2a: Dragonite|180/269",
		"|move|p2a: Dragonite|Outrage|p1a: Charizard",
		"|-damage|p1a: Charizard|145/280",
		"|",
		"|upkeep",
		"|turn|2",
	]
	
	for line in damage_lines:
		battle.add(line)

	expect(p1_charizard.hp).to_be(145)
	expect(p2_dragonite.hp).to_be(180)
	expect(p1_charizard.move_track).to_have_length(1)
	expect(p2_dragonite.move_track).to_have_length(1)


func test_multiple_pokemon_switches() -> void:
	var battle = Battle.new({
		"debug": true,
		"log": [
			"|init|battle",
			"|title|CAROL vs. DAVE",
			"|j|CAROL",
			"|j|DAVE",
			"|request|",
			"|player|p1|CAROL|200",
			"|player|p2|DAVE|200",
			"|teamsize|p1|4",
			"|teamsize|p2|4",
			"|gametype|singles",
			"|gen|7",
			"|tier|[Gen 7] Random Battle",
			"|rated|",
			"|seed|",
			"|",
			"|start",
			"|switch|p1a: Alakazam|Alakazam, L81|244/244",
			"|switch|p2a: Machamp|Machamp, L76|248/248",
			"|turn|1",
		],
	})

	var p1 = battle.sides[0]
	var p2 = battle.sides[1]

	expect(p1.pokemon[0].ident).to_be("p1: Alakazam")
	expect(p1.pokemon).to_have_length(1)
	expect(p2.pokemon[0].ident).to_be("p2: Machamp")
	expect(p2.pokemon).to_have_length(1)

	var switch_lines = [
		"|",
		"|switch|p1a: Gengar|Gengar, L82|240/240",
		"|move|p2a: Machamp|Close Combat|p1a: Gengar",
		"|-damage|p1a: Gengar|120/240",
		"|",
		"|switch|p2a: Alakazam|Alakazam, L80|232/232",
		"|move|p1a: Gengar|Sludge Bomb|p2a: Alakazam",
		"|-damage|p2a: Alakazam|150/232",
		"|",
		"|upkeep",
		"|turn|2",
	]
	
	for line in switch_lines:
		battle.add(line)

	expect(p1.pokemon).to_have_length(2)
	expect(p1.pokemon[1].ident).to_be("p1: Gengar")
	expect(p1.pokemon[1].is_active()).to_be_truthy()
	
	expect(p2.pokemon).to_have_length(2)
	expect(p2.pokemon[1].ident).to_be("p2: Alakazam")
	expect(p2.pokemon[1].is_active()).to_be_truthy()


func test_pokemon_item_and_ability_tracking() -> void:
	var battle = Battle.new({
		"debug": true,
		"log": [
			"|init|battle",
			"|title|EVE vs. FRANK",
			"|j|EVE",
			"|j|FRANK",
			"|request|",
			"|player|p1|EVE|150",
			"|player|p2|FRANK|150",
			"|teamsize|p1|2",
			"|teamsize|p2|2",
			"|gametype|singles",
			"|gen|7",
			"|tier|[Gen 7] Random Battle",
			"|rated|",
			"|seed|",
			"|",
			"|start",
			"|switch|p1a: Tyranitar|Tyranitar, L79, M|277/277",
			"|switch|p2a: Gardevoir|Gardevoir, L75, F|216/216",
			"|-ability|p1a: Tyranitar|Sand Stream",
			"|-ability|p2a: Gardevoir|Synchronize",
			"|turn|1",
		],
	})

	var p1 = battle.sides[0]
	var p2 = battle.sides[1]

	var p1_tyranitar = p1.pokemon[0]
	var p2_gardevoir = p2.pokemon[0]

	expect(p1_tyranitar.ability).to_be("Sand Stream")
	expect(p2_gardevoir.ability).to_be("Synchronize")

	var ability_and_item_lines = [
		"|",
		"|move|p1a: Tyranitar|Stone Edge|p2a: Gardevoir",
		"|-damage|p2a: Gardevoir|100/216",
		"|move|p2a: Gardevoir|Moonblast|p1a: Tyranitar",
		"|-damage|p1a: Tyranitar|180/277",
		"|",
		"|upkeep",
		"|turn|2",
	]
	
	for line in ability_and_item_lines:
		battle.add(line)

	expect(p1_tyranitar.ability).to_be("Sand Stream")
	expect(p2_gardevoir.ability).to_be("Synchronize")
	expect(p1_tyranitar.hp).to_be(180)
	expect(p2_gardevoir.hp).to_be(100)
