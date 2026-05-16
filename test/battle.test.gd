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
	battle.destroy()


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
	battle.destroy()

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

	battle.destroy()

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

	battle.destroy()

func test_real_battle_turn_by_turn_verification() -> void:
	var battle = Battle.new({
		"debug": true,
		"log": [
			"|gametype|singles",
			"|player|p1|RULT61 mc|swimmer-gen4dp|1444",
			"|player|p2|RULT61H Jump Kick|#ruplxicrunchwrap|1559",
			"|gen|9",
			"|tier|[Gen 9] RU",
			"|rated|",
			"|rule|HP Percentage Mod: HP is shown in percentages",
			"|clearpoke",
			"|poke|p1|Kleavor, M|",
			"|poke|p1|Mimikyu, F|",
			"|poke|p1|Maushold-Four|",
			"|poke|p1|Necrozma|",
			"|poke|p1|Yanmega, M|",
			"|poke|p1|Bisharp, M|",
			"|poke|p2|Blissey, F|",
			"|poke|p2|Ditto|",
			"|poke|p2|Goodra-Hisui, M|",
			"|poke|p2|Umbreon, F|",
			"|poke|p2|Gastrodon, M|",
			"|poke|p2|Noivern, F|",
			"|teampreview",
			"|teamsize|p1|6",
			"|teamsize|p2|6",
			"|start",
			"|switch|p1a: summer lose ends|Kleavor, M, shiny|100/100",
			"|switch|p2a: Gastrodon|Gastrodon, M|100/100",
			"|turn|1",
		],
	})

	var p1 = battle.sides[0]
	var p2 = battle.sides[1]

	# Turn 1: Initial state
	expect(p1.name).to_be("RULT61 mc")
	expect(p2.name).to_be("RULT61H Jump Kick")
	expect(p1.active).to_have_length(1)
	expect(p2.active).to_have_length(1)
	
	var p1_kleavor = p1.active[0]
	var p2_gastrodon = p2.active[0]
	
	expect(p1_kleavor.get_ident()).to_be("p1a: summer lose ends")
	expect(p1_kleavor.hp).to_be(100)
	expect(p1_kleavor.maxhp).to_be(100)
	expect(p1_kleavor.is_active()).to_be_truthy()
	
	expect(p2_gastrodon.get_ident()).to_be("p2a: Gastrodon")
	expect(p2_gastrodon.hp).to_be(100)
	expect(p2_gastrodon.maxhp).to_be(100)
	expect(p2_gastrodon.is_active()).to_be_truthy()

	var turn1_lines = [
		"|",
		"|move|p1a: summer lose ends|Swords Dance|p1a: summer lose ends",
		"|-boost|p1a: summer lose ends|atk|2",
		"|move|p2a: Gastrodon|Earth Power|p1a: summer lose ends",
		"|-damage|p1a: summer lose ends|53/100",
		"|",
		"|upkeep",
		"|turn|2",
	]
	
	for line in turn1_lines:
		battle.add(line)

	# Turn 2 verification
	expect(p1_kleavor.hp).to_be(53)
	expect(p1_kleavor.move_track).to_have_length(1)
	expect(p1_kleavor.move_track[0][0]).to_be("Swords Dance")
	expect(p2_gastrodon.hp).to_be(100)
	expect(p2_gastrodon.move_track).to_have_length(1)

	var turn2_lines = [
		"|",
		"|move|p1a: summer lose ends|X-Scissor|p2a: Gastrodon",
		"|-damage|p2a: Gastrodon|0 fnt",
		"|-damage|p1a: summer lose ends|37/100|[from] item: Rocky Helmet|[of] p2a: Gastrodon",
		"|faint|p2a: Gastrodon",
		"|",
		"|upkeep",
		"|",
		"|switch|p2a: Ditto|Ditto|100/100",
		"|-transform|p2a: Ditto|p1a: summer lose ends|[from] ability: Imposter",
		"|turn|3",
	]
	
	for line in turn2_lines:
		battle.add(line)

	# Turn 3 verification
	expect(p2_gastrodon.is_active()).to_be_falsy()
	expect(p1_kleavor.hp).to_be(37)
	expect(p2.active).to_have_length(1)
	
	var p2_ditto = p2.active[0]
	expect(p2_ditto.get_ident()).to_be("p2a: Ditto")
	expect(p2_ditto.is_active()).to_be_truthy()
	expect(p2_ditto.hp).to_be(100)

	var turn3_lines = [
		"|",
		"|move|p1a: summer lose ends|Quick Attack|p2a: Ditto",
		"|-resisted|p2a: Ditto",
		"|-damage|p2a: Ditto|80/100",
		"|move|p2a: Ditto|Stone Axe|p1a: summer lose ends",
		"|-supereffective|p1a: summer lose ends",
		"|-damage|p1a: summer lose ends|0 fnt",
		"|-sidestart|p1: RULT61 mc|move: Stealth Rock",
		"|faint|p1a: summer lose ends",
		"|",
		"|upkeep",
		"|",
		"|switch|p1a: practicing romance|Mimikyu, F, shiny|100/100",
		"|-damage|p1a: practicing romance|88/100|[from] Stealth Rock",
		"|turn|4",
	]
	
	for line in turn3_lines:
		battle.add(line)

	# Turn 4 verification
	expect(p1_kleavor.is_active()).to_be_falsy()
	expect(p2_ditto.hp).to_be(80)
	expect(p1.active).to_have_length(1)
	
	var p1_mimikyu = p1.active[0]
	expect(p1_mimikyu.get_ident()).to_be("p1a: practicing romance")
	expect(p1_mimikyu.is_active()).to_be_truthy()
	expect(p1_mimikyu.hp).to_be(88)
	expect(p1_mimikyu.maxhp).to_be(100)

	var turn4_lines = [
		"|",
		"|move|p2a: Ditto|Stone Axe|p1a: practicing romance",
		"|-activate|p1a: practicing romance|ability: Disguise",
		"|-damage|p1a: practicing romance|88/100",
		"|detailschange|p1a: practicing romance|Mimikyu-Busted, F, shiny",
		"|-damage|p1a: practicing romance|76/100|[from] pokemon: Mimikyu-Busted",
		"|move|p1a: practicing romance|Swords Dance|p1a: practicing romance",
		"|-boost|p1a: practicing romance|atk|2",
		"|",
		"|upkeep",
		"|turn|5",
	]
	
	for line in turn4_lines:
		battle.add(line)

	# Turn 5 verification
	expect(p1_mimikyu.hp).to_be(76)
	expect(p1_mimikyu.move_track).to_have_length(1)

	var turn5_lines = [
		"|",
		"|move|p1a: practicing romance|Shadow Sneak|p2a: Ditto",
		"|-damage|p2a: Ditto|29/100",
		"|-damage|p1a: practicing romance|66/100|[from] item: Life Orb",
		"|move|p2a: Ditto|Stone Axe|p1a: practicing romance",
		"|-damage|p1a: practicing romance|0 fnt",
		"|faint|p1a: practicing romance",
		"|",
		"|upkeep",
		"|",
		"|switch|p1a: we match|Bisharp, M|100/100",
		"|-damage|p1a: we match|94/100|[from] Stealth Rock",
		"|turn|6",
	]
	
	for line in turn5_lines:
		battle.add(line)

	# Turn 6 verification
	expect(p1_mimikyu.is_active()).to_be_falsy()
	expect(p2_ditto.hp).to_be(29)
	
	var p1_bisharp = p1.active[0]
	expect(p1_bisharp.get_ident()).to_be("p1a: we match")
	expect(p1_bisharp.is_active()).to_be_truthy()
	expect(p1_bisharp.hp).to_be(94)

	var turn6_lines = [
		"|",
		"|switch|p2a: Umbreon|Umbreon, F|100/100",
		"|move|p1a: we match|Swords Dance|p1a: we match",
		"|-boost|p1a: we match|atk|2",
		"|",
		"|upkeep",
		"|turn|7",
	]
	
	for line in turn6_lines:
		battle.add(line)

	# Turn 7 verification
	expect(p2_ditto.is_active()).to_be_falsy()
	
	var p2_umbreon = p2.active[0]
	expect(p2_umbreon.get_ident()).to_be("p2a: Umbreon")
	expect(p2_umbreon.hp).to_be(100)
	expect(p2_umbreon.is_active()).to_be_truthy()

	var turn7_lines = [
		"|",
		"|move|p1a: we match|Iron Head|p2a: Umbreon",
		"|-damage|p2a: Umbreon|44/100",
		"|-damage|p1a: we match|78/100|[from] item: Rocky Helmet|[of] p2a: Umbreon",
		"|move|p2a: Umbreon|Moonlight|p2a: Umbreon",
		"|-heal|p2a: Umbreon|94/100",
		"|",
		"|upkeep",
		"|turn|8",
	]
	
	for line in turn7_lines:
		battle.add(line)

	# Turn 8 verification
	expect(p1_bisharp.hp).to_be(78)
	expect(p2_umbreon.hp).to_be(94)
	expect(p1_bisharp.move_track).to_have_length(2)

	var turn8_lines = [
		"|",
		"|move|p1a: we match|Iron Head|p2a: Umbreon",
		"|-damage|p2a: Umbreon|38/100",
		"|-damage|p1a: we match|61/100|[from] item: Rocky Helmet|[of] p2a: Umbreon",
		"|move|p2a: Umbreon|Foul Play|p1a: we match",
		"|-resisted|p1a: we match",
		"|-damage|p1a: we match|27/100",
		"|",
		"|upkeep",
		"|turn|9",
	]
	
	for line in turn8_lines:
		battle.add(line)

	# Turn 9 verification - KO
	expect(p1_bisharp.hp).to_be(27)
	expect(p2_umbreon.hp).to_be(38)
	expect(p1_bisharp.move_track).to_have_length(2)

	var turn9_lines = [
		"|",
		"|move|p1a: we match|Iron Head|p2a: Umbreon",
		"|-damage|p2a: Umbreon|0 fnt",
		"|-damage|p1a: we match|10/100|[from] item: Rocky Helmet|[of] p2a: Umbreon",
		"|faint|p2a: Umbreon",
		"|",
		"|upkeep",
		"|",
		"|switch|p2a: Blissey|Blissey, F|100/100",
		"|turn|10",
	]
	
	for line in turn9_lines:
		battle.add(line)

	# Turn 10 verification
	expect(p2_umbreon.is_active()).to_be_falsy()
	expect(p1_bisharp.hp).to_be(10)
	
	var p2_blissey = p2.active[0]
	expect(p2_blissey.get_ident()).to_be("p2a: Blissey")
	expect(p2_blissey.is_active()).to_be_truthy()
	expect(p2_blissey.hp).to_be(100)

	battle.destroy()
