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
