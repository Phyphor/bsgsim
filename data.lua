crossroads_cards = {
{
	name = "Strange Music",
	desc = [[[b]Strange Music[/b]
[b]Benevolent[/b]: You must choose a player and look at all of his loyalty cards. Then discard 1 trauma token
[b]Antagonistic[/b]: Shuffle 1 "You are not a cylon" card into the Loyalty deck. Then choose a human player to draw 1 Loyalty Card. Each Cylon players draws a Trauma token
]],

	choice = "crossroads",
	a = {choose_player={effect={look_at_loyalty={qty=99}}}, discard_trauma=1},
	b = {crossroads_strange_music=true},
},

{
	name = "Testimony",
	desc = [[[b]Testimony[/b]
[b]Benevolent[/b]: Choose another player. That player discards 2 random skill cards and may discard 2 trauma tokens
[b]Antagonistic[/b]: Choose another player. That player draws 2 skill cards and must draw 2 trauma tokens
]],
	choice = "crossroads",
	a = {choose_player={ effect={discard_trauma=2, random_discard={chosen=2}} }},
	b = {choose_player={ effect={draw_trauma=2, draw_cards={chosen=2}} }},
},

{
	name = "The Opera House",
	desc = [[[b]The Opera House[/b]
[b]Benevolent[/b]: Draw 3 trauma tokens. Then choose another player to also draw 3 trauma tokens
[b]Antagonistic[/b]: No effect
]],
	choice = "crossroads",
	a = {sequence = {{draw_trauma=3}, {choose_player={effect={draw_trauma=3}}}}},
	b = {},
},

{
	name = "Disturbing Vision",
	desc = [[[b]Disturbing Vision[/b]
[b]Benevolent[/b]: Discard 2 trauma tokens and 2 random skill cards
[b]Antagonistic[/b]: Each Cylon player draws 2 trauma tokens. Then the Admiral is executed
]],
	choice = "crossroads",
	a = {discard_trauma=2, random_discard=2},
	b = {crossroads_disturbing_vision_antagonistic=true},
},

{
	name = "Perjury",
	desc = [[[b]Perjury[/b]
[b]Benevolent[/b]: You must discard 2 random skill card and may then discard 2 trauma tokens
[b]Antagonistic[/b]: You must draw 2 trauma tokens and may then draw 2 skill cards
]],
	choice = "crossroads",
	a = {sequence={{random_discard=2}, {discard_trauma=2}}},
	b = {sequence={{draw_trauma=2}, {draw_cards={acting=2}}}},
},

{
	name = "Miraculous Return",
	desc = [[[b]Miraculous Return[/b]
[b]Benevolent[/b]: +1 morale. If any vipers have been destroyed, move 1 destroyed viper to reserves. Activate raiders twice
[b]Antagonistic[/b]: -1 morale. Draw and destroy one civilian ship. Choose one basestar to damage
]],

	choice = "crossroads",
	a = {morale=1, crossroads_miraculous_return_benevolent=true},
	b = {morale=-1, civ=-1, crossroads_miraculous_return_antagonistic=true},
},

{
	name = "Scanned",
	desc = [[[b]Scanned[/b]
[b]Benevolent[/b]: -1 morale. Remove 4 raiders of your choice from the main board.
[b]Antagonistic[/b]: Activate raiders. +1 jump prep
]],

	choice = "crossroads",
	a = {morale = -1, crossroads_scanned=true},
	b = {jump_prep=1, activate_raiders=true},
},


}


base_crisis_cards = {

{
	id = 1,
	name = "Crippled Raider",
	choice = "current",
	a = {
		check = { val = 10, pass = { jump_prep = 1 }, fail = { pop = -1 }, tac = true, eng = true }
	},
	b = { try = { roll = 5, fail={place_civ="rear", place_raiders={qty=3, at="front"} } } },
	jump = true,
	activate = "raider",
	desc = [[[b]Crippled Raider[/b]

Current Player must choose:
A) Skill Check [10] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Increase the Jump Preparation track by 1.
Fail: -1 population.
[b]OR[/b]
B) Roll a die. If 4 or lower, place 3 Raiders in front of Galactica and 1 Civilian Ship behind it.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 2,
	name = "Prisoner Revolt",
	check = {
		val = 11, partialval = 6, lea = true, pol = true, tac = true,
		fail = { pop = -1, force_title_change = {title="president", chooser="president"}},
		partial = { pop = -1 }, 
	},
	jump = true,
	activate = "heavy",
	desc = [[[b]Prisoner Revolt[/b]

Skill Check [11] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
6+: -1 Population.
Fail: -1 Population, and the President chooses another player to receive the President title.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},


{
	id = 3,
	name = "Guilt By Collusion",
	jump = true, activate = "raider",
	check = {
		val = 9, lea=true, tac=true,
		pass = { choice_force_move = {chooser="current", to="brig", forced = false}},
		fail = { morale = -1 },
	},
	desc = [[[b]Guilt By Collusion[/b]

Skill Check [9] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: The current player may choose a character to move to the "Brig".
Fail: -1 Morale.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 4,
	name = "Terrorist Investigations",
	jump = true,
	activate = "heavy",
	check = { val = 12, lea = true, pol = true, partialval = 6, fail = { morale = -1 }, pass = { look_at_loyalty = {chooser="current", qty=1}}},
	desc = [[[b]Terrorist Investigations[/b]

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: Current player looks at 1 random Loyalty Card belonging to any player.
6+: No effect.
Fail: -1 Morale.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},

{
	id = 5,
	name = "Build Cylon Detector",
	choice = "admiral",
	a = { condition = function(state) return state.nukes > 0 end, nukes = -1 },
	b = { morale = -1, card_draws = { admiral = -2 } },
	activate = "heavy",
	desc = [[[b]Build Cylon Detector[/b]

Admiral must choose:
A) Discard 1 nuke token. If you do not have any nuke tokens, you may not choose this option.
[b]OR[/b]
B) -1 morale and the Admiral discards 2 Skill Cards.

[b]After Crisis[/b]: Activate Heavy Raiders]],
},


{
	id = 6,
	name = "A Traitor Accused",
	choice = "current",
	a = { check = { val = 8, pol = true, lea = true, fail = { choice_force_move = {chooser="current", forced = true, to="brig"} } } },
	b = { card_draws = {current = -5 } },
	activate = "raiders",
	jump = true,
	desc = [[[b]A Traitor Accused[/b]

Current Player must choose:
A) Skill Check [8] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: The current player chooses a character to send to the "Brig".
[b]OR[/b]
B) The current player discards 5 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 7,
	name = "Scouting For Water",
	choice = "current",
	a = { check = { val=9, pil=true, tac=true, pass={food=1}, fail={food=-1, raptor=-1} }},
	b = { food = -1 },
	activate = "raiders",
	jump = true,
	desc = [[[b]Scouting for Water[/b]

Current Player must choose:
A) Skill Check [9] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: +1 Food.
Fail: -1 Fuel and destroy 1 Raptor.
[b]OR[/b]
B) -1 Food.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 8,
	name = "Bomb Threat",
	choice = "current",
	a = { check = { val=13, pol=true, tac=true, lea=true, fail={morale=-1, civ=-1} }},

	b = { try = { roll = 5, fail = {morale=-1, civ=-1} } },
	activate = "raider",
	jump = true,
	desc = [[[b]Bomb Threat[/b]

Current Player must choose:
A) Skill Check [13] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 morale and draw a civilian ship and destroy it.
[b]OR[/b]
B) Roll a die. If 4 or lower, trigger the "Fail" effect of this card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
} , 

{
	id = 9,
	name = "Jump Computer Failure",
	check = { val = 7, tac = true, eng = true, fail = {pop=-1, jump_prep=-1} },
	activate = "launch raiders",
	desc = [[[b]Jump Computer Failure[/b]

Skill Check [7] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: -1 Population and move the fleet token 1 space towards the start of the Jump Preparation track.

[b]After Crisis[/b]: Launch Raiders]],
},

{
	id = 10,
	name = "Admiral Grilled",
	choice = "current",
	a = { check = { val = 9, pol = true, lea = true, fail = { morale=-1, card_draws={admiral=-2} } } },
	b = { morale = -1 },
	activate = "raider",
	jump = true,
	desc = [[[b]Admiral Grilled[/b]

Current Player must choose:
A) Skill Check [9] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: -1 morale, and the Admiral discards 2 Skill Cards.
[b]OR[/b]
B) -1 morale.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 11,
	name = "Scouting For Fuel",
	choice = "current",
	a = { check = { val = 12, pil = true, tac = true, pass = { fuel = 1 }, fail = { fuel=-1, raptor=-1 } } },
	b = { try = { roll = 5, fail = {fuel=-1} } },
	activate = "raider",
	jump = true,
	desc = [[[b]Scouting for Fuel[/b]

Current Player must choose:
A) Skill Check [12] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: +1 Fuel
Fail: -1 Fuel and destroy 1 Raptor
[b]OR[/b]
B) Roll a die. If 4 or lower, -1 Fuel.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},

{
	id = 12,
	name = "Missing G4 Explosives",
	check = { val = 7, lea = true, tac = true, fail = {food=-1, force_move={from="armory", to="brig", who="all"} } },
	activate="raider",
	desc = [[[b]Missing G4 Explosives[/b]

Skill Check [7] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Food, and all characters in the "Armory" location are sent to the "Brig".

[b]After Crisis[/b]: Activate Raiders]],
},

{
	id = 13,
	name = "Prison Labor",
	check = { val = 10, lea = true, tac = true, pol = true, fail = {food=-1, morale=-1}},
	activate="raider",
	desc = [[[b]Prison Labor[/b]

Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Morale, -1 Food.

[b]After Crisis[/b]: Activate Raiders]],
},

{
	id = 14,
	name = "Riots",
	choice = "admiral",
	a = { food=-1, morale=-1 }, b = {pop = -1, fuel = -1},
	activate = "launch raiders",
	desc = [[[b]Riots[/b]

Admiral must choose:
A) -1 Food, -1 Morale
[b]OR[/b]
B) -1 Population, -1 Fuel

[b]After Crisis[/b]: Launch Raiders]],
},

{
	id = 15,
	name = "Water Shortage",
	choice = "president",
	a = { food=-1 }, b = {card_draws={president=-2, current=-3}},
	activate = "basestar",
	desc = [[[b]Water Shortage[/b]

President must choose:
A) -1 Food
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars]],
},

{
	id = 16,
	name = "Water Shortage",
	choice = "president",
	a = { food=-1 }, b = {card_draws={president=-2, current=-3}},
	activate = "raider",
	jump = true,
	desc = [[[b]Water Shortage[/b]

President must choose:
A) -1 Food
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
},

{
	id = 17,
	name = "Detector Sabotage",
	check = { val = 8, tac = true, lea = true, fail = {set_flag="no_loyalty_peeking", force_move={from="research", to="sickbay", who="all"}}},
	activate = "heavy",
	jump = true,
	desc = [[[b]Detector Sabotage[/b]

Skill Check [8] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: All characters in the "Research Lab" location are sent to "Sickbay". Keep this card in play. Players may not look at other players’ Loyalty Cards.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},

{
	id = 18,
	name = "Unexpected Reunion",
	check = {val=8, pol=true, lea=true, tac=true, fail = {morale=-1, card_draws={current=-99}}},
	activate = "raider",
	desc = [[[b]Unexpected Reunion[/b]

Skill Check [8] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Morale, and the current player discards his hand of Skill Cards.

[b]After Crisis[/b]: Activate Raiders]],
},
{
	id = 19,
	name = "Cylon Virus",
	check = {val=13, tac=true, eng=true, fail={force_move={from="ftl", to="sickbay", who="all"}, centurion=1}},
	activate="launch raiders",
	desc = [[[b]Cylon Virus[/b]

Skill Check [13] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: All characters in the "FTL Control" location are sent to "Sickbay". Then place 1 centurion marker at the start of the Boarding Party track.

[b]After Crisis[/b]: Launch Raiders]],
},
{
	id = 20,
	name = "Keep Tabs on Visitor",
	choice = "current",
	a = { check = { val = 12, pol = true, lea = true, tac = true, fail = { try = { roll = 5, fail = { pop = -2 } } } } },
	b = { random_discard={current=4} },
	activate = "raider",
	jump = true,
	desc = [[[b]Keep Tabs on Visitor[/b]

Current Player must choose:
A) Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: Roll a die. If 4 or lower, -2 population.
[b]OR[/b]
B) The current player discards 4 random Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 21,
	name = "Send Survey Team",
	choice = "current",
	a = { check = { val = 15, pil = true, eng = true, tac = true, fail = { raptor=-1, force_move={to="sickbay", who="current"} } } },
	b = { try = { roll = 5, fail = { fuel=-1 } } },
	activate = "raider",
	jump = true,
	desc = [[[b]Send Survey Team[/b]

Current Player must choose:
A) Skill Check [15] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect.
Fail: The current player is sent to "Sickbay" and destroy 1 Raptor.
[b]OR[/b]
B) Roll a die. If 5 or less, -1 Fuel.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 22,
	name = "Mandatory Testing",
	check = { val = 13, partialval=9, pol = true, lea = true, pass = {look_at_loyalty = {chooser="president", qty=1}}, fail={morale=-1} },
	activate = "heavy",
	jump = true,
	desc = [[[b]Mandatory Testing[/b]

Skill Check [13] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: The President looks at 1 random Loyalty Card of the current player.
9+: No effect.
Fail: -1 Morale.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation
]],
},
{
	id = 23,
	name = "Water Sabotaged",
	choice = "current",
	a = { check = { val = 13, lea=true, pol=true, tac=true, fail={food=-2} } },
	b = {food=-1},
	activate = "raider",
	jump = true,
	desc = [[[b]Water Sabotaged[/b]

Current player must choose:
A) Skill Check [13] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -2 Food.
[b]OR[/b]
B) -1 Food.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 24,
	name = "Witch Hunt",
	check = { val = 10, lea=true, pol=true, partialval=6, partial={morale=-1}, fail={morale=-1, choice_force_move = {chooser="current", forced = true, to="sickbay"}}},
	activate = "heavy",
	jump = true,
	desc = [[[b]Witch Hunt[/b]

Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect.
6+: -1 Morale.
Fail: -1 Morale. Current player chooses a character and moves him to "Sickbay".

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},
{
	id = 25,
	name = "Tactical Strike",
	attack = {
		{activate="raider"},
		{placement={front={heavy=1}, pbow={basestar=1, raider=5}, paft={vipers=2, civ=1}, rear={civ=1}, saft={civ=1} }},
		{damage_vipers={qty=2, reserve=true}}
	},
	desc = [[[b]Tactical Strike[/b]

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Heavy Raider
Starboard-Quarter (1 o'clock): 1 Civilian Ship
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 2 Vipers, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Basestar, 5 Raiders
3) Special Rule - Hangar Assault
Damage 2 Vipers in the reserves.]],
},
{
	id = 26,
	name = "Legendary Discovery",
	activate = "launch raiders",
	check = {val=14, tac=true,pil=true, pass={distance=1}, fail={food=-1, raptor=-1}}
},
{
	id = 27,
	name = "Security Breach",
	activate = "launch raiders",
	check = {val=6, lea=true, tac=true, fail={morale=-1, force_move={from="command", to="sickbay", who="all"}}},
	desc = [[[b]Security Breach[/b]

Skill Check [6] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Morale, and all characters in the "Command" location are sent to "Sickbay".

[b]After Crisis[/b]: Launch Raiders]],
},
{
	id = 28,
	name = "Food Shortage",
	activate = "raider",
	jump = true,
	choice="president",
	a = {food=-2},
	b = { food=-1, card_draws={president=-2, current=-3} },
	desc = [[[b]Food Shortage[/b]

President must choose:
A) -2 Food.
[b]OR[/b]
B) -1 Food. The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]]
},
{
	id = 29,
	name = "Cylon Swarm",
	attack = {
		{activate="basestar"},
		{placement={sbow={heavy=1}, front={basestar=1, raider=5}, paft={vipers=1, civ=1}, rear={civ=1}, pbow={vipers=1, civ=1} }},
		{set_jump_flag="massive_deployment"},
	},
	desc = [[[b]Cylon Swarm[/b]

1) Activate Basestars
2) Combat Setup
Fore (9 o'clock): 1 Basestar, 5 Raiders
Starboard-Bow (11 o'clock): 1 Heavy Raider
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Viper, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Massive Deployment
Keep this card in play until the fleet jumps. Each time a Basestar launches raiders of heavy raiders, it launches 1 additional ship of the same type.]],
},
{
	id = 30,
	name = "Network Computers",
	activate = "raider",
	jump = true,
	choice = "current",
	a = {check = {val=11, pol=true, tac=true, eng=true, pass={jump_prep=1}, fail={pop=-1, centurion=1}, }},
	b = {pop=-1, jump_prep=-1},
	desc = [[[b]Network Computers[/b]

Current Player must choose:
A) Skill Check [11] [color=yellow]Politics[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Increase the Jump Preparation track by 1.
Fail: -1 Population and place 1 centurion marker at the start of the Boarding Party track.
[b]OR[/b]
B) -1 population and decrease the Jump Preparation track by 1.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 31,
	name = "Water Shortage",
	activate = "basestar",
	jump = true,
	choice = "president",
	a = { food=-1 }, b = {card_draws={president=-2, current=-3}},
	desc = [[[b]Water Shortage[/b]

President must choose:
A) -1 Food
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},
{
	id = 32,
	name = "Rescue Mission",
	activate = "raider",
	jump = true,
	choice = "admiral",
	a = { morale =-1, force_move={to="sickbay", who="current"}},
	b = {fuel=-1, raptor=-1},
	desc = [[[b]Rescue Mission[/b]

Admiral must choose:
A) -1 Morale, and the current player is sent to "Sickbay".
[b]OR[/b]
B) -1 Fuel and destroy 1 Raptor.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 33,
	name = "Surrounded",
	attack = {
		{activate="basestar"},
		{placement={saft={heavy=1, raider=3}, front={raider=4}, paft={vipers=1, civ=1}, rear={civ=1}, pbow={vipers=1, civ=1}, sbow={basestar=1} }},
		{card_draws={current=-3}}
	},
	desc = [[[b]Surrounded[/b]

1) Activate Basestars
2) Combat Setup
Fore (9 o'clock): 4 Raiders
Starboard-Bow (11 o’clock): 1 Basestar
Starboard-Quarter (1 o’clock): 3 Raiders, 1 Heavy Raider
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Viper, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Panic
The current player must discard 3 Skill Cards.]],
},
{
	id = 34,
	name = "Crash Landing",
	activate = "heavy",
	check = {val=6, tac=true, pil=true, fail = {	choice = "admiral", a = { fuel=-1}, b = { morale=-1, force_move={to="sickbay", who="current"} }	}},
	desc = [[[b]Crash Landing[/b]

Skill Check [6] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: No Effect.
Fail: The Admiral may spend 1 Fuel. If he does not, -1 Morale, and the current player is sent to "Sickbay".

[b]After Crisis[/b]: Activate Heavy Raiders]],
},
{
	id = 35,
	name = "Rescue Caprica Survivors",
	activate = "raider",
	jump = true,
	choice = "president",
	a = {fuel=-1, food=-1, pop=1},
	b = {morale=-1},
	desc = [[[b]Rescue Caprica Survivors[/b]

President must choose:
A) -1 Fuel, -1 Food, +1 Population.
[b]OR[/b]
B) -1 Morale.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 36,
	name = "Water Shortage",
	activate = "basestar",
	jump = true,
	choice = "president",
	a = { food=-1 }, b = {card_draws={president=-2, current=-3}},
	desc = [[[b]Water Shortage[/b]

President must choose:
A) -1 Food
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},
{
	id = 37,
	name = "Boarding Parties",
	attack = {
		{activate="heavy"},
		{placement={saft={heavy=2}, sbow={basestar=1, raider=4}, paft={civ=2}, rear={civ=1}, front={heavy=2} }},
	},
	desc = [[[b]Boarding Parties[/b]

1) Activate Heavy Raiders
2) Combat Setup
Fore (9 o'clock): 2 Heavy Raiders
Starboard-Bow (11 o'clock): 1 Basestar, 4 Raiders
Starboard-Quarter (1 o'clock): 2 Heavy Raiders
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 2 Civilian Ships
3) Special Rule - Surprise Assault
There are no vipers in this setup.]],
},
{
	id = 38,
	name = "Resistance",
	activate = "heavy",
	jump = true,
	check = {val=12, partialval=6, pol=true, tac=true, lea=true, partial={food=-1}, fail={food=-1, fuel=-1}},
	desc = [[[b]Resistance[/b]

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
6+: -1 Food.
Fail: -1 Food, -1 Fuel.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},
{
	id = 39,
	name = "Besieged",
	attack = {
		{activate="raider"},
		{placement={pbow={vipers=2, raider=4, civ=1}, sbow={civ=1}, paft={basestar=1}, rear={heavy=1}, front={civ=1} }},
		{func = function(state) fake_raider_activations("pbow", 4) end}
	},
	desc = [[[b]Besieged[/b]

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Civilian Ship
Starboard-Bow (11 o'clock): 1 Civilian Ship
Aft (3 o'clock): 1 Heavy Raider
Port-Quarter (5 o'clock): 1 Basestar
Port-Bow (7 o'clock): 4 Raiders, 2 Vipers, 1 Civilian Ship
3) Special Rule - Heavy Casualties
The 4 Raiders that were just setup are immediately activated.]],
},
{
	id = 40,
	name = "Water Shortage",
	activate = "basestar",
	jump = true,
	choice = "president",
	a = { food=-1 }, b = {card_draws={president=-2, current=-3}},
	desc = [[[b]Water Shortage[/b]

President must choose:
A) -1 Food
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},
{
	id = 41,
	name = "Fulfiller of Prophecy",
	activate = "basestar",
	choice = "current",
	a = {check = { val=6, pol=true, lea=true, pass={card_draws={current={pol=1}} }, fail={pop=-1} }},
	b = {card_draws={current=-1}, new_crisis=true},
	desc = [[[b]Fulfiller of Prophecy[/b]

Current Player must choose:
A) Skill Check [6] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: The current player draws 1 Politics card.
Fail: -1 Population.
[b]OR[/b]
B) The current player discards 1 Skill Card. After the Activate Cylon Ships step, return to the Resolve Crisis step (Draw a new Crisis Card and resolve it.)

[b]After Crisis[/b]: Activate Basestars]],
},{
	id = 42,
	name = "Cylon Screenings",
	activate = "raider",
	choice="current",
	a = {check={val=9, pol=true, lea=true, fail={morale=-1, look_at_loyalty = {chooser="current", qty=1, restriction={president=true, admiral=true}}	}	}},
	b = {card_draws={human=-2}},
	desc = [[[b]Cylon Screenings[/b]

Current Player must choose:
A) Skill Check [9] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: -1 morale, and the current player looks at 1 random Loyalty Card belonging to the President or Admiral.
[b]OR[/b]
B) Each player discards 2 Skill Cards.

[b]After Crisis[/b]: Activate Raiders]],
},{
	id = 43,
	name = "Terrorist Bomber",
	activate = "heavy",
	jump = true,
	check={val=9, lea=true,tac=true, fail={morale=-1, force_move={to="sickbay", who="current"} }},
	desc = [[[b]Terrorist Bomber[/b]

Skill Check [9] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Morale, and the current player is sent to sickbay.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},{
	id = 44,
	name = "Thirty-Three",
	attack = {
		panic = true,
	},
	desc = [[[b]Thirty-Three[/b]

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Battlestar
Starboard-Quarter (1 o’clock): 1 Civilian Ship
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Viper, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Relentless Pursuit
Keep this card in play until a Civilian Ship or Basestar is destroyed. If this card is in play when the fleet jumps, shuffle it back into the Crisis deck.]],
},
{
	id = 45,
	name = "Informing the Public",
	activate = "raider",
	jump = true,
	choice = "current",
	a = { check = { val = 7, lea=true, pol=true, fail={morale=-2}, pass = {look_at_loyalty = {chooser="current", qty=1}} }},
	b = { try = { roll = 5, fail={morale=-1, pop=-1}} },
	desc = [[[b]Informing the Public[/b]

Current Player must choose:
A) Skill Check [7] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: The current player looks at 1 random Loyalty Card belonging to any player.
Fail: -2 Morale.
[b]OR[/b]
B) Roll a die. On a 4 or lower, -1 morale and -1 population.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 46,
	name = "Sleep Deprivation",
	activate = "basestars",
	jump = true,
	choice = "admiral",
	a = {space_vipers="reserve", force_move={to="sickbay", who="current"}},
	b = {morale=-1},
	desc = [[[b]Sleep Deprivation[/b]

Admiral must choose:
A) Return all undamaged vipers on the game board to the "Reserves". Then send the current player to "Sickbay".
[b]OR[/b]
B) -1 Morale.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},
{
	id = 47,
	name = "Declate Martial Law",
	activate = "basestar",
	choice = "admiral",
	a = {morale=-1, force_title_change = {title="president", to="admiral"}},
	b = {pop=-1, card_draws={admiral=-2}},
	desc = [[[b]Declare Martial Law[/b]

Admiral must choose:
A) -1 Morale, and the Admiral receives the President title.
[b]OR[/b]
B) -1 Population, and the Admiral discards 2 Skill Cards.

[b]After Crisis[/b]: Activate Basestars]],
},
{
	id = 48,
	name = "Weapon Malfunction",
	activate = "launch raiders",
	check = { val = 11, tac=true,pil=true,eng=true, fail={ space_vipers=-2, force_move={from="weapons", to="sickbay", who="all"} }},
	desc = [[[b]Weapon Malfunction[/b]

Skill Check [10] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect.
Fail: Damage 2 vipers in space areas. All characters in the "Weapons Control" location are sent to "Sickbay".

[b]After Crisis[/b]: Launch Raiders]],
},
{
	id = 49,
	name = "Raiding Party",
	attack = {
		{activate="raider"},
		{placement = {	rear={heavy=2,raider=2}, pbow={civ=2,viper=2}, paft={civ=1}, saft={basestar=1,raider=3}	}},
		{jump_prep=-1},
	},
	desc = [[[b]Raiding Party[/b]

1) Activate Raiders
2) Combat Setup
Starboard-Quarter (1 o’clock): 1 Basestar, 3 Raiders
Aft (3 o'clock): 2 Heavy Raiders, 2 Raiders
Port-Quarter (5 o'clock): 1 Civilian Ship
Port-Bow (7 o'clock): 2 Vipers, 2 Civilian Ships
3) Special Rule - FTL Failure
Move the fleet token 1 space towards the start of the Jump Preparation track.]],
},
{
	id = 50,
	name = "Heavy Assault",
	attack = {
		{activate="raider"},
		{placement = {	front={basestar=1}, rear={civ=1}, pbow={civ=1,viper=1}, paft={civ=1}, sbow={basestar=1}	}},
		{activate="basestar"},
	},
	desc = [[[b]Heavy Assault[/b]

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Basestar
Starboard-Bow (11 o’clock): 1 Basestar
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Heavy Bombardment
Each Basestar immediately attacks Galactica.]],
},
{
	id = 51,
	name = "Ambush",
	attack = {
		{activate="basestar"},
		{placement = {	front={raider=4}, rear={basestar=1, raider=4}, pbow={civ=1}, paft={civ=1}, saft={civ=1}	}},
		{set_jump_flag="training_new_pilots"},
	},
	desc = [[[b]Ambush[/b]

1) Activate Basestars
2) Combat Setup
Fore (9 o'clock): 4 Raiders
Starboard-Quarter (1 o'clock): 1 Civilian Ship
Aft (3 o'clock): 1 Basestar, 4 Raiders
Port-Quarter (5 o'clock): 2 Vipers, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Civilian Ship
3) Special Rule - Training New Pilots
Keep this card in play until the fleet jumps. Each unmanned viper suffers a -2 penalty to its attack rolls.]],
},
{
	id = 52,
	name = "Rescue Mission",
	activate = "basestar",
	jump = true,
	choice = "admiral",
	a = {morale=-1, force_move={to="sickbay", who="current"}},
	b = {fuel=-1, raptor=-1},
	desc = [[[b]Rescue Mission[/b]

Admiral must choose:
A) -1 Morale, and the current player is sent to "Sickbay".
[b]OR[/b]
B) -1 Fuel and destroy 1 Raptor.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},
{
	id = 53,
	name = "Cylon Accusation",
	activate = "raider",
	check = {val=10, pol=true,lea=true,tac=true, fail={force_move={to="brig", who="current"}}},
	desc = [[[b]Cylon Accusation[/b]

Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: The current player is placed in the "Brig" location.

[b]After Crisis[/b]: Activate Raiders]],
},
{
	id = 54,
	name = "Unidentified Ship",
	activate = "launch raiders",
	check = {val=10, pil=true, tac=true, fail={pop=-1}},
	desc = [[[b]Unidentified Ship[/b]

Skill Check [10] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: No effect.
Fail: -1 Population.

[b]After Crisis[/b]: Launch Raiders]],
},{
	id = 55,
	name = "Colonial Day",
	activate = "basestar",
	jump = true,
	choice="current",
	a = { check = { val = 10, pol=true,tac=true, pass={morale=1}, fail={morale=-2}}}, b = {morale=-1},
	desc = [[[b]Colonial Day[/b]

Current Player must choose:
A) Skill Check [10] [color=yellow]Politics[/color] + [color=mediumorchid]Tactics[/color]
Pass: +1 Morale.
Fail: -2 Morale.
[b]OR[/b]
B) -1 Morale.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},{
	id = 56,
	name = "Food Shortage",
	activate = "raider",
	jump = true,
	choice="president",
	a = {food=-2},
	b = { food=-1, card_draws={president=-2, current=-3} },
	desc = [[[b]Food Shortage[/b]

President must choose:
A) -2 Food.
[b]OR[/b]
B) -1 Food. The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 57,
	name = "Rescue the Fleet",
	activate = "raider",
	jump = true,
	choice="admiral",
	a={pop=-2}, b = {morale=-1, place_basestar="front", place_civ={qty=3, at="rear"}},
	desc = [[[b]Rescue the Fleet[/b]

Admiral must choose:
A) -2 Population
[b]OR[/b]
B) -1 morale. Place 1 Basestar and 3 Raiders in front of Galactica and 3 Civilian Ships behind it.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 58,
	name = "Cylon Tracking Device",
	activate = "raider",
	check = { val=10, tac=true,eng=true,pil=true, fail = { raptor=-1, place_basestar="front", place_civ={qty=2, at="rear"} } },
	desc = [[[b]Cylon Tracking Device[/b]

Skill Check [10] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: Destroy 1 raptor and place a Basestar in front of Galactica and two civilian ships behind it.

[b]After Crisis[/b]: Activate Raiders]],
},
{
	id = 59,
	name = "Elections Loom",
	activate = "heavy",
	jump = true,
	check = { val=8, partialval=5, pol=true, lea=true, partial={morale=-1}, 
						fail={morale=-1, card_draws={president=-4}}	 },
	desc = [[[b]Elections Loom[/b]

Skill Check [8] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
5+: -1 Morale.
Fail: -1 Morale, and the President discards 4 Skill Cards.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},
{
	id = 60,
	name = "Hangar Accident",
	activate = "heavy",
	jump = true,
	check = { val=10, partialval=7, pil=true,eng=true,tac=true, partial={pop=-1}, 
						fail={pop=-1, vipers=-2}	 },
	desc = [[[b]Hangar Accident[/b]

Skill Check [10] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
7+: -1 Population.
Fail: -1 Population and damage 2 Vipers in the "Reserves".

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},
{
	id = 61,
	name = "Low Supplies",
	activate = "raider",
	check = {val=7, pol=true,lea=true, fail={morale = -1, try = { food = 6, fail = {morale = -1} }	}},
	desc = [[[b]Low Supplies[/b]

Skill Check [7] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect.
Fail: -1 Morale. If food is less than 6, -1 additional Morale.

[b]After Crisis[/b]: Activate Raiders]],
},
{
	id = 62,
	name = "Analyze Enemy Fighter",
	activate = "raider",
	jump = true,
	choice = "current",
	a = { check = { val = 7, tac=true, eng=true, fail={pop=-1}, pass={raptor=1} } },
	b = { try = { roll=5, fail = { pop=-1, card_draws={current=-2} } } },
	desc = [[[b]Analyze Enemy Fighter[/b]

Current Player must choose:
A) Skill Check [7] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Repair 1 destroyed Raptor.
Fail: -1 population.
[b]OR[/b]
B) Roll a die. If 4 or lower, -1 population and the current player discards 2 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 63,
	name = "Food Shortage",
	activate = "raider",
	jump = true,
	choice="president",
	a = {food=-2},
	b = { food=-1, card_draws={president=-2, current=-3} },
	desc = [[[b]Food Shortage[/b]

President must choose:
A) -2 Food.
[b]OR[/b]
B) -1 Food. The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},
{
	id = 64,
	name = "The Olympic Carrier",
	activate = "heavy",
	jump = true,
	check = {pol=true, lea=true, pil=true, val=11, partialval=8, partial={pop=-1}, fail={morale=-1, pop=-1}},
	desc = [[[b]The Olympic Carrier[/b]

Skill Check [11] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color]
Pass: No effect.
8+: -1 Population.
Fail: -1 Morale, -1 Population.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},{
	id = 65,
	name = "Food Shortage",
	activate = "raider",
	jump = true,
	choice="president",
	a = {food=-2},
	b = { food=-1, card_draws={president=-2, current=-3} },
	desc = [[[b]Food Shortage[/b]

President must choose:
A) -2 Food.
[b]OR[/b]
B) -1 Food. The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},{
	id = 66,
	name = "Riots",
	choice = "admiral",
	a = { food=-1, morale=-1 }, b = {pop = -1, fuel = -1},
	activate = "basestar",
	jump=true,
	desc = [[[b]Riots[/b]

Admiral must choose:
A) -1 Food, -1 Morale
[b]OR[/b]
B) -1 Population, -1 Fuel

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
},{
	id = 67,
	name = "Loss of a Friend",
	activate = "heavy",
	jump = true,
	check = { val=9, pol=true,lea=true, partialval=7, partial={card_draws={current=-2}}, fail={morale=-1, card_draws={current=-2}} },
	desc = [[[b]Loss of a Friend[/b]

Skill Check [9] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect.
7+: The current player discards 2 Skill Cards.
Fail: -1 Morale, and the current player discards 2 Skill Cards.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
},{
	id = 68,
	name = "Jammed Assault",
	attack = {
		{activate="raider"},
		{placement = {	front={civ=1}, rear={civ=1}, pbow={civ=1,viper=1}, paft={civ=1,viper=1}, sbow={raider=4}, saft={heavy=2,basestar=1}	}},
		{set_jump_flag="communications_disabled"},
	},
	desc = [[[b]Jammed Assault[/b]

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Civilian Ship
Starboard-Bow (11 o’clock): 4 Raiders
Starboard-Quarter (1 o’clock): 1 Basestar, 2 Heavy Raiders
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Viper, 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Communications Jamming
Keep this card in play until the fleet jumps. Players may not activate the "Communications" location.]],
},{
	id = 69,
	name = "Forced Water Mining",
	activate = "raider",
	jump = true,
	choice = "current",
	a = {check={val=17, pol=true,lea=true,tac=true,eng=true, pass={food=1}, fail={pop=-1, morale=-1}} },
	b = {food=1, morale=-1, random_discard={all=1}},
	desc = [[[b]Forced Water Mining[/b]

Current Player must choose:
A) Skill Check [17] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: +1 Food.
Fail: -1 Population, -1 Morale.
[b]OR[/b]
B) +1 Food, -1 Morale, and each player discards 1 random Skill Card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
},{
	id = 70,
	name = "Requested Resignation",
	activate = "basestar",
	choice = "admiral",
	a = {card_draws={president=-2, admiral=-2}},
	b = { choice = "president", a = {force_title_change = {title="president", to="admiral"}}, b = {force_move={to="brig", who="president"}} },
	desc = [[[b]Requested Resignation[/b]

Admiral must choose:
A) The President and Admiral both discard 2 Skill Cards.
[b]OR[/b]
B) The President may choose to give the President title to the Admiral, or move to the "Brig" location.

[b]After Crisis[/b]: Activate Basestars]],
},
}


pegasus_crisis_cards = {
	{ id = 71, name = "Assassination Plot",
		activate = "basestar", jump = true,
		choice = "admiral",
		a = {card_draws={current={qty=-3,tre=3}, admiral={qty=-3,tre=3} } },
		b = {execute="admiral"},
		desc = [[[b]Assassination Plot[/b] <Pegasus Expansion>

President must choose:
A) The Admiral and the current player must both discard 3 Skill Cards and draw 3 Treachery Cards.
[b]OR[/b]
B) The Admiral is executed.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
	{ id = 72, name = "The Black Market",
		activate = "raider", jump=true,
		choice = "current",
		
		a={check = {val=13, pol=true,lea=true,tac=true,pass={food=1},fail={food=-2,morale=-1},}},
		b={food=-1,
		sequence={
			{card_draws={all={qty=-1,}}},
			{card_draws={all={tre=1}}},
		}},
		desc = [[[b]The Black Market[/b] <Pegasus Expansion>

Current Player must choose:
A) Skill Check [13] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: +1 Food
Fail: -2 Food, -1 Morale
[b]OR[/b]
B) -1 Food and each player discards 1 Skill Card and draws 1 Treachery Card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 73, name = "Civilian Ship Nuked",
		activate = "raiders",
		jump=true,
		choice="president",
		a = {civ=-1, card_draws_to_tre={all=1}},
		b = {civ=-2},
		desc = [[[b]Civilian Ship Nuked[/b] <Pegasus Expansion>

President must choose:
A) Draw 1 Civilian Ship and destroy it. Then each player discards 1 Skill Cards and draws 1 Treachery Card.
[b]OR[/b]
B) Draw 2 Civilian Ships and destroy them.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 74, name = "Code Blue",
		activate = "heavy",
		jump = true,
		choice = "current",
		a = {check = {val=13,pol=true,lea=true,tac=true,
			fail={morale = -1, force_move={who="current", to="brig"}}},
			pass={look_at_loyalty = {chooser="current", qty=1}},
		},
		b = { card_draws_to_tre={all=2} },
		desc = [[[b]Code Blue[/b] <Pegasus Expansion>

Current Player must choose:
A) Skill Check [13] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: The current player looks at 1 random Loyalty Card of any player.
Fail: -1 Morale and the current player is sent to the “Brig.”
[b]OR[/b]
B) Each player discards 2 Skill Cards and draws 2 Treachery Cards.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 75, name = "Defending a Prisoner",
		activate = "heavy", jump=true,
		check = {val=11, pol=true,lea=true,
			fail = {morale = -1, try = { roll = 5, fail = { execute="current" }}}
		},
		desc = [[[b]Defending a Prisoner[/b] <Pegasus Expansion>

Skill Check [11] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect
Fail: -1 Morale and roll a die. If 4 or lower, the current player is executed.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 76, name = "Dogfight",
		attack = {},
		desc = [[[b]Dogfight[/b] <Pegasus Expansion>

1) Activate Raiders
2) Combat Setup
Starboard-Quarter (1 o’clock): 1 Basestar, 2 Raiders
Aft (3 o’clock): 2 Raiders
Port-Quarter (5 o’clock): 1 Viper
Port-Bow (7 o’clock): 1 Viper, 1 Civilian Ship
3) Special Rule – Constant Barrage
Keep this card in play until the fleet jumps or no Raiders remain on the board. Each time Raiders are activated, launch two Raiders from each Basestar (do not activate these new Raiders).]],
	},
	{ id = 77, name = "Food Hoarding in the Fleet",
		activate = "raiders", jump=true,
		choice = "president",
		a = {morale=-1, try={roll=4,fail={civ=-1}}},
		b = {food=-2},
		desc = [[[b]Food Hoarding in the Fleet[/b] <Pegasus Expansion>

President must choose:
A) -1 Morale and roll a die. If 3 or less, draw 1 Civilian Ship and destroy it.
[b]OR[/b]
B) -2 Food

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 78, name = "The Guardians",
		attack = {},
		desc = [[[b]The Guardians[/b] <Pegasus Expansion>

1) Activate Basestars
2) Combat Setup
Fore (9 o’clock): 1 Basestar
Starboard-Bow (11 o’clock): 2 Raiders
Starboard-Quarter (1 o'clock): 1 Heavy Raider
Aft (3 o'clock): 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Viper
Port-Bow (7 o'clock): 2 Raiders, 1 Viper
3) Special Rule – Raptor Crew Captured
Keep this card in play until the fleet jumps. When a Basestar is destroyed, lose 1 Morale and destroy 1 Raptor.]],
	},
	{ id = 79, name = "Medical Breakthrough",
		activate = "heavy",
		check = {val=12,pol=true,lea=true, eng=true, partialval=6,
			pass={ card_draws={human=1} },
			fail={morale = -1, card_draws_to_tre={all=1} },
		},
		desc = [[[b]Medical Breakthrough[/b] <Pegasus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=dodgerblue]Engineering[/color]
Pass: Each human player draws 1 Skill Card.
6+: No effect
Fail: -1 Morale and each player discards 1 Skill Card and draws 1 Treachery Card.

[b]After Crisis[/b]: Activate Heavy Raiders]],
	},
	{ id = 80, name = "An Offer of Peace",
		activate = "launch",
		check={val=12, pol=true,lea=true,partialval=6,
			partial = {tre_to_destiny=2},
			fail = {morale=-1, tre_to_destiny=2},
		},
		desc = [[[b]An Offer of Peace[/b] <Pegasus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect
6+: Shuffle 2 Treachery Cards into the Destiny deck.
Fail: -1 Morale and shuffle 2 Treachery Cards into the Destiny deck.

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 81, name = "Pressure the Supply Ships",
		activate = "raiders", jump=true,
		choice="admiral",
		a={food=1,morale=-1,card_draws={admiral={qty=-2,tre=2}}},
		b={food=-2},
		desc = [[[b]Pressure the Supply Ships[/b] <Pegasus Expansion>

Admiral must choose:
A) +1 Food and -1 Morale. The Admiral discards 2 Skill Cards and draws 2 Treachery Cards.
[b]OR[/b]
B) -2 Food

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 82, name = "Reunite the Fleet",
		activate = "raiders",
		choice="current",
		a={check={val=10,pol=true,lea=true,
			pass={pop=1},
			fail={morale=-1,card_draws_to_tre={all=1}}
		}},
		b={card_draws={all={qty=-2,tre=2}}},
		desc = [[[b]Reunite the Fleet[/b] <Pegasus Expansion>

Current Player must choose:
A) Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: +1 Population
Fail: -1 Morale and each player discards 1 Skill Card and draws 1 Treachery Card.
[b]OR[/b]
B) The current player discards 2 random Skill Cards and draws 2 Treachery Cards.

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 83, name = "Review Galactica's Log",
		activate = "raiders", jump=true,
		check={val=14,pol=true,lea=true,tac=true,
				partialval=6,partial={card_draws={admiral=-3}},
				fail={morale=-1,card_draws={admiral=-5}}
		},
		desc = [[[b]Review Galactica's Log[/b] <Pegasus Expansion>

Skill Check [14] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
6+: The Admiral must discard 3 Skill Cards.
Fail: -1 Morale and the Admiral must discard 5 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 84, name = "Sabotage Investigated",
		activate = "heavy", jump=true,
		check={val=9, tac=true,eng=true, pass={food=-1}, fail={morale=-1,fuel=-1,food=-1},},
		desc = [[[b]Sabotage Investigated[/b] <Pegasus Expansion>

Skill Check [9] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: -1 Food
Fail: -1 Morale, -1 Fuel, -1 Food

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 85, name = "Scar",
		attack = {},
		desc = [[[b]Scar[/b] <Pegasus Expansion>

1) Activate Raiders
2) Combat Setup
Starboard-Bow (11 o’clock): Scar
Aft (3 o’clock): 2 Civilian Ships
Port-Quarter (5 o’clock): 1 Viper
Port-Bow (7 o’clock): 1 Viper
3) Special Rule - Personal Vendetta
Keep this card in play until the fleet jumps or Scar is destroyed. Whenever raiders are activated, activate the Scar raider twice. Scar may only be destroyed by a roll of 7 or 8.]],
	},
	{ id = 86, name = "Standoff with Pegasus",
		activate = "launch",
		check={val=22,pol=true,lea=true,tac=true,pil=true,
			pass={todo=true},
			fail={pop=-1,morale=-1,space_vipers=-1},
		},
		desc = [[[b]Standoff with Pegasus[/b] <Pegasus Expansion>

Skill Check [22] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: The current player may move 1 character from the “Brig” to any other location.
Fail: -1 Population, -1 Morale, and damage 1 Viper in a space area (if able).

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 87, name = "Suspicious Election Results",
		activate = "raiders",
		choice = "admiral",
		a = {force_title_change={title="president", abdicate=true}},
		b = {card_draws_to_tre={admiral=1}},
		desc = [[[b]Suspicious Election Results[/b] <Pegasus Expansion>

Admiral must choose:
A) Give the President title to the character (aside from the current President) highest in the line of succession.
[b]OR[/b]
B) The Admiral discards 1 random Skill Card and draws 1 Treachery Card.

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 88, name = "Training Snafu",
		activate = "basestars", jump=true,
		check = {val=8, lea=true, pil=true,
			fail = {damage_vipers=3},
		},
		desc = [[[b]Training Snafu[/b] <Pegasus Expansion>

Skill Check [8] [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color]
Pass: No effect
Fail: Damage 3 Vipers in space areas or in the “Reserves.”

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
	{ id = 89, name = "Unsettling Stories",
		activate = "raiders",jump=true,
		choice = "current",
		a = {
			check = {val=9, pol=true, lea=true,
				fail={morale=-1,card_draws_to_tre={all=1}},
			},
		},
		b = {morale=-1},
		desc = [[[b]Unsettling Stories[/b] <Pegasus Expansion>

Current Player must choose:
A) Skill Check [9] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect
Fail: -1 Morale, and each player discards 1 Skill Card and draws 1 Treachery Card.
[b]OR[/b]
B) -1 Morale

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 90, name = "A Verdict of Guilty",
		activate = "basestars",jump=true,
		choice = "admiral",
		a = {execute="current", card_draws={admiral=-3}},
		b = {damage=2},
		desc = [[[b]A Verdict of Guilty[/b] <Pegasus Expansion>

Admiral must choose:
A) The current player is executed and the Admiral discards 3 Skill Cards.
[b]OR[/b]
B) Damage Galactica twice.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
}

exodus_crisis_cards = {
	{ id = 91, name = "Airlock Leak",
		activate = "heavy",
		check = {val=6,tac=true,eng=true, fail={damage=1, force_move={to="sickbay", who="current"} } },
		desc = [[[b]Airlock Leak[/b]

Skill Check [6] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect
Fail: Damage Galactica and the current player is sent to "Sickbay".

[b]After Crisis[/b]: Activate Heavy Raiders
]],
	},
	{ id = 92, name = "Ambushed by the Press",
		activate = "raiders",
		jump = true,
		choice = "president",
		a = {morale=-1},
		b = {random_discard={president=99}},
		desc = [[[b]Ambushed by the Press[/b]

President must choose:
A) -1 morale
[b]OR[/b]
B) The President must discard all of his Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 93, name = "Appoint Head of Security",
		activate = "launch",
		choice = "admiral",
		a = {space_vipers = "reserve", random_discard={admiral=2}},
		b = {morale = -1, damage = 1},
		desc = [[[b]Appoint Head of Security[/b]

Admiral must choose:
A) Return all undamaged vipers on the game board to the "Reserves". Then the Admiral must discard 2 random Skill Cards.
[b]OR[/b]
B) -1 morale and damage Galactica once.

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 94, name = "Centurion Assault",
		activate = "launch",
		check={val=9,tac=true,pil=true,
			fail={raptors=-1,force_move={who="current", to="sickbay"}}},
		desc = [[[b]Centurion Assault[/b] <Exodus Expansion>

Skill Check [9] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: No Effect.
Fail: Destroy 1 raptor and the current player is sent to "Sickbay".

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 95, name = "The Circle",
		activate = "raiders",jump=true,
		choice = "president",
		a = {
			choice = "president",
			a = {force_title_change={title="president", chooser="president"}},
			b = {execute = "current"},
		},
		b = {card_draws={president=-2,current=-3}},
		desc = [[[b]The Circle[/b] <Exodus Expansion>

President must choose:
A) You must choose another player to receive the President title or the current player is executed.
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 96, name = "Consult the Prisoner",
		activate = "basestars",jump=true,
		choice = "current",
		a={check={val=13, pol=true,tac=true,eng=true,
			pass={jump_prep=1},
			fail={card_draws={all=-1},force_move={who="current", to="brig"}}
		}},
		b={card_draws={admiral=-2,current=-3}},
		desc = [[[b]Consult the Prisoner[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [13] [color=yellow]Politics[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Increase the Jump Preparation track by 1.
Fail: Each player discards 1 Skill Card and the current player is sent to the "Brig".
[b]OR[/b]
B) The Admiral discards 2 Skill Cards and the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
	{ id = 97, name = "Controversial Manuscript",
		activate = "raiders",jump=true,
		choice = "president",
		a = {morale = -1}, b = {morale=1, damage=2},
		desc = [[[b]Controversial Manuscript[/b] <Exodus Expansion>

President must choose:
A) -1 morale
[b]OR[/b]
B) +1 morale and damage Galactica twice

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 98, name = "Cylon Genocide",
		activate = "raiders",jump=true,
		choice = "current",
		a = {check={val=21,pol=true,lea=true,tac=true,eng=true,
			pass = {cylon_genocide=true,},
			fail = {morale=-1, activate = {"basestar", "launch", "heavy"}}
		}},
		b = {try={roll=5, fail={force_move={who="current",to="brig"}}}},
		desc = [[[b]Cylon Genocide[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [21] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Destroy all Cylon ships currently on the main game board.
Fail: -1 morale, then Activate Basestars, Launch Raiders, Activate Heavy Raiders
[b]OR[/b]
B) Roll a die. If 4 or lower, the current player is sent to the "Brig".

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 99, name = "Détente",
		activate = "launch",
		choice = "cag",
		a = {pursuit=1, land_all_vipers=true},
		b = {activate={"basestar","raiders","heavy"}},
		desc = [[[b]Détente[/b] <Exodus Expansion>

CAG must choose:
A) All vipers in space areas are returned to the "Reserves". All characters who were piloting vipers are placed in the "Hangar Deck". Increase the Pursuit track by 1.
[b]OR[/b]
B) Activate Basestars, Activate Raiders, Activate Heavy Raiders

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 100, name = "Divisive Behavior",
		activate = "heavy",jump=true,
		check={val=10,pol=true,lea=true,tac=true,fail={morale=-1},
			consequence={force_move={chooser="current", to="sickbay"}}
		},
		desc = [[[b]Divisive Behavior[/b] <Exodus Expansion>

Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 morale.
Consequence: The current player chooses another player to send to "Sickbay".

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 101, name = "Familiar Face",
		activate = "raiders",jump=true,
		choice = "current",
		a = {check = {val=12,pol=true,lea=true,tac=true,
			pass = {choice_force_move = {chooser="admiral", to="brig"}},
			fail = {morale=-1, card_draws={admiral=-99}},
		}},
		b = {morale=-1},
		desc = [[[b]Familiar Face[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: The Admiral may choose a character to send to the "Brig".
Fail: -1 morale and the Admiral must discard all of his Skill Cards.
[b]OR[/b]
B) -1 morale

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 102, name = "Guilty Conscience",
		activate = "heavy",jump=true,
		check = {val=7,pol=true,lea=true,fail={random_discard={current=3}}},
		desc = [[[b]Guilty Conscience[/b] <Exodus Expansion>

Skill Check [7] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: The current player discards 3 random Skill Cards.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 103, name = "Haunted by the Past",
		activate = "heavy",jump=true,
		check={val=12,pol=true,lea=true,fail={card_draws={all=-1,random=true}},
			consequence={self_abdicate=true},
		},
		desc = [[[b]Haunted by the Past[/b] <Exodus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: Each player must discard 1 random Skill Card.
Consequence: The current player gives any Title Cards he has to the player (aside from himself) highest on the Line of Succession.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 104, name = "Hera Rescued",
		activate = "raider",jump=true,
		choice="current",
		a ={
			check={val=10,pol=true,lea=true,
				fail = {morale=-2,raptor=-1}
			},
		},
		b={morale=-1},
		desc = [[[b]Hera Rescued[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [10] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No Effect.
Fail: -2 morale and destroy 1 raptor.
[b]OR[/b]
B) -1 morale

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 105, name = "Hidden Explosives",
		activate = "raiders",jump=true,
		choice = "admiral",
		a = {raptor=-1, force_move={who="admiral", to="sickbay"} },
		b={morale=-1},
		desc = [[[b]Hidden Explosives[/b] <Exodus Expansion>

Admiral must choose:
A) Destroy 1 raptor and the current player is sent to "Sickbay".
[b]OR[/b]
B) -1 morale

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 106, name = "Hidden Identity",
		activate = "launch",
		check={val=12, pol=true,lea=true,tac=true,fail={morale=-1,force_move={who="current", to="brig"}}},
		desc = [[[b]Hidden Identity[/b] <Exodus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No Effect.
Failure: -1 morale. Current player is sent to the "Brig".

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 107, name = "In the Ring",
		activate = "heavy",jump=true,
		check={val=12,pol=true,lea=true,tac=true,pass={morale=1},fail={morale=-1,force_move={who="current", to="sickbay"}}},
		consequence={choice_force_move={chooser="current",to="sickbay",forced=true,not_self=true}},
		desc = [[[b]In the Ring[/b] <Exodus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: +1 morale
Fail: -1 morale and the current player is sent to "Sickbay".
Consequence: The current player chooses another player to send to "Sickbay".

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 108, name = "Interrogation",
		activate = "basestar",
		choice="admiral",
		a={choose_player={forced=true,not_self=true, move="sickbay",look_at_loyalty={qty=1}} },
		b={card_draws={admiral=-2,current=-3}},
		desc = [[[b]Interrogation[/b] <Exodus Expansion>

Admiral must choose:
A) The Admiral chooses another player to send to "Sickbay". The Admiral may then look at 1 of that character's Loyalty Cards at random.
[b]OR[/b]
B) The Admiral discards 2 Skill Cards; then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars]],
	},
	{ id = 109, name = "Joe's Bar",
		activate = "raiders",jump=true,
		check={val=12,pol=true,lea=true,eng=true,pass={morale=1},fail={morale=-1,force_move={who="current",to="brig"}}},
		desc = [[[b]Joe's Bar[/b] <Exodus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=dodgerblue]Engineering[/color]
Pass: +1 morale
Fail: -1 morale and the current player is sent to the "Brig".

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 110, name = "Labor Dispute",
		activate = "basestar",
		choice="president",
		a={morale=-2},
		b={fuel=-1,jump_prep=-1},
		desc = [[[b]Labor Dispute[/b] <Exodus Expansion>

President must choose:
A) -2 morale
[b]OR[/b]
B) -1 fuel and decrease the Jump Preparation track by 1.

[b]After Crisis[/b]: Activate Basestars]],
	},
	{ id = 111, name = "Medal of Distinction",
		activate = "basestar",jump=true,
		choice="admiral",
		a={morale=1,sequence={{place_civ=2},{activate="raiders"}}},
		b={morale=-1},
		desc = [[[b]Medal of Distinction[/b] <Exodus Expansion>

Admiral must choose:
A) +1 morale, place 2 civilian ships on the game board, and then Activate Raiders
[b]OR[/b]
B) -1 morale

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
	{ id = 112, name = "Mysterious Guide",
		activate = "raiders",
		choice="current",
		a={check={val=11,pol=true,lea=true,pass={jump_prep=1},fail={fuel=-1,card_draws={current=-99}} }},
		b={morale=-1},
		desc = [[[b]Mysterious Guide[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [11] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: Increase the Jump Preparation track by 1.
Fail: -1 fuel and the current player discards all of his Skill Cards.
[b]OR[/b]
B) -1 morale

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 113, name = "Mysterious Message",
		activate = "basestar",
		choice="current",
		a={check={val=9,pol=true,eng=true,pass={mysterious_message_effect=true},fail={activate={"launch","basestar"}}}},
		b={activate="basestar"},
		desc = [[[b]Mysterious Message[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [9] [color=yellow]Politics[/color] + [color=dodgerblue]Engineering[/color]
Pass: The current player may search the Destiny deck and choose 2 cards to discard. He then reshuffles the Destiny deck.
Fail: Launch Raiders, Activate Basestars
[b]OR[/b]
B) Activate Basestars

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 114, name = "The Passage",
		activate = "raider",jump=true,
		choice="current",
		a={check={val=14,tac=true,pil=true,eng=true,
			pass={jump_prep=1},fail={civ=-2},
		}},
		b={try={roll=7,fail={force_move={who="current",to="sickbay"}} }},
		desc = [[[b]The Passage[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [14] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: Increase the Jump Preparation track by 1.
Fail: Destroy 2 civilian ships.
[b]OR[/b]
B) Roll a die. If 6 or lower, the current player is sent to "Sickbay".

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 115, name = "Power Failure",
		activate = "heavy",
		check={val=14, lea=true, tac=true, eng=true, fail={jump_prep=-1}},
		consequence={damage=1},
		desc = [[[b]Power Failure[/b] <Exodus Expansion>

Skill Check [14] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: Reduce the Jump Preparation track by 1.
Consequence: Damage Galactica once.

[b]After Crisis[/b]: Activate Heavy Raiders]],
	},
	{ id = 116, name = "Raiders Inbound",
		activate = "heavy",
		choice="cag",
		a={pop=-1,damage=1},
		b={card_draws={cag=-2,admiral=-2}},
		desc = [[[b]Raiders Inbound[/b] <Exodus Expansion>

CAG must choose:
A) -1 population and damage Galactica once
[b]OR[/b]
B) The CAG and the Admiral must each discard 3 Skill Cards.

[b]After Crisis[/b]: Activate Heavy Raiders]],
	},
	{ id = 117, name = "Raptor Malfunction",
		activate = "raider",jump=true,
		choice="current",
		a={check={val=14, tac=true,pil=true,eng=true, fail={damage=1,raptor=-1}}},
		b={force_move={who="current",to="sickbay"}},
		desc = [[[b]Raptor Malfunction[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [12] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: Damage Galactica once and destroy 1 raptor.
[b]OR[/b]
B) The current player is sent to "Sickbay".

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 118, name = "Return to Duty",
		activate = "raider",
		choice="cag",
		a={sequence={{return_to_duty_effect=true},{activate="raider"}}},
		b={activate="basestar"},
		desc = [[[b]Return to Duty[/b] <Exodus Expansion>

CAG must choose:
A) Any character on Galactica with piloting in his skill set may immediately launch himself in a viper. Then Launch Raiders.
[b]OR[/b]
B) Activate Basestars

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 119, name = "Review Camera Footage",
		activate = "basestar",
		choice="cag",
		a={sequence={{vipers=-2}, {pursuit=1},{unmanned_activations=1}}},
		b={card_draws={cag=-2,current=-3}},
		desc = [[[b]Review Camera Footage[/b] <Exodus Expansion>

CAG must choose:
A) Damage 2 vipers in the "Reserves" (if able) and increase the Pursuit track by 1. The CAG may then activate 1 unmanned viper.
[b]OR[/b]
B) The CAG discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars]],
	},
	{ id = 120, name = "Set a Trap",
		activate = "raider",
		choice="current",
		a={check={val=10,lea=true,tac=true,pass={centurion=-1},fail={centurion=1,force_move={who="current",to="sickbay"}}}},
		b={try={roll=5,fail={centurion=1}}},
		desc = [[[b]Set a Trap[/b] <Exodus Expansion>

Current Player must choose:
A) Skill Check [10] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: Destroy a centurion on the Boarding Party track.
Fail: Place a centurion at the start of the Boarding Party track. The current player is sent to "Sickbay".
[b]OR[/b]
B) Roll a die. If 4 or lower, place a centurion at the start of the Boarding Party track.

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 121, name = "Strange Beacon",
		activate = "raider",
		check={val=13,tac=true,pil=true,eng=true,fail={jump_prep=-1},pass={strange_beacon_effect=true}},
		desc = [[[b]Strange Beacon[/b] <Exodus Expansion>

Skill Check [13] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: Choose 1 space area on the main game board and remove all Cylon ships in that area.
Fail: Decrease the Jump preparation track by 1.

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 122, name = "Temple of the Five",
		activate = "launch",
		check={val=9,tac=true,eng=true, pass={card_draws={current=2}},fail={jump_prep=-1}},
		desc = [[[b]Temple of the Five[/b] <Exodus Expansion>

Skill Check [9] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: The current player may draw 2 Skill Cards.
Fail: Decrease the Jump Preparation track by 1.

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 123, name = "Threat of Super Nova",
		activate = "heavy",jump=true,
		check={val=10,lea=true,pil=true,eng=true, fail={pop=-1,damage=1}},
		consequence={activate="basestar"},
		desc = [[[b]Threat of Super Nova[/b] <Exodus Expansion>

Skill Check [10] [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No Effect.
Fail: -1 population and damage Galactica.
Consequence: Activate Basestars

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation]],
	},
	{ id = 124, name = "Tracked by Radiation",
		activate = "basestar",
		choice="cag",
		a={place_basestar="front",place_raiders={qty=3,at="front"},place_civ={qty=2, at="rear"}},
		b={fuel=-1},
		desc = [[[b]Tracked by Radiation[/b] <Exodus Expansion>

CAG must choose:
A) Place a basestar and 3 raiders in front of Galactica and 2 civilian ships behind Galactica.
[b]OR[/b]
B) -1 fuel.

[b]After Crisis[/b]: Activate Basestars]],
	},
	{ id = 125, name = "Training a Rookie",
		activate = "launch",
		choice="cag",
		a={sequence={{unmanned_activation={who="cag",qty=1}},{activate="raider"}}},
		b={damage_any_vipers=2},
		desc = [[[b]Training a Rookie[/b] <Exodus Expansion>

CAG must choose:
A) Activate one unmanned viper. Then Activate Raiders.
[b]OR[/b]
B) The CAG chooses 2 vipers that are not currently damaged or destroyed and moves them to the "Damaged Viper" box.

[b]After Crisis[/b]: Launch Raiders]],
	},
	{ id = 126, name = "Truth and Reconciliation",
		activate = "basestar",jump=true,
		choice="president",
		a={morale=-1, choice_force_move = {chooser="president", forced = true, to="brig"}},
		b={card_draws={president=-2,current=-3}},
		desc = [[[b]Truth and Reconciliation[/b] <Exodus Expansion>

President must choose:
A) -1 morale and the President must choose a character to send to the "Brig".
[b]OR[/b]
B) The President discards 2 Skill Cards, then the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation]],
	},
	{ id = 127, name = "Unexplained Deaths",
		activate = "raider",jump=true,
		check={val=8,lea=true,tac=true,fail={morale=-1,pop=-1}},
		desc = [[[b]Unexplained Deaths[/b] <Exodus Expansion>

Skill Check [8] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No Effect.
Fail: -1 morale, -1 population.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 128, name = "Unfair Bias",
		activate = "raider",jump=true,
		check ={val=12,pol=true,lea=true,tac=true,fail={damage=1,card_draws={current=-99}}},
		desc = [[[b]Unfair Bias[/b] <Exodus Expansion>

Skill Check [12] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No Effect.
Fail: Damage Galactica and the current player discards his hand of Skill Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 129, name = "Unwelcome Faces",
		activate = "raider",jump=true,
		choice="admiral",
		a={card_draws={admiral=-99}, choice_force_move = {chooser="admiral", forced = true, to="brig"}},
		b={morale=-1,damage=1},
		desc = [[[b]Unwelcome Faces[/b] <Exodus Expansion>

Admiral must choose:
A) The Admiral must discard all of his Skill Cards and then choose a character to send to the "Brig".
[b]OR[/b]
B) -1 morale and damage Galactica once.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
	{ id = 130, name = "Widespread Starvation",
		activate = "raider",jump=true,
		choice="president",
		a={food=-2},
		b={food=-1,pop=-1},
		desc = [[[b]Widespread Starvation[/b] <Exodus Expansion>

President must choose:
A) -2 food
[b]OR[/b]
B) -1 food, -1 population

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation]],
	},
}

daybreak_crisis_cards = {
	{ id = 131, name = "Abandon Galactica",
		activate = "basestar", jump=true,
		choice = "admiral",
		a = {nukes=-1},
		b = {food=-1,draw_cards={admiral={tre=2}}},
		desc = [[[b]Abandon Galactica[/b] <Daybreak Expansion>

Admiral must choose:
A) Discard 1 nuke token. If you do not have any nuke tokens, you cannot choose this option.
[b]OR[/b]
B) -1 food, and the Admiral draws 2 Treachery Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation
]],
	},
	{ id = 132, name = "An Ambitious Operation",
		activate = "raiders", jump=true,
		choice = "admiral",
		a = {fuel=-1, grant_miracle={who="choice",chooser="admiral"}},
		b = {try={roll=5, fail={fuel=-1}}},
		desc = [[[b]An Ambitious Operation[/b] <Daybreak Expansion>

Admiral must choose:
A) -1 Fuel. The Admiral chooses another player to gain 1 miracle token.
[b]OR[/b]
B) Roll a die. On a 4 or less, -1 fuel.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 133, name = "Blindsided",
		attack = {panic=true},
		desc = [[[b]Blindsided[/b] <Daybreak Expansion>

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 1 Basestar, 1 Heavy Raider
Starboard-Bow (11 o'clock): 3 Raiders
Aft (3 o'clock): 1 Basestar, 1 Heavy Raider
Port-Quarter (5 o'clock): 1 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 2 Civilian Ships
3) Special Rule - Pluck Out Their Eyes
Destroy 1 Raptor.
]],
	},
	{ id = 134, name = "Consult the Hybrid",
		activate = "heavy", jump=true,
		check = {
			val = 10, pol=true,lea=true,
			pass = {card_draws={current={any=2}}, draw_mutiny="current"},
			fail={food=-1, tre_to_destiny=2},
		},
		desc = [[[b]Consult the Hybrid[/b] <Daybreak Expansion>

Skill Check [10] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: The current player draws a Mutiny Card and 2 Skill Cards (they may be from outside his skill set).
Fail: -1 food, and shuffle 2 Treachery Cards into the Destiny deck.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation
]],
	},
	{ id = 135, name = "Dangerous Plots",
		activate = "basestar", jump=true,
		choice = "president",
		a = {sequence={{draw_mutiny="admiral"},{draw_mutiny="president"}}},
		b={morale=-1, card_draws={current=-3}},
		desc = [[[b]Dangerous Plots[/b] <Daybreak Expansion>

President must choose:
A) The Admiral and President both draw 1 Mutiny Card.
[b]OR[/b]
B) -1 morale, and the current player discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation
]],
	},
	{ id = 136, name = "A Desperate Pact",
		activate = "raiders",
		choice = "current",
		a = {
			check={val=15,pol=true,lea=true,pil=true,
				fail={morale=-1,force_title_change={title="president", abdicate=true}}
			},
		},
		b = {sequence = {{card_draws={president=-3}},{draw_mutiny="current"}}},
		desc = [[[b]A Desperate Pact[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [15] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color]
Pass: No effect.
Fail: -1 morale, and give the President title to the player (aside from the current President) highest on the Presidential line of succession.
[b]OR[/b]
B) The President discards 3 Skill Cards, then the current player draws 1 Mutiny Card.

[b]After Crisis[/b]: Activate Raiders]],
	},
	{ id = 137, name = "Dishonest Tactics",
		activate = "raider", jump=true,
		choice = "president",
		a = {morale=-1, choice_force_move = {chooser="president", from="brig", to="command", forced = false}},
		b = {fuel=-1, draw_quorum=2},
		desc = [[[b]Dishonest Tactics[/b] <Daybreak Expansion>

President must choose:
A) -1 morale, and the President may choose 1 player to move from the "Brig" to "Command."
[b]OR[/b]
B) -1 fuel, and the President draws 2 Quorum Cards.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 138, name = "Domestic Dispute",
		activate = "raider",
		check={val=9,pol=true,tac=true,
			fail={morale=-1, force_move={to="Sickbay", who="current"}}
		},
		desc = [[[b]Domestic Dispute[/b] <Daybreak Expansion>

Skill Check [9] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 morale, and the current player is sent to "Sickbay."

[b]After Crisis[/b]: Activate Raiders.
]],
	},
	{ id = 139, name = "Earth in Ruins",
		activate = "raider", jump=true,
		choice="current",
		a = {check = {val=9,pol=true,lea=true,tac=true,pass={morale=-1},fail={morale=-2}}},
		b = {food=-1, draw_mutiny="current"},
		desc = [[[b]Earth in Ruins[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [9] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: -1 morale.
Fail: -2 morale.
[b]OR[/b]
B) -1 food, and the current player draws 1 Mutiny Card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 140, name = "Enemy of my Enemy",
		activate = "raider",jump=true,
		choice="current",
		a={
			check = {val=13,pol=true,lea=true,pil=true,
			pass={morale=-1},fail={morale=-2,damage=1}}
		},
		b={damage=2},
		desc = [[[b]Enemy of my Enemy[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [13] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color]
Pass: -1 morale
Fail: -2 morale, and damage Galactica
[b]OR[/b]
B) Damage Galactica twice.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 141, name = "Event Horizon",
		attack = {},
		desc = [[[b]Event Horizon[/b] <Daybreak Expansion>

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 2 Raiders, 1 Viper
Starboard-Bow (11 o'clock): 1 Basestar
Aft (3 o'clock): 1 Basestar, 2 Raiders
Port-Quarter (5 o'clock): 1 Viper
Port-Bow (7 o'clock): 1 Viper
3) Special Rule - Gravity Well
Keep this card in play until the fleet jumps. No player can activate a viper unless he first discards a Skill Card.
]],
	},
	{ id = 142, name = "Galactica Falling Apart",
		activate = "raider", jump=true,
		choice="current",
		a = { check ={val=8,lea=true,pil=true,eng=true,fail={morale=-1,damage=1}}
		},
		b={try={roll=7,fail={food=-1}}},
		desc = [[[b]Galactica Falling Apart[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [8] [color=limegreen]Leadership[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect
Fail: -1 morale, and damage Galactica
[b]OR[/b]
B) Roll a die. On a 6 or lower, -1 food.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 143, name = "Give in to Despair",
		activate = "heavy",jump=true,
		check={val=14,pol=true,lea=true,partialval=9,fail={morale=-2},partial={food=-1,card_draws={current={tre=3}}}},
		desc = [[[b]Give in to Despair[/b] <Daybreak Expansion>

Skill Check [14] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: No effect
9+: -1 food, and the current player draws 3 Treachery Cards.
Fail: -2 morale

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation
]],
	},
	{ id = 144, name = "Hornet’s Nest",
		attack = {},
		desc = [[[b]Hornet’s Nest[/b] <Daybreak Expansion>

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 3 Raiders, 1 Viper, 1 Civilian Ship
Starboard-Quarter (1 o'clock): 1 Basestar
Aft (3 o'clock): 3 Raiders
Port-Quarter (5 o'clock): 1 Viper
Port-Bow (7 o'clock): 2 Civilian Ships
3) Special Rule - Suppressive Fire
Keep this card in play until the fleet jumps or a basestar is destroyed. Players cannot use actions on Piloting Cards.
]],
	},
	{ id = 145, name = "Hybrid in Panic",
		activate = "heavy",jump=true,
		check={val=12,tac=true,eng=true,
			pass={jump_prep=1},
			partialval=6, partial={card_draws={current=-2}},
			fail={fuel=-1}
		},
		desc = [[[b]Hybrid in Panic[/b] <Daybreak Expansion>

Skill Check [12] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: Increase the Jump Preparation track by 1.
8+: The current player discards 2 Skill Cards.
Fail: -1 fuel.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation
]],
	},
	{ id = 146, name = "Incitement to Mutiny",
		activate = "heavy",jump=true,
		check={val=13,pol=true,lea=true,tac=true,partialval=7,
			partial = {tre_to_destiny=2},
			fail = {tre_to_destiny=4},
		},
		desc = [[[b]Incitement to Mutiny[/b] <Daybreak Expansion>

Skill Check [13] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
7+: Shuffle 2 Treachery Cards into the Destiny deck.
Fail: Shuffle 4 Treachery Cards into the Destiny deck.

[b]After Crisis[/b]: Activate Heavy Raiders, Advance Jump Preparation
]],
	},
	{ id = 147, name = "Insubordinate Crew",
		activate = "raider",
		check={val=12,lea=true,tac=true,fail={morale=-1,insubordinate_effect=true}},
		desc = [[[b]Insubordinate Crew[/b] <Daybreak Expansion>

Skill Check [12] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
Fail: -1 morale, and each player that does not have a Mutiny Card draws 1 Mutiny Card.

[b]After Crisis[/b]: Activate Raiders
]],
	},
	{ id = 148, name = "Lockdown",
		attack = {},
		desc = [[[b]Lockdown[/b] <Daybreak Expansion>

1) Activate Heavy Raiders
2) Combat Setup
Fore (9 o'clock): 2 Heavy Raiders
Starboard-Bow (11 o'clock): 1 Basestar, 2 Heavy Raiders
Aft (3 o'clock): 1 Viper, 1 Civilian Ship
Port-Quarter (5 o'clock): 1 Civilian Ship
3) Special Rule - Concerted Attack
Keep this card in play until the fleet jumps or a basestar is destroyed. Players cannot activate the "Armory" location.
]],
	},
	{ id = 149, name = "One Last Cocktail",
		activate = "basestar",jump=true,
		choice="current",
		a={check={val=7,tac=true,eng=true,fail={food=-1,morale=-1}},},
		b={try={roll=7, fail={morale=-1, force_move={to="Sickbay", who="president"}}}},
		desc = [[[b]One Last Cocktail[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [7] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect.
Fail: -1 food, -1 morale.
[b]OR[/b]
B) Roll a die. On a 6 or lower, -1 morale and the President is sent to "Sickbay."

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation
]],
	},
	{ id = 150, name = "Question Procedure",
		activate = "basestar",jump=true,
		choice="president",
		a={morale=-1},
		b={damage=1, card_draws={president=-3}},
		desc = [[[b]Question Procedure[/b] <Daybreak Expansion>

President must choose:
A) -1 morale
[b]OR[/b]
B) Damage Galactica, and the President discards 3 Skill Cards.

[b]After Crisis[/b]: Activate Basestars, Advance Jump Preparation
]],
	},
	{ id = 151, name = "Quorum in Uproar",
		activate = "raider",
		check={val=8,pol=true,tac=true,fail={random_discard={president=2,quorum=2}}},
		desc = [[[b]Quorum in Uproar[/b] <Daybreak Expansion>

Skill Check [8] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
Fail: The President discards 2 random Quorum Cards and 2 random Skill Cards.

[b]After Crisis[/b]: Launch Raiders
]],
	},
	{ id = 152, name = "Rallying Support",
		activate = "raider",jump=true,
		check={val=8,pol=true,tac=true,fail={pop=-1,draw_mutiny="current",card_draws={current={tre=1}}}},
		desc = [[[b]Rallying Support[/b] <Daybreak Expansion>

Skill Check [8] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
Fail: -1 population, and the current player draws 1 Mutiny Card and 1 Treachery Card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 154, name = "Reactor Critical",
		activate = "raider",
		check={val=7,tac=true,pil=true,eng=true,fail={fuel=-1},pass={card_draws={current={tre=2}}}},
		desc = [[[b]Reactor Critical[/b] <Daybreak Expansion>

Skill Check [7] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: The current player draws 2 Treachery Cards
Fail: -1 fuel

[b]After Crisis[/b]: Launch Raiders
]],
	},
	{ id = 155, name = "Rebuild Trust",
		activate = "raider",
		check={val=9,pol=true,lea=true,fail={morale=-2},pass={jailbreak_effect=true}},
		desc = [[[b]Rebuild Trust[/b] <Daybreak Expansion>

Skill Check [9] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: Each character in the "Brig" may move to any location on Galactica
Fail: -2 morale

[b]After Crisis[/b]: Activate Raiders
]],
	},
	{ id = 156, name = "Religious Turmoil",
		activate = "raider",jump=true,
		choice="current",
		a = {check={val=7,pol=true,tac=true,fail={morale=-1, card_draws={all=-1}}
			},
		},
		b = {try={roll=5,fail={food=-1,pop=-1}}},
		desc = [[[b]Religious Turmoil[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [7] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect
Fail: -1 morale, and each player discards 1 Skill Card.
[b]OR[/b]
B) Roll a die. On a 4 or lower, -1 food and -1 population.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 157, name = "Reprisal",
		attack={},
		desc = [[[b]Reprisal[/b] <Daybreak Expansion>

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 2 Raiders, 1 Civilian Ship
Starboard-Bow (11 o'clock): 1 Viper
Starboard-Quarter (1 o'clock): 1 Viper
Aft (3 o'clock): 3 Raiders, 1 Heavy Raider
Port-Quarter (5 o'clock): 1 Civilian Ship
Port-Bow (7 o'clock): 1 Basestar
3) Special Rule - Opportunity for Treason
Shuffle 2 Treachery Cards into the Destiny deck. Then, the current player draws a Mutiny Card.
]],
	},
	{ id = 158, name = "Requisition for Demetrius",
		activate = "basestar",
		choice="admiral",
		a = {food=-1, try={roll=7,fail={tre_to_destiny=2}}},
		b = {sequence={{draw_cards={admiral={tre=2}}},{draw_mutiny="admiral"}}},
		desc = [[[b]Requisition for Demetrius[/b] <Daybreak Expansion>

Admiral must choose:
A) -1 food, then roll a die. On a 6 or lower, shuffle 2 Treachery Cards into the Destiny deck.
[b]OR[/b]
B) The Admiral draws 1 Mutiny Card and 2 Treachery Cards.

[b]After Crisis[/b]: Activate Basestars
]],
	},
	{ id = 159, name = "Secret Meetings",
		activate = "raider",jump=true,
		choice="current",
		a={check={val=9,pol=true,tac=true,eng=true,fail={morale=-1}
		}},
		b={sequence={{draw_mutiny="current"},{draw_mutiny={who="choice", chooser="current"}}}},
		desc = [[[b]Secret Meetings[/b] <Daybreak Expansion>

Current player must choose:
A) Skill Check [9] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect
Fail: -1 morale
[b]OR[/b]
B) The current player draws 1 Mutiny card. Then, he chooses a player to draw 1 Mutiny card.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 153, name = "Starvation in Dogsville",
		activate = "raider",jump=true,
		choice="president",
		a={try={roll=5, fail={pop=-1,food=-1}}},
		b={try={roll=5, fail={food=-2}}},
		desc = [[[b]Starvation in Dogsville[/b] <Daybreak Expansion>

President must choose:
A) Roll a die. On a 4 or less, -1 population and -1 food.
[b]OR[/b]
B) Roll a die. On a 4 or less, -2 food.

[b]After Crisis[/b]: Activate Raiders, Advance Jump Preparation
]],
	},
	{ id = 160, name = "Trial by Fire",
		attack = {},
		desc = [[[b]Trial by Fire[/b] <Daybreak Expansion>

1) Activate Raiders
2) Combat Setup
Fore (9 o'clock): 3 Raiders, 2 Heavy Raiders
Starboard-Bow (11 o'clock): 1 Viper
Aft (3 o'clock): 1 Basestar
Port-Bow (7 o'clock): 1 Civilian Ship
3) Special Rule - Cavalry's Here
The human fleet gains an assault raptor. The current player places it in a space area with a viper launch icon and may immediately activate it.
]],
	},
}

base_supercrisis = {
{
	name = "Fleet Mobilization",
	supercrisis=true,
	check = { val=24, lea=true, tac=true, pil=true, eng=true, pass = { activate={"basestar", "launch raiders"} }, fail = {activate={"basestar", "raider", "heavy", "launch raiders"}, morale=-1} },
	desc = [[[b][color=crimson]Fleet Mobilization[/color][/b]

Skill Check [24] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: Activate Basestars, Launch Raiders.
Fail: -1 Morale and Activate Basestars, Activate Raiders, Activate Heavy Raiders, Launch Raiders.]],
},
{
	name = "Inbound Nukes",
	supercrisis=true,
	check = { val=15, lea=true, tac=true, fail = {fuel=-1,pop=-1,food=-1} },
	desc = [[[b][color=crimson]Inbound Nukes[/color][/b]

Skill Check [15] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: -1 Fuel, -1 Food, and -1 Population.]],
},
{
	name = "Massive Assault",
	supercrisis=true,
	attack = {
		{activate={"heavy", "basestar"}},
		{placement = {	pbow={civ=2,viper=1}, paft={civ=2,viper=1}, sbow={raider=4,basestar=1}, saft={heavy=1,basestar=1,raider=2}	}},
		{jump = -2},
	},
	desc = [[[b][color=crimson]Massive Assault[/color][/b]

1) Activate Heavy Raiders, Activate Basestars
2) Combat Setup
Starboard-Bow (11 o’clock): 1 Basestar, 4 Raiders
Starboard-Quarter (1 o’clock): 1 Basestar, 2 Raiders, 1 Heavy Raider
Port-Quarter (5 o'clock): 1 Viper, 2 Civilian Ship
Port-Bow (7 o'clock): 1 Viper, 2 Civilian Ship
3) Special Rule - Power Failure
Move the fleet token 2 spaces towards at the start of the Jump Preparation track.]],
},
{
	name = "Bomb on Colonial One",
	supercrisis=true,
	check = { val=15, tac=true,pil=true,eng=true, fail = {morale=-2, destroy_locations={pressroom=true, presidentsoffice=true, administration=true}}},
	desc = [[[b][color=crimson]Bomb on Colonial One[/color][/b]

Skill Check [15] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect.
Fail: -2 Morale, and all characters on Colonial One are sent to "Sickbay". Keep this card in play. Characters may not move to Colonial One for the rest of the game.]],
},
{
	name = "Cylon Intruders",
	supercrisis=true,
	check = { val=18, tac=true, lea=true, partialval=14, partial={centurion=1}, fail={damage=1, centurion=2} },
	desc = [[[b][color=crimson]Cylon Intruders[/color][/b]

Skill Check [18] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
14+: Place 1 centurion marker at the start of the Boarding Party track.
Fail: Damage Galactica and place 2 centurion markers at the start of the Boarding Party track.]],
},
}

pegasus_supercrisis = {
	{
	name = '"Demand Peace" Manifesto',
	choice = "admiral",
	a={morale=-1, damage=2},
	b={random_discard={president=99,admiral=99}},
	desc = [[[b][color=crimson]Demand Peace” Manifesto[/color][/b] <Pegasus Expansion>

Admiral must choose:
A) -1 Morale and damage Galactica twice.
[b]OR[/b]
B) The President and the Admiral must each discard their hand of Skill Cards.]],
	},
	{
	name = "The Farm",
	desc = [[[b][color=crimson]The Farm[/color][/b] <Pegasus Expansion>

Skill Check [15] [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: No effect
8+: -1 Food
Fail: -1 Food, -1 Population. Keep this card in play. Human players may not use their once-per-game abilities.]],
	},
	{
	name = "Footage Transmitted",
	desc = [[[b][color=crimson]Footage Transmitted[/color][/b] <Pegasus Expansion>

Skill Check [17] [color=yellow]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: Each player draws 1 Treachery Card.
12+: Each revealed Cylon player draws 2 Treachery Cards.
Fail: Each revealed Cylon player draws 2 Treachery Cards and 1 Super Crisis Card.]],
	},
	{
	name = "Lured into a Trap",
	desc = [[[b][color=crimson]Lured into a Trap[/color][/b] <Pegasus Expansion>

1) Activate Raiders
2) Combat Setup
Starboard-Bow (11 o’clock): 1 Basestar, 3 Raiders
Starboard-Quarter (1 o’clock): 1 Basestar, 3 Raiders
Aft (3 o’clock): 1 Heavy Raider
Port-Quarter (5 o’clock): 1 Viper, 1 Civilian Ship
Port-Bow (7 o’clock): 1 Viper, 1 Civilian Ship
3) Special Rule - Dangerous Repairs are Necessary
Keep this card in play until the fleet jumps. Any character in either the “Engine Room” or “FTL Control” locations when the fleet jumps is executed.]],
	},
	{
	name = "Psychological Warfare",
	desc = [[[b]Psychological Warfare[/b] <Pegasus Expansion>

President must choose:
A) -1 Morale, each player discards 2 Skill Cards and draws 2 Treachery Cards.
[b]OR[/b]
B) Each revealed Cylon player draws 2 Treachery Cards. Then, discard the entire Destiny deck and build a new one consisting of only 6 Treachery Cards.]],
	},
}

exodus_supercrisis = {
	{
	name = "Fighting Blind",
	desc = [[[b][color=crimson]Fighting Blind[/color][/b] <Exodus Expansion>

CAG must choose:
A) Place 2 centurions at the start of the Boarding Party track.
[b]OR[/b]
B) The CAG is executed.]],
	},
	{
	name = "Fire All Missiles",
	desc = [[[b][color=crimson]Fire All Missiles[/color][/b] <Exodus Expansion>

Skill Check [22] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: No effect.
Fail: Draw 2 civilian ships to destroy.
Consequence: Damage Galactica twice.]],
	},
	{
	name = "Human Prisoner",
	desc = [[[b][color=crimson]Human Prisoner[/color][/b] <Exodus Expansion>

Skill Check [18] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: No effect.
Fail: The Cylon player who played this card chooses one human player and takes all of his Skill Cards. That human player’s character is then sent to "Sickbay".]],
	},
}

base_quorum = {
{
	qty = 4,
	name = "Inspirational Speech",
	action = { try = { roll=6, pass={morale=1, trash_card=true} } },desc=[[[b]Inspirational Speech[/b]

[b]Action[/b]: Roll a die. If 6 or higher, gain 1 Morale and remove this card from the game. Otherwise, no effect and discard this card.]]
},
{
	qty = 2,
	name = "Arrest Order",
	action = { choice_force_move = {chooser="acting", to="brig"} },desc=[[[b]Arrest Order[/b]

[b]Action[/b]: Choose a character and send him to the "Brig" location. Then discard this card.]]
},
{
	qty = 2,
	name = "Authorization of Brutal Force",
	action = { sequence={ {aobf_effect=true}, { try={roll=3, fail={pop=-1}} } } },desc=[[[b]Authorization of Brutal Force[/b]

[b]Action[/b]: Destroy 3 Raiders, 1 Heavy Raider, or 1 Centurion. Then roll a die, and if 2 or less, lose 1 Population. Then discard this card.]]
},
{
	name = "Encourage Mutiny",
	action = {
		choose_player = {
			filter = {"!active", "!admiral"}, effect = {
				try = { roller="chosen", roll=3, pass={force_title_change = {title="admiral", to="chosen"}}, fail={morale=-1} }
			}
		}
	}
	,desc=[[[b]Encourage Mutiny[/b]

[b]Action[/b]: Choose any other player (excluding the Admiral). That player rolls a die. If 3 or higher, he receives the Admiral title; otherwise, lose 1 Morale. Then discard this card.]]
},{
	qty = 2,
	name = "Food Rationing",
	action = { try = { roll=6, pass={food=1, trash_card=true} } },desc=[[[b]Food Rationing[/b]

[b]Action[/b]: Roll a die. If 6 or higher, gain 1 Food and remove this card from the game. Otherwise, no effect and discard this card.]]
},{
	name = "Release Cylon Mugshots",desc=[[[b]Release Cylon Mugshots[/b]

[b]Action[/b]: Look at 1 random Loyalty Card belonging to any other player, then roll a die. If 3 or less, lose 1 Morale. Then discard this card.
]],
	action = { try = { roll=4, fail={morale=-1}}, look_at_loyalty = {chooser="acting", qty=1} }
},{
	name = "Presidential Pardon",
	action = { pardon_effect = true },desc=[[[b]Presidential Pardon[/b]

[b]Action[/b]: Move any other character from the "Brig" to any other location on Galactica.]]
},
{
	name = "Assign Mission Specialist",
	action = { quorum_assign = "mission_specialist" },desc=[[[b]Assign Mission Specialist[/b]

[b]Action[/b]: Draw 2 Politics cards and give this card to any other player.

Keep this card in play. The next time the fleet jumps, this player chooses the destination instead of the Admiral. He draws 3 Destination Cards (instead of 2) and chooses 1. Then discard this card.]]
},
{
	name = "Assign Vice President",
	action = { quorum_assign = "vice_president" },desc=[[[b]Assign Vice President[/b]

[b]Action[/b]: Draw 2 Politics cards and give this card to any other player.

Keep this card in play. While this player is not President, other players may not be chosen with the "Administration" location.]]
},
{
	name = "Accept Prophecy",
	action = { quorum_assign = "prophet", card_draws={chooser={any=1}} },desc=[[[b]Accept Prophecy[/b]

[b]Action[/b]: Draw 1 Skill Card of any type (it may be drawn from outside your skill set).

Keep this card in play. When a player activates "Administration" or chooses the President with the "Admiral’s Quarters" location, increase the difficulty by 2, then discard this card.]]
},
{
	name = "Assign Arbitrator",
	action = { quorum_assign = "arbitrator" },desc=[[[b]Assign Arbitrator[/b]

[b]Action[/b]: Draw 2 Politics cards and give this card to any other player.

Keep this card in play. When a player activates the "Admiral’s Quarters" location, this player may discard this card to reduce or increase the difficulty by 3.]]
},
}

pegasus_quorum = {
	{name="Assign Chief of Staff", action = { quorum_assign = "chief_of_staff", card_draws={acting={pol=2}} },desc=[[[b]Assign Chief of Staff[/b] <Pegasus Expansion>

[b]Action[/b]: Draw 2 Politics cards and give this card to any other player.

Keep this card in play. Before cards are added to a Skill check, this player may discard this card to make all Politics cards in the Skill check count as positive strength.]] },
	{name="Civilian Self Defense",action={ civ_self_defense_effect = true },desc=[[[b]Civilian Self Defense[/b] <Pegasus Expansion>

[b]Action[/b]: Choose 1 Civilian Ship. Destroy either 3 Raiders or 1 Heavy Raider in the same space area as that ship. Then roll a die. If the result is 2 or less, the Civilian Ship is destroyed. Then discard this card.]]},
	{name="Consult the Oracle", action={ consult_oracle_effect = true},desc=[[[b]Consult the Oracle[/b] <Pegasus Expansion>

[b]Action[/b]: Look at the bottom card of any 1 deck. Then look at all cards in the Destiny deck and discard 2 of them. Then shuffle the Destiny deck and discard this card.]]},
	{name="Enact Production Quotas", action={morale=-1, food=1},desc=[[[b]Enact Production Quotas[/b] <Pegasus Expansion>

[b]Action[/b]: Gain 1 Food and lose 1 Morale. Then discard this card.]]},
	{name="Eulogy", action={ try={execution_lost_morale=true, pass={morale=1}} },desc=[[[b]Eulogy[/b] <Pegasus Expansion>

[b]Action[/b]: If at least 1 Morale has been lost by a character being executed, gain 1 Morale. Then discard this card.]]},
	{name="Execute Prisoner", action={ choose_player={filter="loc:Brig", effect={execute="chosen"}}}
		,desc=[[[b]Execute Prisoner[/b] <Pegasus Expansion>

[b]Action[/b]: Chose a character in the “Brig.” The character is executed. Then discard this card.]]},
	{name="Probation", action={quorum_assign="probated"},desc=[[[b]Probation[/b] <Pegasus Expansion>

[b]Action[/b]: Give this card to any player. After he plays cards into a Skill check, you may discard this card to look at the cards he played.]]},
	{name="Resources for Galactica", action={ repair={location=1,viper=2} },desc=[[[b]Resources for Galactica[/b] <Pegasus Expansion>

[b]Action[/b]: Repair up to 1 location and 2 damaged Vipers. Then discard this card.]]},
	{name="Unsavory Connections",desc=[[[b]Unsavory Connections[/b] <Pegasus Expansion>

[b]Action[/b]: Discard 2 random Skill Cards and draw 2 Treachery Cards. Then gain either 1 Food or 1 Fuel and discard this card.]],action={ sequence={{random_discard={active=2}},{card_draws={active={tre=2}}},{choice="acting",a={food=1},b={fuel=1}}} }},
}

exodus_quorum = {
	{name="Establish Dogsville",action={pop=1,morale=-1},desc=[[[b]Establish Dogsville[/b] <Exodus Expansion>

[b]Action[/b]: Gain 1 Population and lose 1 Morale. Then discard this card.]]},
	{name="Presidential Order",action={choose_player={effect={
		choice="acting",
		a={force_title_change={title="admiral", to="chosen"}},
		b={force_title_change={title="cag", to="chosen"}},
	}}},desc=[[[b]Presidential Order[/b] <Exodus Expansion>

[b]Action[/b]: Choose any player, give him either the Admiral title or the CAG title, and then discard this card.]]},
	{name="Resignation", action = {resignation_effect=true},desc=[[[b]Resignation[/b] <Exodus Expansion>

[b]Action[/b]: Discard any number of Quorum Cards from your hand and then draw an equal number of new Quorum Cards. Then choose another character, give him the President title, and discard this card.]]},
}



title_succession = {
	admiral = {
		'Helena Cain',
		'William Adama',
		'Saul Tigh',
		'Karl "Helo" Agathon',
		'Felix Gaeta',
		'Louis Hoshi',
		'Tom Zarek (alt)',
		'Lee "Apollo" Adama',
		'Anastasia "Dee" Dualla',
		'Karl "Helo" Agathon (alt)',
		'Kara "Starbuck" Thrace',
		'Louanne "Kat" Katraine',
		'Sharon "Boomer" Valerii',
		'Brendan "Hot Dog" Costanza',
		'Samuel T. Anders',
		'"Chief" Galen Tyrol',
		'Callandra "Cally" Tyrol',
		'Sherman "Doc" Cottle',
		'Lee Adama (alt)',
		'Tom Zarek',
		'Ellen Tigh',
		'Gaius Baltar (alt)',
		'Gaius Baltar',
		'Romo Lampkin',
		'Tory Foster',
		'Laura Roslin',
	},
	president = {
		'Laura Roslin',
		'Gaius Baltar',
		'Lee "Apollo" Adama (alt)',
		'Tom Zarek',
		'Romo Lampkin',
		'Tory Foster',
		'Ellen Tigh',
		'Lee "Apollo" Adama',
		'Tom Zarek (alt)',
		'Felix Gaeta',
		'William Adama',
		'Karl "Helo" Agathon',
		'"Chief" Galen Tyrol',
		'Gaius Baltar (alt)',
		'Callandra "Cally" Tyrol',
		'Sherman "Doc" Cottle',
		'Helena Cain',
		'Anastasia "Dee" Dualla',
		'Louis Hoshi',
		'Karl "Helo" Agathon (alt)',
		'Sharon "Boomer" Valerii',
		'Saul Tigh',
		'Brendan "Hot Dog" Costanza',
		'Samuel T. Anders',
		'Kara "Starbuck" Thrace',
		'Louanne "Kat" Katraine',
	},
	cag = {
		'Lee "Apollo" Adama',
		'Kara "Starbuck" Thrace',
		'Louanne "Kat" Katraine',
		'Karl "Helo" Agathon (alt)',
		'Sharon "Boomer" Valerii',
		'Brendan "Hot Dog" Costanza',
		'Samuel T. Anders',
		'Lee "Apollo" Adama (alt)',
		'Karl "Helo" Agathon',
		'William Adama',
		'Helena Cain',
		'Saul Tigh',
		'Felix Gaeta',
		'Anastasia "Dee" Dualla',
		'Louis Hoshi',
		'Tom Zarek (alt)',
		'"Chief" Galen Tyrol',
		'Callandra "Cally" Tyrol',
		'Sherman "Doc" Cottle',
		'Tom Zarek',
		'Ellen Tigh',
		'Gaius Baltar (alt)',
		'Gaius Baltar',
		'Tory Foster',
		'Romo Lampkin',
		'Laura Roslin',
	}
}



characters = {
	{
		name = "William Adama",
		alias = {'adama'},
		start = "Admiral's Quarters",
		type = "mil",
		draw = { lea=3, tac=2 },
		cant_activate = "Admiral's Quarters"
	},
	{
		name = "Saul Tigh",
		alias = {'tigh'},
		start = "Command",
		type = "mil",
		draw = { tac=3, lea=2 },
		opg = {
			action = { force_title_change = {title="president", to="admiral"} }
		},
	},
	{
		name = 'Karl "Helo" Agathon',
		alias = {'helo'},
		start = "Hangar Deck",
		type = "mil",
		draw = { lea=2, tac=2, pil=1 },
	},
	{
		name = 'Helena Cain',
		alias = {'cain'},
		start = {"Pegasus CIC", "Command"},
		type = "mil",
		draw = { lea=2, tac=2, flex={lea=true,tac=true,qty=1} },
		opg = {
			action = { blind_jump = true }
		},
		cant_activate = {"Engine Room", "FTL Control"},
	},
	{
		name = 'Felix Gaeta',
		alias = {'felix','gaeta'},
		start = "FTL Control",
		type = "mil",
		draw = { tac=2,eng=1,flex={lea=true,pol=true,qty=2} },
	},
	{
		name = "Louis Hoshi",
		alias = {'hoshi'},
		start = "Communications",
		type = "mil",
		draw = {lea=2, tac=2, eng=1},
	},
	{
		name = 'Laura Roslin',
		alias = {'roslin'},
		start = "President's Office",
		type = "pol",
		draw = { pol=3,lea=2 },
	},
	{
		name = 'Gaius Baltar',
		alias = {'baltar'},
		start = "Research Lab",
		type = "pol",
		draw = { pol=2,lea=1,eng=1 },
	},
	{
		name = 'Tom Zarek',
		alias = {'zarek'},
		start = "Administration",
		type = "pol",
		draw = { pol=2,lea=2,tac=1, },
	},
	{
		name = 'Ellen Tigh',
		alias = {'ellen'},
		start = "Admiral's Quarters",
		type = "pol",
		draw = { pol=2,lea=2,tre=1 },
	},
	{
		name = 'Tory Foster',
		alias = {'tory'},
		start = "Press Room",
		type = "pol",
		draw = { pol=3,lea=1,tac=1 },
	},
	{
		name = "Romo Lampkin",
		alias = {'romo', 'lampkin'},
		start = "Administration",
		type = "pol",
		draw = { pol=3, tac=2}
	},
	{
		name = 'Lee "Apollo" Adama',
		alias = {'lee', 'apollo'},
		start = "viper",
		type = "pil",
		draw = { tac=1,pil=2,flex={lea=true,pol=true,qty=2}, },
		opg = { action = { unmanned_activation=6 }},
	},
	{
		name = 'Lee "Apollo" Adama',
		alt = true,
		start = "Admiral's Quarters",
		draw = {tac=1, pil=2, flex = {pol=true,lea=true, qty=2}}
	},
	{
		name = 'Kara "Starbuck" Thrace',
		alias = {'kara', 'starbuck'},
		start = "Hangar Deck",
		type = "pil",
		draw = { tac=2,pil=2,flex={lea=true,eng=true,qty=1} },
	},
	{
		name = 'Sharon "Boomer" Valerii',
		alias = {'boomer'},
		start = "Armory",
		type = "pil",
		draw = { tac=2,pil=2,eng=1 },
	},
	{
		name = 'Louanne "Kat" Katraine',
		alias = {'kat'},
		start = "Hangar Deck",
		type = "pil",
		draw = { pil=2,tac=2,lea=1 },
	},
	{
		name = 'Samuel T. Anders',
		alias = {'anders'},
		start = "Armory",
		type = "pil",
		draw = { lea=2,tac=2,flex={tac=true,pil=true,qty=1} },
	},
	{
		name = 'Brendan "Hot Dog" Costanza',
		alias = {'hotdog'},
		start = "Hangar Deck",
		type = "pil",
		draw = {lea=1, pil=2, tac=1, eng=1},
	},
	{
		name = '"Chief" Galen Tyrol',
		alias = {'chief', 'tyrol'},
		start = "Hangar Deck",
		type = "sup",
		draw = { lea=2, pol=1,eng=2},
		hand_limit = 8,
	},
	{
		name = 'Anastasia "Dee" Dualla',
		alias = {'dee','dualla'},
		start = "Communications",
		type = "sup",
		draw = { lea=1,tac=3,eng=1 },
		exec = function (state, player)
			if state.state == "end_turn" and state.morale <= 2 then
				-- executed
				state:execute(player, true)
			end
		end,
	},
	{
		name = 'Callandra "Cally" Tyrol',
		alias = {'cally'},
		start = "Hangar Deck",
		type = "sup",
		draw = { lea=1,pol=1,tac=1,eng=2 },
		opg = {
			action = {
				execute_in_location = true
			},
		},
	},
	{
		name = 'Sherman "Doc" Cottle',
		alias = {'doc','cottle'},
		start = "Research Lab",
		type = "sup",
		draw = { tac=2, pol=1, eng=2}
	},
	{
		name = 'Cavil',
		start = "Cylon Fleet",
		type = "cylon",
		draw = { tac=1,flex={tre=true,eng=true,qty=1}},
	},
	{
		name = 'Leoben Conoy',
		alias = {"leoben"},
		start = "Human Fleet",
		type = "cylon",
		draw = { pol=1, flex={tre=true,eng=true,qty=1} },
		movement = { glimpse_effect = true, }
	},
	{
		name = '"Caprica" Six',
		alias = {"caprica", "six", "caprica six"},
		start = "Caprica",
		type = "cylon",
		draw = { lea=1, flex={tre=true,eng=true,qty=1} },
		movement = { choose_player = {why="six ability", effect={six_effect=true}} },
	},
	{
		name = "D'Anna Biers",
		alias = {"d'anna"},
		start = "Human Fleet",
		type = "cylon",
		draw = {flex = {pol=true, lea=true, tre=true, eng=true, qty=2} }
	},



	{
		name = 'Gaius Baltar (alt)',
		alias = {'cultar'},
		start = "Admiral's Quarters",
		type = "sup",
		draw = {pol=2,lea=2,eng=1},
	},
	{
		name = 'Lee "Apollo" Adama (alt)',
		alias = {'pol apollo', 'pol lee'},
		start = "Admiral's Quarters",
		type = "pol",
		draw = {tac=1,pil=2,flex={lea=true,pol=true,qty=2}},
	},
	{
		name = "Romo Lampkin",
		alias = {'romo'},
		start = 'Administration',
		type = 'pol',
		draw = {tac=2,pol=3},
	},
	{
		name = "Louis Hoshi",
		alias = {'hoshi'},
		start = "Communications",
		type = "mil",
		draw = {lea=2,tac=2,eng=1},
		opg = {action={hoshi_opg = true}}
	},
	{
		name = "Tom Zarek (alt)",
		alias = {'rebel zarek'},
		start = "Weapons Control",
		type = "mil",
		draw = {pol=2,lea=2,tac=1},
	},
	{
		name = 'Brendan "Hot Dog" Costanza',
		alias = {'hot dog'},
		start = "Hangar Deck",
		type = "pil",
		draw = {lea=1,tac=1,pil=2,eng=1},
	},
	{
		name = 'Karl "Helo" Agathon',
		alias = {'pil helo'},
		start = "Admiral's Quarters",
		type = "pil",
		draw = {lea=2,tac=2,pil=1},
	},
	{
		name = 'Sherman "Doc" Cottle',
		alias = {'cottle','doc'},
		start = "Admiral's Quarters",
		type = "sup",
		draw = {pol=2,lea=2,eng=1},
	},
	{
		name = "D'Anna Biers",
		alias = {'danna'},
		start = "Human Fleet",
		type = "cylon",
		draw = {},
	},
	{
		name = "Simon O'Neill",
		alias = {'simon'},
		start = "Cylon Fleet",
		type = "cylon",
		draw = {eng=1,flex={tre=true,tac=true,qty=1}},
	},
	{
		name = "Aaron Doral",
		alias = {'aaron'},
		start = "Caprica",
		type = "cylon",
		draw = {tre=1,flex={pol=true,tac=true,qty=1}},
	},
	{
		name = 'Sharon "Athena" Agathon',
		alias = {'athena'},
		start = "Hangar Deck",
		type = "cylon",
		draw = {pil=1,flex={lea=true, eng=true, qty=1}},
	},
}

local function make_notify(name)
	return '@"' .. name .. '"'
end

player_funcs = {}
player_funcs.__index = player_funcs

function load_player(s, t)
	for k,v in pairs(s.players) do
		if v.name == t.name then return v end
	end
	error("Unknown player " .. t.name)
end
function player_funcs:savefunc()
	return string.format('{name=%q, loadfunc="load_player"}', self.name)
end
function player_funcs:internal_name()
	return self.name .. ' / ' .. self.player
end
function player_funcs:full_name(no_notify)
	local s = ''
	local state = self.state

	if state.admiral == self then
		s = s .. "a"
	end
	if state.president == self then
		s = s .. "p"
	end
	if state.cag == self then
		s = s .. 'c'
	end
	
	local title, list
	list = {
		p = "President ",
		a = "Admiral ",
		c = "CAG ",
		ap = "Emperor ",
		ac = "Grand Admiral ",
		pc = "El Presidente ",
		apc = "God Emperor ",
	}
	if list[s] then
		local t = list[s]
		if self.location and self.location.name == 'Brig' then
			t = t .. 'of the Brig '
		end
		title = '[b]'..t..'[/b]'
	else
		local lookup = {
			chief_of_staff = "Chief of Staff ",
		}
		for k,v in pairs(lookup) do
			if state[k] == self then
				title = v
			end
		end
		if title then title = '[b]' .. title .. '[/b]' end
	end

	return string.format('%s%s (%s)', title or '', self.name, ((no_notify or state.no_player_notifications) and self.player) or make_notify(self.player))
end
function player_funcs:can_fly()
	return ((self.draw.pil or (self.draw.flex and self.draw.flex.pil)) and true) or false
end

for k,v in pairs(characters) do
	setmetatable(v, player_funcs)
end


consolidate_power = {
	type = "pol",
	name = "Consolidate Power",
	module = "base",
	action = { card_draws = { unrestricted=true, current = {any=2, } } }
}
investigative_committee = {
	type = "pol",
	name = "Investigative Committee",
	module = "base",
}
support_the_people = {
	type = "pol",
	name = "Support the People",
	module = "pegasus",
	reckless = true,
}
preventative_policy = {
	type = "pol",
	name = "Preventative Policy",
	module = "pegasus",
	movement = { preventative_policy=true }
}
red_tape = {
	type = "pol",
	name = "Red Tape",
	module = "exodus",
	precount_func = function (state, check, flags)
		flags.red_tape = true
	end,
	skill_check = true,
}
political_prowess = {
	type = "pol",
	name = "Political Prowess",
	module = "exodus",
}
force_hand={
	type="pol",
	name="Force Their Hand",
	module="daybreak",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.force_hand = true
	end,
}
popular_influence={
	type="pol",
	name="Popular Influence",
	module="daybreak",
	action = {popular_influence=true}
}
negotiation={
	type="pol",
	name="Negotiation",
	module="daybreak",
}

launch_scout = {
	type = "tac",
	name = "Launch Scout",
	module = "base",
	action = { condition = function(state) return state.raptor > 0 end,
		try = { roll = 3, fail = {raptor = -1}, pass = { choice="acting", a={launch_scout_effect={qty=1, deck="crisis"}}, b={launch_scout_effect={qty=1, deck="destination"}} } } }
}
strategic_planning = {
	type = "tac",
	name = "Strategic Planning",
	module = "base",
}
guts_and_initiative = {
	type = "tac",
	name = "Guts and Initiative",
	module = "pegasus",
}
critical_situation = {
	type = "tac",
	name = "Critical Situation",
	module = "pegasus",
	movement = {
		condition = function(state) return not state.flags.executive_order end,
		critical_situation=true, set_turn_flag = "executive_order" 
	}
}
trust_instincts = {
	type = "tac",
	name = "Trust Instincts",
	module = "exodus",
	precount_func = function (state, check, flags)
		flags.trust_instincts = true
	end,
	skill_check = true,
}
scout_for_fuel = {
	type = "tac",
	name = "Scout for Fuel",
	module = "exodus",
	action = {
		condition = function(state) return state.raptor > 0 end,
		try = {
			roll = 4, pass = {fuel=1}, fail = {raptor=-1}
		}
	}
}
quick_thinking={
	type="tac",
	name="Quick Thinking",
	module="daybreak",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.quick_thinking = true
	end,
}
unorthodox_plan ={
	type="tac",
	name="Unorthodox Plan",
	module="daybreak",
}
second_chance={
	type="tac",
	name="A Second Chance",
	module="daybreak",
}

executive_order = {
	type = "lea",
	name = "Executive Order",
	module = "base",
	action = {
		executive_order=true}
}
declare_emergency = {
	type = "lea",
	name = "Declare Emergency",
	module = "base",
}
major_victory = {
	type = "lea",
	name = "Major Victory",
	module = "pegasus",
}
at_any_cost = {
	type = "lea",
	name = "At Any Cost",
	module = "pegasus",
	reckless = true,
}
iron_will = {
	type = "lea",
	name = "Iron Will",
	module = "exodus",
	precount_func = function (state, check, flags)
		flags.iron_will = true
	end,
	skill_check = true,
}
state_of_emergency = {
	type = "lea",
	name = "State of Emergency",
	module = "exodus",
	action = {food = -1, state_of_emergency = true }
}
all_hands={
	type="lea",
	name="All Hands On Deck",
	module="daybreak",
	precount_func = function (state, check, flags)
		flags.all_hands = true
	end,
	skill_check=true,
}
restore_order={
	type="lea",
	name="Restore Order",
	module="daybreak"
}
change_of_plans={
	type="lea",
	name="Change Of Plans",
	module="daybreak",
}

repair = {
	type = "eng",
	name = "Repair",
	module = "base",
	action = {repair_card=true},
}
scientific_research = {
	type = "eng",
	name = "Scientific Research",
	module = "base",
}
jury_rigged = {
	type = "eng",
	name = "Jury Rigged",
	module = "pegasus",
}
calculations = {
	type = "eng",
	name = "Calculations",
	module = "pegasus",
}
establish_network = {
	type = "eng",
	name = "Establish Network",
	module = "exodus",
	precount_func = function (state, check, flags)
		flags.establish_network = true
	end,
	skill_check = true,
}
build_nuke = {
	type = "eng",
	name = "Build Nuke",
	module = "exodus",
	action = {nukes=1}
}
install_upgrades={
	type="eng",
	name="Install Upgrades",
	module="daybreak",
	skill_check = true,
	precount_func = function (state, check, flags)
		flags.install_upgrades = true
	end,
}
raptor_specialist={
	type="eng",
	name="Raptor Specialist",
	module="daybreak",
	action={
		try={
			raptor=1,
			fail={raptor=1},
			pass={
				choice="acting",
				a={araptor=1, raptor=-1},
				b={raptor=1},
			},
		}
	}
}
test_limits={
	type="eng",
	name="Test The Limits",
	module="daybreak",
	action = {
		try={
			jump_track=3,
			fail={
				jump_prep=1,
				try={
					roll=6,
					fail={damage=1}
				}
			}
		}
	}
}

evasive_maneuvers = {
	type = "pil",
	name = "Evasive Maneuvers",
	module = "base",
}
maximum_firepower = {
	type = "pil",
	name = "Maximum Firepower",
	module = "base",
	action = { maximum_firepower=true }
}
full_throttle = {
	type = "pil",
	name = "Full Throttle",
	module = "pegasus",
	movement = { full_throttle = true },
	action = { full_throttle = true },
}
run_interference = {
	type = "pil",
	name = "Run Interference",
	module = "pegasus",
}
protect_the_fleet = {
	type = "pil",
	name = "Protect the Fleet",
	module = "exodus",
	skill_check = true,
	precount_func = function (state, check, flags)
		flags.protect_fleet = true
	end,
}
best_of_the_best = {
	type = "pil",
	name = "Best of the Best",
	module = "exodus",
	action = { best_of_the_best = true }
}
dogfight = {
	type="pil",
	name="Dogfight",
	module="daybreak",
	skill_check = true,
	precount_func = function (state, check, flags)
		flags.dogfight = true
	end,
}
combat_veteran = {
	type="pil",
	name="Combat Veteran",
	module="daybreak",
	action = { combat_veteran = true }
}
launch_reserves = {
	type="pil",
	name="Launch Reserves",
	module="daybreak",
	action = { launch_reserves = true }
}
broadcast_location = {
	type = "tre",
	module = "pegasus",
	name = "Broadcast Location",
	skill_check = true,
}
by_your_command = {
	type = "tre",
	module = "pegasus",
	name = "By Your Command",
	skill_check = true,
}
special_destiny = {
	type = "tre",
	module = "pegasus",
	name = "Special Destiny",
	skill_check = true,
}
gods_plan = {
	type = "tre",
	module = "pegasus",
	name = "God's Plan",
	movement = {gods_plan=true}
}
sabotage = {
	type = "tre",
	module = "pegasus",
	name = "Sabotage",
}
human_weakness = {
	type = "tre",
	module = "pegasus",
	name = "Human Weakness",
	action = {human_weakness=true}
}
dradis_contact = {
	type="tre",
	module="daybreak",
	name = "Dradis Contact",
	skill_check = true,
	mutiny_on_discard = true,
	precount_func = function (state, check, flags)
		flags.dradis_contact = true
	end,
}
bait = {
	type="tre",
	module="daybreak",
	name="Bait",
	skill_check=true,
	mutiny_on_discard = true,
	precount_func = function (state, check, flags)
		flags.bait = true
	end,
}
better_machine = {
	type="tre",
	module="daybreak",
	name="A Better Machine",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.better_machine = true
	end,
}
personal_vices = {
	type="tre",
	module="daybreak",
	name="Personal Vices",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.personal_vices = true
	end,
}
violent_outbursts = {
	type="tre",
	module="daybreak",
	name="Violent Outbursts",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.violent_outbursts = true
	end,
}
exploit_weakness = {
	type="tre",
	module="daybreak",
	name="Exploit A Weakness",
	skill_check=true,
	precount_func = function (state, check, flags)
		flags.exploit_weakness = true
	end,
}

skill_card_list = {
	consolidate_power,
	investigative_committee,
	support_the_people,
	preventative_policy,
	red_tape,
	political_prowess,
	launch_scout,
	strategic_planning,
	guts_and_initiative,
	critical_situation,
	trust_instincts,
	scout_for_fuel,
	executive_order,
	declare_emergency,
	major_victory,
	at_any_cost,
	iron_will,
	state_of_emergency,
	repair,
	scientific_research,
	jury_rigged,
	calculations,
	establish_network,
	build_nuke,
	evasive_maneuvers,
	maximum_firepower,
	full_throttle,
	run_interference,
	protect_the_fleet,
	best_of_the_best,
	broadcast_location,
	by_your_command,
	special_destiny,
	gods_plan,
	sabotage,
	human_weakness,
	dradis_contact,
	bait,
	better_machine,
	personal_vices,
	violent_outbursts,
	exploit_weakness,
	dogfight,
	combat_veteran,
	launch_reserves,
	install_upgrades,
	raptor_specialist,
	test_limits,
	all_hands,
	restore_order,
	change_of_plans,
	quick_thinking,
	unorthodox_plan,
	second_chance,
	force_hand,
	popular_influence,
	negotiation,
}



base_pol_deck = {
	{ strength = 1, qty = 8, card = consolidate_power },
	{ strength = 2, qty = 6, card = consolidate_power },
	{ strength = 3, qty = 4, card = investigative_committee },
	{ strength = 4, qty = 2, card = investigative_committee },
	{ strength = 5, qty = 1, card = investigative_committee },
}
base_lea_deck = {
	{ strength = 1, qty = 8, card = executive_order },
	{ strength = 2, qty = 6, card = executive_order },
	{ strength = 3, qty = 4, card = declare_emergency },
	{ strength = 4, qty = 2, card = declare_emergency },
	{ strength = 5, qty = 1, card = declare_emergency },
}
base_tac_deck = {
	{ strength = 1, qty = 8, card = launch_scout },
	{ strength = 2, qty = 6, card = launch_scout },
	{ strength = 3, qty = 4, card = strategic_planning },
	{ strength = 4, qty = 2, card = strategic_planning },
	{ strength = 5, qty = 1, card = strategic_planning },
}
base_pil_deck = {
	{ strength = 1, qty = 8, card = evasive_maneuvers },
	{ strength = 2, qty = 6, card = evasive_maneuvers },
	{ strength = 3, qty = 4, card = maximum_firepower },
	{ strength = 4, qty = 2, card = maximum_firepower },
	{ strength = 5, qty = 1, card = maximum_firepower },
}
base_eng_deck = {
	{ strength = 1, qty = 8, card = repair },
	{ strength = 2, qty = 6, card = repair },
	{ strength = 3, qty = 4, card = scientific_research },
	{ strength = 4, qty = 2, card = scientific_research },
	{ strength = 5, qty = 1, card = scientific_research },
}

peg_pol_deck = {
	{ strength = 1, qty = 1, card = support_the_people },
	{ strength = 2, qty = 1, card = support_the_people },
	{ strength = 3, qty = 1, card = preventative_policy },
	{ strength = 4, qty = 1, card = preventative_policy },
	{ strength = 5, qty = 1, card = preventative_policy },
}
peg_lea_deck = {
	{ strength = 1, qty = 1, card = major_victory },
	{ strength = 2, qty = 1, card = major_victory },
	{ strength = 3, qty = 1, card = at_any_cost },
	{ strength = 4, qty = 1, card = at_any_cost },
	{ strength = 5, qty = 1, card = at_any_cost },
}
peg_tac_deck = {
	{ strength = 1, qty = 1, card = guts_and_initiative },
	{ strength = 2, qty = 1, card = guts_and_initiative },
	{ strength = 3, qty = 1, card = critical_situation },
	{ strength = 4, qty = 1, card = critical_situation },
	{ strength = 5, qty = 1, card = critical_situation },
}
peg_pil_deck = {
	{ strength = 1, qty = 1, card = full_throttle },
	{ strength = 2, qty = 1, card = full_throttle },
	{ strength = 3, qty = 1, card = run_interference },
	{ strength = 4, qty = 1, card = run_interference },
	{ strength = 5, qty = 1, card = run_interference },
}
peg_eng_deck = {
	{ strength = 1, qty = 1, card = jury_rigged },
	{ strength = 2, qty = 1, card = jury_rigged },
	{ strength = 3, qty = 1, card = calculations },
	{ strength = 4, qty = 1, card = calculations },
	{ strength = 5, qty = 1, card = calculations },
}
peg_tre_deck = {
	{ strength = 1, qty = 8, card = broadcast_location },
	{ strength = 1, qty = 4, card = by_your_command },
	{ strength = 2, qty = 5, card = special_destiny },
	{ strength = 2, qty = 3, card = gods_plan },
	{ strength = 3, qty = 4, card = sabotage },
	{ strength = 3, qty = 2, card = human_weakness },
}

exo_pol_deck = {
	{ strength = 0, qty = 3, card = red_tape },
	{ strength = 6, qty = 1, card = political_prowess },
}
exo_lea_deck = {
	{ strength = 0, qty = 3, card = iron_will },
	{ strength = 6, qty = 1, card = state_of_emergency },
}
exo_tac_deck = {
	{ strength = 0, qty = 3, card = trust_instincts },
	{ strength = 6, qty = 1, card = scout_for_fuel },
}
exo_pil_deck = {
	{ strength = 0, qty = 3, card = protect_the_fleet },
	{ strength = 6, qty = 1, card = best_of_the_best },
}
exo_eng_deck = {
	{ strength = 0, qty = 3, card = establish_network },
	{ strength = 6, qty = 1, card = build_nuke },
}

day_pol_deck = {
	{ strength = 0, qty = 2, card = force_hand },
	{ strength = 3, qty = 1, card = popular_influence },
	{ strength = 4, qty = 1, card = popular_influence },
	{ strength = 5, qty = 1, card = negotiation },
}
day_lea_deck = {
	{ strength = 0, qty = 2, card = all_hands },
	{ strength = 3, qty = 1, card = restore_order },
	{ strength = 4, qty = 1, card = restore_order },
	{ strength = 5, qty = 1, card = change_of_plans },
}
day_tac_deck = {
	{ strength = 0, qty = 2, card = quick_thinking },
	{ strength = 3, qty = 1, card = unorthodox_plan },
	{ strength = 4, qty = 1, card = unorthodox_plan },
	{ strength = 5, qty = 1, card = second_chance },
}
day_pil_deck = {
	{ strength = 0, qty = 2, card = dogfight },
	{ strength = 3, qty = 1, card = combat_veteran },
	{ strength = 4, qty = 1, card = combat_veteran },
	{ strength = 5, qty = 1, card = launch_reserves },
}
day_eng_deck = {
	{ strength = 0, qty = 2, card = install_upgrades },
	{ strength = 3, qty = 1, card = raptor_specialist },
	{ strength = 4, qty = 1, card = raptor_specialist },
	{ strength = 5, qty = 1, card = test_limits },
}
day_tre_deck = {
	{ strength = 0, qty = 6, card = dradis_contact },
	{ strength = 0, qty = 6, card = bait },
	{ strength = 3, qty = 4, card = better_machine },
	{ strength = 3, qty = 4, card = personal_vices },
	{ strength = 4, qty = 3, card = violent_outbursts },
	{ strength = 5, qty = 3, card = exploit_weakness },
}

mission_cards = {
	{
		name = "Attack on the Colony",
		check = {
			val=14, tac=true, pil=true,
			pass = { remove_basestars=2, permanent_basestars = -1 },
			fail = { damage=1, place_basestar="front", },
		},
		desc = [[[b]Attack on the Colony[/b] <Daybreak Expansion>

Skill Check [14] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: Remove all basestars from the board. Then, remove 1 basestar from the game.
Fail: Place 1 basestar in front of Galactica and damage Galactica.]],
	},
	{
		name = "Cylon Civil War",
		check = {
			val=21, pol=true, lea=true, tac=true,
			pass = {rebel_basestar="human"},
			fail = {rebel_basestar="cylon"},
		},
		desc = [[[b]Cylon Civil War[/b] <Daybreak Expansion>

Skill Check [21] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color]
Pass: Place the Rebel Basestar game board in play with the Basestar Allegiance marker set to its human side.
Fail: Place the Rebel Basestar game board in play with the Basestar Allegiance marker set to its Cylon side.]],
	},
	{
		name = "Destroy the Hub",
		check = {
			val=14, lea=true, tac=true, pil=true,
			pass = { destroy_res_ship = true },
			fail = { pop=-1, sequence={{land_all_vipers=true},{damage_vipers={qty=2, reserve=true}}} },
		},
		desc = [[[b]Destroy the Hub[/b] <Daybreak Expansion>

Skill Check [14] [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: Flip the Cylon Locations overlay over. If a player is sent to the "Resurrection Ship" location, he is now sent to the "Hub Destroyed" location instead.
Fail: -1 population. Return all vipers in space areas to the Reserves and then damage 2 vipers.]],
	},
	{
		name = "Digging Up the Past",
		check = {
			val=14, pol=true, lea=true,
			pass = {delayed_distance=1},
			fail = {tre_to_destiny=2, retry_mission=true},
		},
		desc = [[[b]Digging Up the Past[/b] <Daybreak Expansion>

Skill Check [14] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color]
Pass: This card counts as 1 distance. The next time the fleet jumps, place this card next to the Earth Objective Card.
Fail: Shuffle 2 Treachery Cards into the Destiny deck and turn this card facedown on the "Active Mission" space.]],
	},
	{
		name = "Needs of the People",
		check = {
			val=18, pol=true, lea=true, eng=true,
			pass={food=2, repair={location=1}},
			fail = {food=-1, draw_cards={human={tre=1}}},
		},
		desc = [[[b]Needs of the People[/b] <Daybreak Expansion>

Skill Check [18] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=dodgerblue]Engineering[/color]
Pass: +2 food, and repair 1 damaged location.
Fail: -1 food, and each human player draws a Treachery Card.]],
	},
	{
		name = "Rescue Hera",
		check = {
			val=20, pol=true, tac=true, pil=true,
			pass = {grant_restricted_miracle=1},
			fail = {morale=-1, raptor = -1},
		},
		desc = [[[b]Rescue Hera[/b] <Daybreak Expansion>

Skill Check [20] [color=goldenrod]Politics[/color] + [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color]
Pass: Each human player that does not have a miracle token gains 1 miracle token.
Fail: -1 morale and destroy a raptor.]],
	},
	{
		name = "The Red Stripes",
		check = {
			val=16, tac=true, pil=true, eng=true,
			pass = {remove_all_heavies=true, permanent_heavy_remove=2},
			fail = {place_heavy="front", place_centurions=1},
		},
		desc = [[[b]The Red Stripes[/b] <Daybreak Expansion>

Skill Check [16] [color=mediumorchid]Tactics[/color] + [color=crimson]Piloting[/color] + [color=dodgerblue]Engineering[/color]
Pass: Remove all heavy raiders and centurions from the board. Then, remove 2 heavy raiders and 2 centurions from the game.
Fail: Place 1 heavy raider in front of Galactica and 1 centurion at the start of the Boarding Party track.]],
	},
	{
		name = "The Search For Home",
		check = {
			val=25, pol=true, lea=true, tac=true, eng=true,
			pass = {delayed_distance=2},
			fail = {fuel=-1, retry_mission=true},
		},
		desc = [[[b]The Search For Home[/b] <Daybreak Expansion>

Skill Check [25] [color=goldenrod]Politics[/color] + [color=limegreen]Leadership[/color] + [color=mediumorchid]Tactics[/color] + [color=dodgerblue]Engineering[/color]
Pass: This card counts as 2 distance. The next time the fleet jumps, place this card next to the Earth Objective Card.
Fail: -1 fuel. Then turn this card facedown on the "Active Mission" space.]],
	},
}

mutiny_cards = {
	{
		name="Armed Resistance",
		desc=[[[b]Armed Resistance[/b] <Daybreak Expansion>

[b]Action[/b]: Send the Admiral to "Sickbay" and look at the top card of the Crisis deck. Place that card on the top or bottom of the deck, and discard this card.]],
	},
	{
		name="Assume Command",
		desc=[[[b]Assume Command[/b] <Daybreak Expansion>

[b]Action[/b]: Discard 5 Skill Cards to take the Admiral title. Then, discard this card.

You cannot play this card if you do not have 5 or more Skill Cards, you already hold the Admiral title, or you are in the "Brig."]],
	},
	{
		name="Bait and Switch",
		desc=[[[b]Bait and Switch[/b] <Daybreak Expansion>

[b]Action[/b]: Draw 2 Skill Cards (they may be from outside your skill set). Then, shuffle 2 Treachery Cards into the Destiny deck and discard this card.]],
	},
	{
		name="Betrayal of Trust",
		desc=[[[b]Betrayal of Trust[/b] <Daybreak Expansion>

[b]Action[/b]: Draw 2 Treachery Cards. Then, look at the top card of the Destination deck and place it on the top or bottom of the deck. Finally, discard this card.]],
	},
	{
		name="Blackmail",
		desc=[[[b]Blackmail[/b] <Daybreak Expansion>

[b]Action[/b]: Take 3 random Skill Cards from the President. Then, discard this card.

You cannot play this card if you are the President or if the President has 2 or fewer Skill Cards.
]],
	},
	{
		name="Clipped Wings",
		desc=[[[b]Clipped Wings[/b] <Daybreak Expansion>

[b]Action[/b]: Return all vipers in space areas to the "Reserves" and repair all damaged vipers. Then, draw 2 Treachery Cards and discard this card.

You cannot play this card unless there is at least 1 viper in a space area.
]],
	},
	{
		name="Controversial Speech",
		desc=[[[b]Controversial Speech[/b] <Daybreak Expansion>

[b]Action[/b]: Roll a die. If the result is 6 or more, gain 1 morale and remove this card from the game. Otherwise, discard this card and each player, including Cylon players, draws 1 Treachery Card.
]],
	},
	{
		name="Feed the People",
		desc=[[[b]Feed the People[/b] <Daybreak Expansion>

[b]Action[/b]: Decrease the Jump Preparation track by 2 and gain 1 food. Then, remove this card from the game.]],
	},
	{
		name="Impeachment",
		desc=[[[b]Impeachment[/b] <Daybreak Expansion>

[b]Action[/b]: Discard 5 Skill Cards to take the President title. Then, discard this card.

You cannot play this card if you do not have 5 or more Skill Cards or you already hold the President title.]],
	},
	{
		name="Make a Deal",
		desc=[[[b]Make a Deal[/b] <Daybreak Expansion>

[b]Action[/b]: Choose a character in the "Brig" and move him to any location on Galactica. Then, discard this card and choose a player to draw a Mutiny Card.

You cannot play this card if there are no characters in the "Brig."
]],
	},
	{
		name="Necessary Risk",
		desc=[[[b]Necessary Risk[/b] <Daybreak Expansion>

[b]Action[/b]: Increase food by 1. Then, choose 1 space area and place 1 basestar and 3 raiders in that area. Finally, remove this card from the game.

You can play this card even if all of the Cylon ships cannot be placed.]],
	},
	{
		name="Panic",
		desc=[[[b]Panic[/b] <Daybreak Expansion>

[b]Action[/b]: Place 1 civilian ship behind Galactica. Then, activate 1 unmanned viper, if possible, and discard this card.]],
	},
	{
		name="Peaceful Resistance",
		desc=[[[b]Peaceful Resistance[/b] <Daybreak Expansion>

[b]Action[/b]: Move to "Sickbay" and roll a die. On a result of 4 or less, send the Admiral to the "Brig". Then, discard this card.]],
	},
	{
		name="Ruined Reputation",
		desc=[[[b]Ruined Reputation[/b] <Daybreak Expansion>

[b]Action[/b]: Choose one human player to draw 2 Skill Cards (they may be from outside his skill set). Then, roll a die. On a result of 4 or less, send that player to the "Brig." Then, discard this card.]],
	},
	{
		name="Scavenging for Parts",
		desc=[[[b]Scavenging for Parts[/b] <Daybreak Expansion>

[b]Action[/b]: Damage Galactica and, if possible, choose 1 civilian ship in a space area. Shuffle that ship into the pile of unused civilian ships. Then, discard this card.]],
	},
	{
		name="Selfish Act",
		desc=[[[b]Selfish Act[/b] <Daybreak Expansion>

[b]Action[/b]: Draw 2 Skill Cards. Discard this card and then draw another Mutiny Card.]],
	},
	{
		name="Send a Message",
		desc=[[[b]Send a Message[/b] <Daybreak Expansion>

[b]Action[/b]: Damage Galactica and, if possible, attack a centurion on the Boarding Party track, adding 2 to the die result. Then, discard this card.]],
	},
	{
		name="Set the Agenda",
		desc=[[[b]Set the Agenda[/b] <Daybreak Expansion>

[b]Action[/b]: The President draws 2 Quorum Cards. Look at his Quorum Cards and choose 2 cards. Place them on the bottom of the Quorum deck in any order. Then, discard this card.

You cannot play this card if you are the President.]],
	},
	{
		name="The Strong Survive",
		desc=[[[b]The Strong Survive[/b] <Daybreak Expansion>

[b]Action[/b]: Draw a civilian ship to destroy. Then, increase the Jump Preparation track by 1 and remove this card from the game.]],
	},
	{
		name="Unauthorized Usage",
		desc=[[[b]Unauthorized Usage[/b] <Daybreak Expansion>

[b]Action[/b]: Launch 1 nuke at a basestar. Then remove this card and all nuke tokens from the game.

You cannot play this card if the Admiral has no nuke tokens.]],
	},
	{
		name="Violent Protest",
		desc=[[[b]Violent Protest[/b] <Daybreak Expansion>

[b]Action[/b]: Draw 2 Politics Cards and send the President to "Sickbay." Then, discard this card.]],
	},
	{
		name="Weapons Armed",
		desc=[[[b]Weapons Armed[/b] <Daybreak Expansion>

[b]Action[/b]: Destroy a raptor to gain an assault raptor. Then, launch 2 raiders from each basestar.

You cannot play this card if there are no raptors in the "Reserves."]],
	},

}

locations = {
	comms = {
		name = "Communications",
		alias = "comms",
		ship = "galactica",
		action = { activate_communications = true },
	},
	command = {
		name = "Command",
		ship = "galactica",
		damagable = true,
		action = { sequence={{unmanned_activation=true},{unmanned_activation=true}} },
	},
	ftl = {
		name = "FTL Control",
		alias = "ftl",
		ship = "galactica",
		damageable = true,
		action = { activate_ftl_control=true }
	},
	weapons = {
		name = "Weapons Control",
		alias = "weapons",
		ship = "galactica",
		damageable = true,
		action = { activate_weapons_control = true}
	},
	research = {
		name = "Research Lab",
		alias = "lab",
		ship = "galactica",
		action = { choice="acting",
			desc={a='Draw Eng', b='Draw Tac'},
			mapping={a='eng', b = 'tac'},
			a={card_draws={active={eng=1}}},
			b={card_draws={active={tac=1}}},
		}
	},
	admiralq = {
		name = "Admiral's Quarters",
		alias = "admiral",
		ship = "galactica",
		damageable = true,
		action = { choose_player={check={val=7,lea=true, tac=true, pass={force_move={to="brig", who="chosen"}}}}}
	},
	hangar = {
		name = "Hangar Deck",
		alias = "hangar",
		ship = "galactica",
		damageable = true,
		action = { activate_hangar_deck = true}
	},
	armoy = {
		name = "Armory",
		ship = "galactica",
		damageable = true,
		action = { try = { roll = 7, pass = { destroy_centurion = true } } }
	},
	sickbay = {
		name = "Sickbay",
		ship = "galactica",
		hazardous = true,
	},
	brig = {
		name = "Brig",
		ship = "galactica",
		action = { check={val=7,pol=true,tac=true,pass={activate_brig = true}}},
		hazardous = true,
	},
	press = {
		name = "Press Room",
		alias = "press",
		ship = "colonial_one",
		action = { activate_press_room = true }
	},
	president = {
		alias = "president",
		name = "President's Office",
		ship = "colonial_one",
		action = { activate_presidents_office = true },
	},
	quorum_chamber = {
		alias = "quorum",
		name = "Quorum Chamber",
		ship = "colonial_one",
		action = { activate_quorum = true },
		module = "daybreak",
	},
	admin = {
		alias = "admin",
		name = "Administration",
		ship = "colonial_one",
		action = { administration = true }
	},
	pegcic = {
		name = "Pegasus CIC",
		alias = "cic",
		ship = "pegasus",
		damageable = true,
		action = { activate_pegasus_cic = true },
	},
	airlock = {
		name = "Airlock",
		ship = "pegasus",
		damageable = true,
		action = { check={val=12,pol=true,tac=true,tre=true, pass={execute={choice="acting"} }} },
	},
	batteries = {
		name = "Main Batteries",
		alias = "batteries",
		ship = "pegasus",
		damageable = true,
		action = { activate_pegasus_batteries = true },
	},
	engine = {
		name = "Engine Room",
		alias = "engine",
		ship = "pegasus",
		damageable = true,
		action = { draw_cards={acting=-2},set_turn_flag = "engine_room" },
	},
	captains = {
		name = "Captain's Cabin",
		alias = 'cabin',
		ship = 'demetrius',
		action = { captains_cabin_effect = true },
	},
	tactical = {
		name = 'Tactical Plot',
		alias = 'tactical',
		ship = 'demetrius',
		action = { launch_scout_effect = { deck = 'mission' } },
	},
	bridge = {
		name = 'Bridge',
		ship = 'demetrius',
		action = { start_mission = true }
	},
	hybrid_tank = {
		name = 'Hybrid Tank',
		alias = 'hybrid',
		ship = 'rebel',
		action = { hybrid_effect = true }
	},
	datastream = {
		name = 'datastream',
		ship = 'rebel',
		action = { datastream_effect = true }
	},
	raider_bay = {
		name = 'Raider Bay',
		ship = 'rebel',
		action = { raider_bay_effect = true }
	},
	caprica = {
		name = "Caprica",
		ship = "cylon",
		action = { activate_caprica = true },
	},
	cylonfleet = {
		name = "Cylon Fleet",
		ship = "cylon",
		action = { activate_cylon_fleet = true },
	},
	humanfleet = {
		name = "Human Fleet",
		ship = "cylon",
		action = { activate_human_fleet = true },
	},
	resship = {
		name = "Resurrection Ship",
		ship = "cylon",
		action = { draw_supercrisis = 1 },
		hazardous = true,
	},
	basestarbridge = {
		name = "Basestar Bridge",
		ship = "cylon",
		action = { activate_basestar_bridge = true },
		module = "cylon_fleet",
	},
	viper = {
		name = "Piloting a viper",
		ship = "viper",
	}
}

destination_cards = {
	{
		name = "Algae Planet",
		effect = { distance = 1, food = 1, fuel = -1 },
		text = "Lose 1 Fuel and gain 1 Food.",
	},
	{
		name = "Asteroid Field", qty=2,
		effect = { distance = 3, fuel = -2, civ = -1 },
		text = "Lose 2 Fuel. Then draw 1 Civilian Ship and destroy it (lose the resources on the back).",
	},
	{
		name = "Barren Planet", qty=4,
		effect = { distance = 2, fuel = -2 },
		text = "Lose 2 Fuel.",
	},
	{
		module = "pegasus",
		name = "Binary Star",
		effect = { distance = 2, fuel = -1, placement = { rear = { civ = 1 }, front = { civ = 1}} },
		text = "Lose 1 Fuel. Place 1 Civilian Ship in front of Galactica and 1 Civilian Ship behind Galactica.",
	},
	{
		module = "pegasus",
		name = "A Civilian Convoy",
		effect = { distance = 3, fuel = -3, pop = 1, choice = "admiral", a={morale=-1, fuel=1} },
		text = "Lose 3 Fuel and gain 1 Population. The Admiral may choose to lose 1 Morale to gain 1 Fuel.",
	},
	{
		name = "Cylon Ambush",
		effect = { distance = 3, fuel = -1, placement = { rear={civ=3}, front={basestar=1,raider=3}} },
		text = "Lose 1 Fuel. Then place 1 Basestar and 3 Raiders in front of Galactica and 3 civilian ships behind Galactica.",
	},
	{
		module = "exodus",
		name = "Cylon Raiders",
		effect = { distance = 3, fuel = -2, placement={rear={raider=3}} },
		text = "Lose 2 Fuel and place 3 raiders behind Galactica.",
	},
	{
		name = "Cylon Refinery",
		effect = { distance = 2, fuel = -1, choice = "admiral", a={try={roll=6, pass={fuel=2},fail={damage_vipers= 2}}} },
		text = "Lose 1 Fuel. The Admiral may risk 2 Vipers to roll a die. If 6 or higher, gain 2 Fuel. Otherwise, damage 2 Vipers.",
	},
	{
		name = "Deep Space", qty=3,
		effect = { distance = 2, fuel = -1, morale = -1 },
		text = "Lose 1 Fuel and 1 Morale.",
	},
	{
		module = "exodus",
		name = "Derelict Basestar",
		text = "Lose 1 Fuel. Then place 2 civilian ships behind Galactica and 1 basestar in front of Galactica. Damage the basestar once.",
		effect = { distance = 2, fuel = -1, placement = {rear={civ=2},front={basestar={1,damage=1}} },},
	},
	{
		name = "Desolate Moon",
		effect = { distance = 3, fuel = -3 },
		text = "Lose 3 Fuel.",
	},
	{
		module = "exodus",
		name = "Dying Star",
		effect = { distance = 2, fuel = -1, damage = 1 },
		text = "Lose 1 Fuel and damage Galactica once.",
	},
	{
		module = "pegasus",
		name = "Gas Cloud",
		effect = { distance = 1, gas_cloud_effect = true },
		text = "The Admiral may look at the top 3 cards of the Crisis deck, then place them on the top or bottom of the deck in any order.",
	},
	{
		module = "exodus",
		name = "Gas Giant",
		effect = { distance = 1, choice = "admiral", a = {destroy_viper = 1, fuel=1} },
		text = "The Admiral may destroy 1 viper to gain 1 Fuel.",
	},
	{
		name = "Icy Moon", qty=2,
		effect = { distance = 1, fuel = -1, choice = "admiral",
			a = { try = { roll=3, pass={food=1}, fail={raptor=-1} } },
		},
		text = "Lose 1 Fuel. The Admiral may risk 1 Raptor to roll a die. If 3 or higher, gain 1 Food. Otherwise, destroy 1 Raptor.",
	},
	{
		module = "exodus",
		name = "Lion's Head Nebula",
		effect = { distance = 3, fuel = -4, jump_prep = 2 },
		text = "Lose 4 Fuel. After the Reset Jump Preparation Track step of this jump, advance the Jump Preparation track by 2.",
	},
	{
		module = "pegasus",
		name = "Mining Asteroid",
		text = "Lose 1 Fuel and repair 2 Vipers. Search the Crisis deck or discard pile for the “Scar” card and immediately resolve it. Then shuffle the Crisis deck.",
		effect = { distance = 2, fuel = -1, mining_asteroid_effect = true,},
	},
	{
		module = "pegasus",
		name = "Misjump",
		effect = { distance = 0, civ = -1, redraw_destination = true },
		text = "Draw 1 Civilian Ship and destroy it. Then discard this card and draw a new Destination Card to resolve.",
	},
	{
		module = "exodus",
		name = "Radioactive Cloud",
		effect = { distance = 2, fuel = -1, pop = -1 },
		text = "Lose 1 Fuel and 1 Population.",
	},
	{
		name = "Ragnar Anchorage",
		effect = { distance = 1, choice = "admiral", a = {ragnar_anchorage_effect=true} },
		text = "The Admiral may repair up to 3 Vipers and 1 Raptor. These ships may be damaged or even destroyed.",
	},
	{
		name = "Remote Planet", qty=3,
		effect = { distance = 2, fuel = -1, raptor = -1 },
		text = "Lose 1 Fuel and destroy 1 Raptor.",
	},
	{
		name = "Tylium Planet", qty=4,
		effect = { distance = 1, fuel = -1, choice = "admiral",
			a={try={roll=3, pass={fuel=2}, fail={raptor=-1} } },},
		text = "Lose 1 Fuel. The Admiral may risk 1 Raptor to roll a die. If 3 or higher, gain 2 Fuel. Otherwise, destroy 1 Raptor.",
	},
}

allies = {
	{
		name = 'Lee "Apollo" Adama',
		location = "Hangar Deck",
		benevolent = {name="Inspirational Pilot", action={lee_ally_benevolent=true}},
		antagonistic = {name = "Under Too Much Pressure", action={activate='launch'}},
		desc=[[[b]Lee "Apollo" Adama[/b]

[b]Location[/b]: Hangar Deck
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Inspirational Pilot[/b] - Each unmanned viper may destroy a raider in its current space area.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Under Too Much Pressure[/b] - Activate the following Cylon ships: Launch Raiders]],
	},
	{
		name = 'William Adama',
		location = "Admiral's Quarters",
		benevolent = {name="Veteran Commander",action={draw_cards={current={lea=3}}}},
		antagonistic = {name="No Man Left Behind",action={jump_prep=-1}},
		desc=[[[b]William Adama[/b]

[b]Location[/b]: Admiral's Quarters
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Veteran Commander[/b] - Draw 3 Leadership Skill Cards.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]No Man Left Behind[/b] - Decrease the Jump Preparation track by 1]],
	},
	{
		name = 'Karl "Helo" Agathon',
		location = "Weapons Control",
		benevolent = {name="Devoted Officer",action={draw_cards={current={tac=3}}}},
		antagonistic = {name="Unpopular Decisions", action={try={roll=5, fail={morale=-1}}}},
		desc=[[[b]Karl "Helo" Agathon[/b]

[b]Location[/b]: Weapons Control
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Devoted Officer[/b] - Draw 3 Tactics Skill Cards.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Unpopular Decisions[/b] – Roll a die. On a 4 or lower, lose 1 morale.]],
	},
	{
		name = "Samuel T. Anders",
		location = "Armory",
		benevolent = {name="Athlete",action={centurion_retreat=true}},
		antagonistic = {name="Rookie Pilot", action={damage_vipers={qty=2, space=true, unmanned_only=true}}},
		desc=[[[b]Samuel T. Anders[/b]

[b]Location[/b]: Armory
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Athlete[/b] - Move all centurion tokens on the boarding party track one space towards the "Start" space.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Rookie Pilot[/b] - Choose two unmanned vipers in space areas to move to the "Damaged Vipers" box.]],
	},
	{
		name = "Gaius Baltar",
		location = "Research Lab",
		benevolent = {name="Brilliant Scientist",action={look_at_loyalty = {chooser="current", qty=1}}},
		antagonistic = {name="Odd Behaviour",action={try={distance=7,fail={baltar_ally_antagonistic = true}}}},
		desc=[[[b]Gaius Baltar[/b]

[b]Location[/b]: Research Lab
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Brilliant Scientist[/b] - You may look at 1 random Loyalty Card belonging to any player.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Odd Behavior[/b] - If distance is 7 or less, shuffle 1 "You are Not a Cylon" card into the Loyalty deck. Then draw 1 Loyalty Card. Otherwise, no effect.]],
	},
	{
		name = "Helena Cain",
		location = "Command",
		benevolent = {name="Uncompromising",action={execute={who="choice", chooser="current"}}},
		antagonistic = {name="No Room For Mistakes",action={force_move={to="brig", who="admiral"}}},
		desc=[[[b]Helena Cain[/b]

[b]Location[/b]: Command 
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Uncompromising[/b] - You may choose another human character to be executed.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]No Room For Mistakes[/b] - The Admiral is sent to the "Brig".]],
	},
	{
		name = 'Brendan "Hot Dog" Costanza',
		location = "Weapons Control",
		benevolent = {name="Fearless Pilot", action={hot_dog_effect = true} },
		antagonistic = {name="Troublemaker", action={try={roll=5,fail={morale=-1}}}},
		desc=[[[b]Brendan "Hot Dog" Costanza[/b]

[b]Location[/b]: Weapons Control
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Fearless Pilot[/b] - Choose 1 space area on the main game board and destroy 2 raiders in that area.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Troublemaker[/b] - Roll a die. On a 4 or lower, lose 1 morale.]]
	},
	{
		name = 'Dr. Sherman Cottle',
		location = "Sickbay",
		benevolent = {name="Expert Surgeon",action={trauma=-3, free_move=true}},
		antagonistic = {name="Chain Smoker",action={card_draws={current=-3}, free_move=true}},
		desc=[[[b]Dr. Sherman Cottle[/b]

[b]Location[/b]: Sickbay
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Expert Surgeon[/b] - Discard 3 of your trauma tokens and then move to any location.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Chain Smoker[/b] - Discard 3 Skill Cards, then move to any location.]],
	},
	{
		name = 'Anastasia "Dee" Dualla',
		location = "Communications",
		benevolent = {name="CIC Officer",action={communications_effect={all=true, move_all=true}}},
		antagonistic = {name="Despondent",action={trauma=2}},
		desc=[[[b]Anastasia "Dee" Dualla[/b]

[b]Location[/b]: Communications
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]CIC Officer[/b] - Look at every civilian ship on the game board and then you may move any number of them to adjacent areas.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Despondent[/b] - Draw 2 trauma tokens.]],
	},
	{
		name = 'Margaret "Racetrack" Edmondson',
		location = "Weapons Control",
		benevolent = {name="Gifted Raptor Pilot",action={fuel=1}},
		antagonistic = {name="Kill Them All!",action={trauma=1,random_discard={current=1}  }},
		desc=[[[b]Margaret "Racetrack" Edmondson[/b]

[b]Location[/b]: Weapons Control
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Gifted Raptor Pilot[/b] - Gain 1 fuel.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Kill Them All![/b] - Draw 1 trauma token and discard 1 random Skill Card.]],
	},
	{
		name = 'Priestess Elosha',
		location = "President's Office",
		benevolent = {name="Religious Leader",action={launch_scout_effect={qty=1, deck="crisis"}}},
		antagonistic = {name="Crisis of Faith",action={trauma=2}},
		desc=[[[b]Priestess Elosha[/b]

[b]Location[/b]: President's Office
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Religious Leader[/b] - Look at the top of the Crisis deck, and place it on the top or bottom of the deck.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Crisis of Faith[/b] - Draw 2 trauma tokens.]],
	},
	{
		name = 'Tory Foster',
		location = "Press Room",
		benevolent = {name="Political Strategist",action={draw_cards={current={pol=3}}}},
		antagonistic = {name="Questionable Ethics",action={random_discard={current=2}}},
		desc=[[[b]Tory Foster[/b]

[b]Location[/b]: Press Room 
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Political Strategist[/b] - Draw 3 Politics Skill Cards.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Questionable Ethics[/b] - Discard 2 random Skill Cards.]],
	},
	{
		name = 'Felix Gaeta',
		location = "FTL Control",
		benevolent = {name="Tactical Officer",action={jump_prep=1}},
		antagonistic = {name="Consumed with Bitterness",action={choice="current",a={trauma=2},b={random_discard={current=3}}}},
		desc=[[[b]Felix Gaeta[/b]

[b]Location[/b]: FTL Control 
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Tactical Officer[/b] - Advance the Jump Preparation track by 1.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Consumed with Bitterness[/b] - Draw 2 trauma tokens or discard 3 Skill Cards.]],
	},
	{
		name = 'Louis Hoshi',
		location = "Communications",
		benevolent = {name="Communications Officer",action={escort_civ={where="any",qty=1}}},
		antagonistic = {name="Emotionally Compromised",action={activate="basestar"}},
		desc=[[[b]Louis Hoshi[/b]

[b]Location[/b]: Communications
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Communications Officer[/b] - Choose 1 civilian ship in a space area to shuffle back into the pile of unused civilian ships.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Emotionally Compromised[/b] - Activate the following Cylon ships: Activate Basestars]],
	},
	{
		name = 'Louanne "Kat" Katraine',
		location = "Hangar Deck",
		benevolent = {name="Hotshot Pilot",action={draw_cards={current={pil=3}}}},
		antagonistic = {name="Stim Addiction",action={random_discard={current=3}}},
		desc=[[[b]Louanne "Kat" Katraine[/b]

[b]Location[/b]: Hangar Deck
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Hotshot Pilot[/b] - Draw 3 Piloting Skill Cards.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Stim Addiction[/b] - Discard 3 Skill Cards.]],
	},
	{
		name = 'Billy Keikeya',
		location = "Administration",
		benevolent = {name="Populist Politician",action={morale=1}},
		antagonistic = {name="Jealous Nature",action={trauma=1, random_discard={current=1}}},
		desc=[[[b]Billy Keikeya[/b]

[b]Location[/b]: Administration
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Populist Politician[/b] - Gain 1 morale.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Jealous Nature[/b] - Draw 1 trauma token and discard 1 random Skill Card.]],
	},
	{
		name = 'Aaron Kelly',
		location = "Command",
		benevolent = {name="Landing Signal Officer",action=nil},
		antagonistic = {name="Extreme Measures",action={damage=1}},
		desc=[[[b]Aaron Kelly[/b]

[b]Location[/b]: Command 
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Landing Signal Officer[/b] - Activate up to 4 unmanned vipers.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Extreme Measures[/b] - Damage Galactica.]],
	},
	{
		name = 'Romo Lampkin',
		location = "Brig",
		benevolent = {name="Clever Lawyer",action={free_move={galactica=true}}},
		antagonistic = {name="Kleptomaniac",action={random_discard={current=99}}},
		desc=[[[b]Romo Lampkin[/b]

[b]Location[/b]: Brig
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Clever Lawyer[/b] - Move out of the "Brig" location.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Kleptomaniac[/b] - Discard all of your Skill Cards.]],
	},
	{
		name = 'Alex "Crashdown" Quartararo',
		location = "Armory",
		benevolent = {name="Loyal ECO",action={launch_scout_effect={qty=1, deck="crisis"}}},
		antagonistic = {name="Inexperienced Leader",action={try={roll=5, fail={pop=-1}}}},
		desc=[[[b]Alex "Crashdown" Quartararo[/b]

[b]Location[/b]: Armory
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Loyal ECO[/b] - Look at the top card of the Destination deck and place it on the top or bottom of the deck.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Inexperienced Leader[/b] - Roll a die. On a 4 or lower, lose 1 population.]],
	},
	{
		name = 'Laura Roslin',
		location = "President's Office",
		benevolent = {name="Gifted Leader",action={trauma=-2}},
		antagonistic = {name="Debilitating Illness",action={trauma=2}},
		desc=[[[b]Laura Roslin[/b]

[b]Location[/b]: President's Office
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Gifted Leader[/b] - Discard 2 trauma tokens.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Debilitating Illness[/b] - Draw 2 trauma tokens.]],
	},
	{
		name = 'Diana "Hardball" Seelix',
		location = "Armory",
		benevolent = {name="Avionics Specialist",action={vipers=3}},
		antagonistic = {name="Unforgiving",action={force_move={to="sickbay", who="current"}}},
		desc=[[[b]Diana "Hardball" Seelix[/b]

[b]Location[/b]: Armory
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Avionics Specialist[/b] - Move 3 vipers from the "Damaged Vipers" box to the "Reserves".
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Unforgiving[/b] - You are sent to "Sickbay".]],
	},
	{
		name = 'Kendra Shaw',
		location = "Weapons Control",
		benevolent = {name="Razor",action={ choice="current",a={}, b={ choice="current", morale = -1, a={fuel=1},b={food=1} } }},
		antagonistic = {name="Went Too Far",action={civ=-1}},
		desc=[[[b]Kendra Shaw[/b]

[b]Location[/b]: Weapons Control
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Razor[/b] - You may lose 1 morale to gain either 1 fuel or 1 food.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Went Too Far[/b] - Draw a civilian ship to destroy.]],
	},
	{
		name = 'Kara "Starbuck" Thrace',
		location = "Hangar Deck",
		benevolent = {name="Skilled Pilot",action={starbuck_benevolent_effect = true}},
		antagonistic = {name="Risky Maneuvers",action={activate='raider'}},
		desc=[[[b]Kara "Starbuck" Thrace[/b]

[b]Location[/b]: Hangar Deck
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Skilled Pilot[/b] - Choose 1 unmanned viper to activate 4 times.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Risky Maneuvers[/b] - Activate the following Cylon ships: Activate Raiders]],
	},
	{
		name = 'Ellen Tigh',
		location = "Admiral's Quarters",
		benevolent = {name="Savvy Manipulator",action=nil},
		antagonistic = {name="Bad Influence",action={force_move={to="brig", who="current"}}},
		desc=[[[b]Ellen Tigh[/b]

[b]Location[/b]: Admiral's Quarters
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Savvy Manipulator[/b] - You may choose any human player to receive either the President or the Admiral title.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Bad Influence[/b] - You are sent to the "Brig".]],
	},
	{
		name = 'Saul Tigh',
		location = "Command",
		benevolent = {name="Executive Officer",action=nil},
		antagonistic = {name="Heavy-handed",action={force_move={to="brig", who="current"}}},
		desc=[[[b]Saul Tigh[/b]

[b]Location[/b]: Command
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Executive Officer[/b] - You may choose another character to send to the "Brig".
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Heavy-handed[/b] - You are sent to the "Brig".]],
	},
	{
		name = 'Callandra "Cally" Tyrol',
		location = "Hangar Deck",
		benevolent = {name="Gifted Deckhand",action={draw_cards={current={eng=3}}}},
		antagonistic = {name="Mood Swings",action={try={roll=5,fail={morale=-1}}}},
		desc=[[[b]Callandra "Cally" Tyrol[/b]

[b]Location[/b]: Hangar Deck
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Gifted Deckhand[/b] - Draw 3 Engineering Skill Cards.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Mood Swings[/b] - Roll a die. On a 4 or lower, lose 1 morale.]],
	},
	{
		name = '"Chief" Galen Tyrol',
		location = "Hangar Deck",
		benevolent = {name="Senior Chief Petty Officer",action=nil},
		antagonistic = {name="Depression and Anger",action={force_move={to="sickbay", who="current"}}},
		desc=[[[b]"Chief" Galen Tyrol[/b]

[b]Location[/b]: Hangar Deck
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Senior Chief Petty Officer[/b] - Repair up to 2 locations on Galactica or up to 4 damaged vipers.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Depression and Anger[/b] - You are sent to the "Sickbay".]],
	},
	{
		name = 'Sharon "Boomer" Valerii',
		location = "Armory",
		benevolent = {name="Talented Raptor Pilot",action={food=1}},
		antagonistic = {name="Botched Landings",action={damage=1}},
		desc=[[[b]Sharon "Boomer" Valerii[/b]

[b]Location[/b]: Armory
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Talented Raptor Pilot[/b] - Gain 1 food.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Botched Landings[/b] - Damage Galactica.]],
	},
	{
		name = 'Tom Zarek',
		location = "Administration",
		benevolent = {name="Resourceful",action=
				{
					choice = "current", a={},
					b = { pop = -1,
						choice = "current", a={fuel=1},
						b = { choice = "current", a={morale=1},b={food=1}}
					},
				}
			},
		antagonistic = {name="Dubious Associations",action={force_move={to="brig", who="current"}}},
		desc=[[[b]Tom Zarek[/b]

[b]Location[/b]: Administration 
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Resourceful[/b] - You may lose 1 population to gain 1 of any other resource type.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Dubious Associations[/b] - You are sent to the "Brig".]],
	},
	{
		name = 'Brother Cavil',
		location = "Research Lab",
		benevolent = {name="Unconventional Counselor",action={sequence={{trauma=-1},{trauma={qty=-1, random=true}}}}},
		antagonistic = {name="Primary Cylon",action={place_basestar="front", place_civ="rear", place_raiders={qty=3, at="front"}}},
		desc=[[[b]Brother Cavil[/b]

[b]Location[/b]: Research Lab
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Unconventional Counselor[/b] - Choose 1 trauma token to discard. Then choose a second trauma token at random to discard.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Primary Cylon[/b] - Place a basestar and 3 raiders in front of Galactica. Place 1 civilian ship behind Galactica.]],
	},
	{
		name = 'Leoben Conoy',
		location = "Communications",
		benevolent = {name="Tuned In",action=nil},
		antagonistic = {name="Unstable Cylon",action={trauma=2}},
		desc=[[[b]Leoben Conoy[/b]

[b]Location[/b]: Communications
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Tuned In[/b] - Choose 1 space area on the main game board and destroy all Cylon ships from that area.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Unstable Cylon[/b] - Draw 2 trauma tokens.]],
	},
	{
		name = "D'Anna Biers",
		location = "Press Room",
		benevolent = {name="Investigative Journalist",action={morale=1}},
		antagonistic = {name="Opportunistic Cylon",action={choice="current",a={trauma=2}, b={card_draws={current=-3}}}},
		desc=[[[b]D'Anna Biers[/b]

[b]Location[/b]: Press Room
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Investigative Journalist[/b] - Gain 1 morale.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Opportunistic Cylon[/b] - Draw 2 trauma tokens or discard 3 Skill Cards.
]],
	},
	{
		name = "Simon O'Neill",
		location = "Sickbay",
		benevolent = {name="Cylon Medic",action=nil},
		antagonistic = {name="Experimental Procedures",action=nil},
		desc=[[[b]Simon O'Neill[/b]

[b]Location[/b]: Sickbay
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Cylon Medic[/b] - Draw 2 Skill Cards of any type (they may be from outside your skill set). Then move to any location.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Experimental Procedures[/b] - Draw 2 trauma tokens. Then move to any location.]],
	},
	{
		name = 'Aaron Doral',
		location = "Administration",
		benevolent = {name="Bureaucrat",action=nil},
		antagonistic = {name="Calculating Cylon",action={damage=1}},
		desc=[[[b]Aaron Doral[/b]

[b]Location[/b]: Administration
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Bureaucrat[/b] - Draw 3 Quorum Cards, choose 1 to resolve and place the rest on the bottom of the deck (even if you are not President).
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Calculating Cylon[/b] - Damage Galactica.]],
	},
	{
		name = 'Caprica Six',
		location = "Brig",
		benevolent = {name="Cooperative Cylon Prisoner",action={jump_prep=1}},
		antagonistic = {name="",action=nil},
		desc=[[[b]Caprica Six[/b]

[b]Location[/b]: Brig
[b][color=dodgerblue]Benevolent Result[/color][/b]: [b]Cooperative Cylon Prisoner[/b] - Advance the Jump Preparation by 1.
[b][color=crimson]Antagonistic Result[/color][/b]: [b]Delusional[/b] - Discard 3 random Skill Cards and then draw the top 2 cards of the Destiny deck and add them to your hand of Skill Cards.]],
	},
}

loyalty_cards = {
	{name="pg_titles", type="personal_goals", cylon=false, personal_goal={goal="Acquire Power", penalty='food'}, desc=[[[b]You Are Not a Cylon: Personal Goal: Acquire Power: 2 or More Title Cards at the Same Time[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if you currently hold 2 or more Title Cards.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Food.]]},
	{name="pg_nukeless", type="personal_goals", cylon=false, personal_goal={goal="Devastation", penalty='morale' }, desc=[[[b]You Are Not a Cylon: Personal Goal: Devastation: Admiral has no Remaining Nuke Tokens[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if the Admiral has no remaining nuke tokens.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Morale.]] },
	{name="pg_bigged_pres", type="personal_goals", cylon=false, personal_goal={goal="Politial Intrigue", penalty='food' }, desc=[[[b]You Are Not a Cylon: Personal Goal: Political Intrigue: The President is in the "Brig"[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if the President is in the "Brig".

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Food.]] },
	{name="pg_damged_vipers", type="personal_goals", cylon=false, personal_goal={goal="Sacrifice", penalty='fuel' }, desc=[[[b]You Are Not a Cylon: Personal Goal: Sacrifice: 6 Vipers Damaged or Destroyed[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if 6 or more vipers are either damaged or destroyed.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Fuel.]]},
	{name="pg_brig_or_sickbay", type="personal_goals", cylon=false, personal_goal={goal="Self Destruction", penalty='morale' }, desc=[[[b]You Are Not a Cylon: Personal Goal: Self-Destruction: In the "Brig" or the "Sickbay"[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if you are in the "Brig" or "Sickbay".

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Morale.]] },
	{name="pg_discard", type="personal_goals", cylon=false, personal_goal={goal="Selfish", penalty='fuel' },desc=[[[b]You Are Not a Cylon: Personal Goal: Selfish: Discard Skill Cards Equal to 20 Strength[/b] <Exodus Expansion>

[b]Action[/b]: Discard any number of Skill Cards with a combined strength of 20 to reveal this card.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Fuel.]] },
	{name="pg_raiders", type="personal_goals", cylon=false, personal_goal={goal="Stand And Fight", penalty='pop' } ,desc=[[[b]You Are Not a Cylon: Personal Goal: Stand and Fight: 10 or More Raiders[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if 10 or more raiders are on the main game board.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Population.]]},
	{name="pg_1dist", type="personal_goal", cylon=false, personal_goal={goal="Caution", penalty='pop' },desc=[[[b]You Are Not a Cylon: Personal Goal: Use Caution: The Fleet Has Made a 1-Distance Jump[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card if a 1-distance Destination Card has been resolved.

Then, if distance is 6 or less, shuffle 1 "You Are Not a Cylon" card into the Loyalty deck and draw a new Loyalty Card.

If you are a human player and this card has not been revealed by the end of the game, lose 1 Population.]] },
	
	{name="final5_damage", type="final5", cylon=false, final5={damage = 2}, desc=[[[b]You Are Not a Cylon: The Final Five: If This Card is Examined, Galactica is Damaged Twice[/b] <Exodus Expansion>

If this card is examined by another player, it is immediately revealed and Galactica is damaged twice.

Then reshuffle this card with any other Loyalty Cards you have and return them facedown in front of you.

If this card is revealed as a result of execution, all players must discard 2 Skill Cards.]] },
	{name="final5_activate", type="final5", cylon=false, final5={activate = {"raider", "basestar", "heavy"}} ,desc=[[[b]You Are Not a Cylon: The Final Five: If This Card is Examined, Cylon Ships are Activated[/b] <Exodus Expansion>

If this card is examined by another player, it is immediately revealed and Activate Raiders, Activate Basestars, and Activate Heavy Raiders.

Then reshuffle this card with any other Loyalty Cards you have and return them facedown in front of you.

If this card is revealed as a result of execution, all players must discard 2 Skill Cards.]]},
	{name="final5_selfexecute", type="final5", cylon=false, final5={execute_self = true} ,desc=[[[b]You Are Not a Cylon: The Final Five: If This Card is Examined, You are Executed[/b] <Exodus Expansion>

If this card is examined by another player, it is immediately revealed, you are executed, and all other players must discard 2 random Skill Cards.

If this card is revealed as a result of execution, all players must discard 2 Skill Cards.]]},
	{name="final5_executed", type="final5", cylon=false, final5={execute_examiner = true} ,desc=[[[b]You Are Not a Cylon: The Final Five: Whoever Examines This Card is Executed[/b] <Exodus Expansion>

If this card is examined by another player, it is immediately revealed. The player who examined this card is executed.

Then reshuffle this card with any other Loyalty Cards you have and return them facedown in front of you.

If this card is revealed as a result of execution, all players must discard 2 Skill Cards.]]},
	{name="final5_bigged", type="final5", cylon=false, final5={brig_examiner = true} ,desc=[[[b]You Are Not a Cylon: The Final Five: Whoever Examines This Card is Sent to the "Brig"[/b] <Exodus Expansion>

If this card is examined by another player, it is immediately revealed. The player who examined this card is sent to the "Brig".

Then reshuffle this card with any other Loyalty Cards you have and return them facedown in front of you.

If this card is revealed as a result of execution, all players must discard 2 Skill Cards.]]},
	{type="exodus", cylon=true, action = {jump_prep = -2}, name = "jump prep", desc=[[[b]You Are a Cylon: Can Decrease the Jump Preparation Track by 2[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card. If you are not in the "Brig", you may decrease the Jump Preparation track by 2.]]},
	{type="exodus", cylon=true, name = "centurion", action = {centurion = 1},desc=[[[b]You Are a Cylon: Can Place a Centurion Token on the Boarding Party Track[/b] <Exodus Expansion>

[b]Action[/b]: Reveal this card. If you are not in the "Brig",you may place a centurion token at the start of the Boarding Party track.]]},
	{type="pegasus", cylon=true, name = "treachery", action = "treachery" ,desc=[[[b]You Are a Cylon: Can Make Players Draw Treachery Cards[/b] <Pegasus Expansion>

[b]Action[/b]: Reveal this card. If you are not in the "Brig", each human player discards one random Skill Card and draws 1 Treachery Card. Then you draw 2 Treachery cards (after you discard down to 3 Skill Cards).]]},
	{cylon=true, name = "morale", action={morale = -1},desc=[[[b]You Are a Cylon: Can Reduce Morale by 1[/b]

[b]Action[/b]: Reveal this card. If you are not in the "Brig", you may reduce Morale by 1.]]},
	{cylon=true, name = "brig", action = {choice_force_move = {chooser="acting", to="brig", forced = false}},desc=[[[b]You Are a Cylon: Can Send a Character to the Brig[/b]

[b]Action[/b]: Reveal this card. If you are not in the "Brig", you may choose a character on Galactica. Move that character to the "Brig".]]},
	{cylon=true, name = "sickbay", action = {choice_force_move = {chooser="acting", to="sickbay", forced = false}},desc=[[[b]You Are a Cylon: Can Send a Character to Sickbay[/b]

[b]Action[/b]: Reveal this card. If you are not in the "Brig", you may choose a character on Galactica. That character must discard 5 Skill Cards and is moved to "Sickbay".]]},
	{cylon=true, name = "damage", action = {damage_choice = {chooser = "acting", choice = 5, qty = 2} },desc=[[[b]You Are a Cylon: Can Damage Galactica[/b]

[b]Action[/b]: Reveal this card. If you are not in the "Brig", you may draw up to 5 Galactica damage tokens. Choose 2 of them to resolve and discard the others.]]},
}

motive_list = {
	['Keep Them Docile'] = '(Allegiance: Human) Reveal this card if the game is over and food is 4 or less.',
	['Pressure their Leaders'] = '(Allegiance: Human) Reveal this card if the game is over and morale is 5 or less.',
	['Learn to Cherish'] = '(Allegiance: Human) Reveal this card if the game is over and population is 6 or less',
	['Improve Efficiency'] = '(Allegiance: Human) Reveal this card if the game is over and you have at least 1 Politics card, 1 Tactics card, and 1 Engineering card in your hand of Skill Cards.',
	['Remove the Threat'] = '(Allegiance: Human) Reveal this card if the game is over and at least 4 vipers are damaged or destroyed.',
	['End the Chase'] = [[(Allegiance: Human) Reveal this card if "FTL Control" or "Admiral's Quarters" is damaged.]],
	['Make an Ally'] = '(Allegiance: Human) Reveal this card if another player is in the "Brig" and you have a Mutiny Card.',
	['Harvest their Resources'] = ' (Allegiance: Cylon) Reveal this card if the game is over and food is 2 or more.',
	['A False Sense of Security'] = '(Allegiance: Cylon) Reveal this card if the game is over and morale is 3 or more.',
	['Subjects for Study'] = '(Allegiance: Cylon) Reveal this card if the game is over and population is 4 or more.',
	['Fight with Honor'] = '(Allegiance: Cylon) Reveal this card if the game is over and you have at least 3 Treachery Cards in your hand of Skill Cards.',
	['Savor their Demise'] = '(Allegiance: Cylon) Reveal this card if the game is over and 7 or more distance has been traveled.',
	['No Unnecessary Force'] = '(Allegiance: Cylon) Reveal this card if 5 or more distance has been traveled and no centurions are on the Boarding Party track.',
	['A Justified Response'] = '(Allegiance: Cylon) Reveal this card if the fleet marker is on a blue space of the Jump Preparation track and there are no raiders, heavy raiders, or basestars on the board.',
}

local function genfind(t, name)
	local name_lower = name:lower()
	if t[name] then return t[name] end
	if t[name_lower] then return t[name_lower] end
	for k,v in pairs(t) do
		if name_lower == v.name:lower() then return v end
		if v.alias then
			if type(v.alias) == "string" then
				if name_lower == v.alias:lower() then
					return v
				end
			else
				for _,u in pairs(v.alias) do
					if name_lower == u:lower() then
						return v
					end
				end
			end
		end
	end
end

function find_mutiny(name)
	return genfind(mutiny_cards, name)
end

function find_location(name)
	return genfind(locations, name)
end

function find_card(name)
	return genfind(skill_card_list, name)
end

function get_crisis_by_id(id)
	for k,v in pairs(base_crisis_cards) do
		if v.id == id then return v end
	end
	for k,v in pairs(pegasus_crisis_cards) do
		if v.id == id then return v end
	end
	for k,v in pairs(exodus_crisis_cards) do
		if v.id == id then return v end
	end
	for k,v in pairs(daybreak_crisis_cards) do
		if v.id == id then return v end
	end
end

function match_name(name, p)
	local n = p.name
	if p.alt then n = n .. ' (alt)' end
	if name:lower() == n:lower() then return p end
	if p.alias then
		for _,v in pairs(p.alias) do
			if v:lower() == name:lower() then return p end
		end
	end
end

function find_ally(name)
	for k,v in pairs(allies) do
		if v.name == name then return v end
	end
end

function find_char(name)
	for k,v in pairs(characters) do
		if match_name(name, v) then return v end
	end
end


function find_destination(name)
	for k,v in pairs(destination_cards) do
		if v.name == name then return v end
	end
end

function find_mission(name)
	for k,v in pairs(mission_cards) do
		if v.name == name then return v end
	end
end

find_crisis = get_crisis_by_id

function find_crisis_by_name(name)
	return genfind(base_crisis_cards, name)
end

function find_supercrisis(name)
	for _,deck in pairs({base_supercrisis,pegasus_supercrisis,exodus_supercrisis}) do
		for k,v in pairs(deck) do
			if v.name == name then return v end
		end
	end
end

function find_quorum(name)
	for _,deck in pairs({base_quorum,pegasus_quorum,exodus_quorum}) do
		for k,v in pairs(deck) do
			if v.name == name then return v end
		end
	end
end


function foreach_crisis(func)
	for k,v in ipairs({'base','pegasus','exodus','daybreak'}) do
		local list = _G[v..'_crisis_cards']
		for i,j in ipairs(list) do
			func(j, v)
		end
	end
end

function combined_crisis_list()
	local t = {}
	for k,v in ipairs({'base','pegasus','exodus','daybreak'}) do
		local list = _G[v..'_crisis_cards']
		for i,j in ipairs(list) do
			table.insert(t, j)
		end
	end
	return t
end

function counter(func, set)
	return function(v, exp)
		local result = func(v)
		if result and set then
			set.total = (set.total or 0) + 1
			if exp then set[exp] = (set[exp] or 0) + 1 end
		end
		return result
	end
end

function filter_crisis_list(func, list)
	if not list then list = combined_crisis_list() end
	local t = {}
	for k,v in ipairs(list) do
		if func(v) then table.insert(t, v) end
	end
	return t
end

function analyze_crises(desc, func, list)
	local n = 0
	for k,v in ipairs(list or combined_crisis_list()) do
		if func(v) then n = n + 1 end
	end
	print(string.format(desc, n))
end

function check_results(check)
	local function build(t)
		local k, f
		return function()
			while true do
				if not f then
					local v
					k, v = next(check, k)
					if k == 'sequence' then
						local n = 1
						local __t = t
						local __f
						f = function()
							while true do
								if __f then
									local k, v = __f()
									if k then return k,v end
									__f = nil
								end
								local v = __t[n]
								n = n + 1
								if v then
									__f = build(v)
								else
									return
								end
							end
						end
					else
						return k, v
					end
				end
				if f then
					local k, v = f()
					if k then return k, v end
					f = nil
				end
			end
		end
	end
	return build(check)
end

function f_choices(v) return v.choice ~= nil end
function f_check(v) return v.check or (v.a and v.a.check) or (v.b and v.b.check) end
function f_jump(v) return v.jump_prep end
