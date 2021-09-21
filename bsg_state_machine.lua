state_machine = nil

local tins = table.insert
local sfmt = string.format

function state_funcs:ChangeState(s, substate)
	self.state = s
	self.substate = substate
	self.state_changed = true
end
function state_funcs:PushState(s, substate)
	local push = {state = self.state, substate = self.substate}
	table.insert(self.state_stack, 1, push)
	self.state = s
	self.substate = substate
	self.state_changed = true
end
function state_funcs:PopState(what)
	if what then
		if what == self.state then return self:PopState() end
		
		for i=1, #self.state_stack do
			if self.state_stack[i].state == what then
				table.remove(self.state_stack, i)
				return
			end
		end
		panic()
	elseif #self.state_stack > 0 then
		self.state = self.state_stack[1].state
		self.substate = self.state_stack[1].substate
		table.remove(self.state_stack, 1)
		self.state_changed = true
	else
		self:PushState('error_underflow')
	end
end

function state_funcs:ExecState()
	local f = state_machine[self.state] or _G['state_' .. self.state] or self['state_' .. self.state]
	if not f then error("Unknown state " .. self.state) end
	f(self, self.substate)
end

function state_funcs:state_idle()
	self:PopState()
end

function state_funcs:state_game_setup(sub)
	if not sub then
		self.substate = {}
		for k,v in ipairs(self.players) do
			table.insert(self.substate, {what="location", who=k})
		end
		for k,v in ipairs(self.players) do
			table.insert(self.substate, {what="loyalty", who=k})
		end
		for k,v in ipairs(self.players) do
			table.insert(self.substate, {what="cards", who=k})
		end
	else
		while #sub > 0 do
			local e = sub[1]
			local p = self.players[e.who]
			if e.what == 'location' then
				self:PlaceSelectedCharacter(p)
			elseif e.what == 'loyalty' then
				self:NewCharacterLoyalty(p)
			else
				if e.who == 1 then
					-- do nothing
				elseif p.type == "cylon" then
					-- as per FAQ cylon leaders only start with 2 cards
					p:DrawCards(2)
				else
					p:DrawCards(3)
				end
			end
			table.remove(sub, 1)
		end
		self:ChangeState('start_turn')
	end
end

function state_funcs:state_daybreak_press_room(sub)
	if not sub.chosen then
		local who = self.acting:Choice(self:FilterPlayers('human'), 'who draws mutiny?')
		sub.chosen = who
		who:DrawMutiny(nil, {no_brig=true})
		return
	end
	sub.chosen:DiscardMutiny(#sub.chosen.mutiny_hand - 1)
	self.acting:DiscardMutiny(1)
	self:PopState('daybreak_press_room')
end

function state_funcs:state_clear_chosen()
	self.chosen = nil
	self:PopState()
end

function state_funcs:state_draw_trauma(sub)
	local who = sub.who or self.acting
	local disasters = 0
	while sub.qty ~= 0 do
		if sub.qty > 0 then
			local trauma = self:DrawTrauma()
			if trauma == 'disaster' then
				disasters = disasters + 1
				self:ResultLog('%s draws a disaster token', who:full_name(true))
				if who:Cylon() then
					self:ResultLog('Must draw 2 more trauma tokens')
					sub.qty = sub.qty + 2
				else
					self.trauma.disaster = self.trauma.disaster + disasters
					self:PushState('execute', {who=who})
					self:PopState('draw_trauma')
					return
				end
			else
				self:ResultLog('%s draws a trauma token', who:full_name(true))
			end
			if trauma ~= 'disaster' then
				who.trauma[trauma] = who.trauma[trauma] + 1
			end
			sub.qty = sub.qty - 1
		else
			if sub.random then
				local n = (who.trauma.benevolent or 0) + (who.trauma.antagonistic or 0)
			else
			end
			panic()
		end
	end
	self.trauma.disaster = self.trauma.disaster + disasters
	who:PrivateMsg('Trauma: %d Benevolent, %d Antagonistic', who.trauma.benevolent, who.trauma.antagonistic)
	self:PopState('draw_trauma')
end

function state_funcs:state_execute(sub)
	self:Execute(sub.who)
end

function state_funcs:state_start_turn(sub)
	if not sub then
		self.activation_list = {}
		self.substate = {}
		for k,v in ipairs(self.players) do
			if v.name == "Saul Tigh" and #v.hand == 1 then
				self:ResultLog('%s is forced to discard his last card', v:full_name())
				v:DiscardCards(1)
				break
			end
		end
		return
	end
	
	if not self.no_automatic_saves and not sub.saved then
		sub.saved = true
		--self:Save()
	end
	self.turn_progress = self.state
	self.jump_prep = 0
	self.turn_crisis = nil
	if not sub.turn_incremented then
		self.turn = (self.turn or 0) + 1
		sub.turn_incremented = true
	end
	
	local who = self.current
	
	if not sub.trauma_drawn and who.location and self.ionian_nebula then
		sub.trauma_drawn = true
		local at = self.current.location.name
		if at == 'Brig' or at == 'Sickbay' then
			local trauma = self['trauma_' .. at] or self:DrawTrauma()
			self['trauma_' .. at] = self:DrawTrauma()
			if trauma == 'disaster' then
				self:ResultLog('%s draws a disaster token', who:full_name())
				self.disaster = self.disaster + 1
				self:PushState('execute', {who=who})
				return
			end
			who.trauma[trauma] = who.trauma[trauma] + 1
			who:PrivateMsg('Trauma: %d Benevolent, %d Antagonistic', who.trauma.benevolent, who.trauma.antagonistic)
		end
	end

	if not sub.cards_dealt then
		self:DealTurnCards()
		sub.cards_dealt = true
	end
	
	if who.name == 'Louanne "Kat" Katraine' then
		self.turn_flags.katraine_starting_location = self.current.location.name
	end
	
	self.acting = self.current
	self.crisis_flags = {}
	self.turn_flags = {}
	self:ChangeState('end_turn')
	self:PushState('jump_prep', {})
	if not self.current:Cylon() then self:PushState('activate_cylon_ships') end
	self:PushState('pre_crisis')
	self:PushState('action_end')
	if self.current.name == 'Kara "Starbuck" Thrace' and self.current.location.ship == "viper" then
		self:PushState('action', {requires_human = true})
	end
	self:PushState('action')

	self:PushState('movement_end')
	self:PushState('movement')
end

function state_funcs:state_pre_mission(sub)
	local mission = self.mission_deck:draw_top()
	self.current_mission = mision
	self:ChangeState('crisis', {crisis = mission, mission = true})
end

function state_funcs:state_end_turn(sub)
	-- check hand limits, discard if needed
	if not sub then self.substate = {} return end
	if not self.current:Cylon() and self.current.name == 'Sharon "Boomer" Valerii' and not sub.boomer_scout then
		sub.boomer_scout = true
		self:PushState('launch_scout_effect', {acting=self.current, deck='crisis'})
		return
	end
	
	local discarding
	for k,v in ipairs(self:InTurnOrder()) do
		local limit = (v.hand_limit or 10)
		local overlimit = #v.hand - limit
		if overlimit > 0 then
			discarding = true
			v:DiscardCards(overlimit)
		end
	end
	if discarding then return end
		
	if self.crossroads then
		self.crossroads = nil
		self:PushState('crossroads_cleanup')
		self:PushState('crossroads', {})
		return
	end

	self.turn_progress = self.state
	self.turn_crisis = nil
	self.recieve_skills_msg = ''
	
	if self:CheckEndOfGame() then self:PushState('cylon_win') return end
	
	local n = self.current.number + 1
	if n > #self.players then n = 1 end
	self.current = self.players[n]

	-- reset everything
	self.state_stack = {}
	self:ChangeState('start_turn')
end

function state_funcs:state_null()
	self:PopState()
end

function state_funcs:state_crossroads_cleanup()
	self.allies = {}

	for k,v in ipairs(self.players) do
		local t = v.trauma
		self:ResultLog('%s reveals %d Antagonistic and %d Benevolent trauma', v:full_name(true), t.antagonistic, t.benevolent)
		if t.antagonistic > 2 and not v:Cylon() or t.benevolent > 2 and v:Cylon() then
			self:ResultLog('%s is eliminated', v:full_name(true))
		end
	end

	self.crossroads_resolved = true
	self:PopState()
end

function state_funcs:state_crossroads(sub)
	if not sub.board_setup then
		self:DeployShips('basestar', 1, 'saft')
		self:DeployShips('raider', 4, 'saft')
		self:DeployShips('basestar', 1, 'sbow')
		self:DeployShips('raider', 4, 'sbow')
		sub.board_setup = true
	end

	if not sub.dealt then
		self:ResultLog('All players get dealt a crossroad card and must choose a trauma token to place on it. Players without a trauma token have a free choice. At the end of resolution the human with the most Antagonistic tokens or the Cylon with the most Benevolent tokens (and has more than 2) is eliminated from the game. Cylon leaders are considered human if infiltrating.')
		local cards = shuffle_list{1, 2, 3, 4, 5, 6, 7}
		for i=1,7 do
			if self.players[i] then
				self.players[i].crossroads_card = cards[i]
				self.players[i]:PrivateMsg('Crossroads card:\n' .. crossroads_cards[cards[i]].desc)
			end
		end
		sub.dealt = true
	end

	local list = self:InTurnOrder()
	if not sub.chosen then
		local t = {}
		for i=1,#list do
			local c = {}
			local trauma = list[i].trauma
			if trauma.antagonistic > 0 then tins(c, 'antagonistic') end
			if trauma.benevolent > 0 then tins(c, 'benevolent') end
			if #c == 0 then c = {'antagonistic','benevolent'} end
			t[i] = list[i]:Choice(c, 'crossroads')
			trauma[t[i]] = trauma[t[i]] - 1
		end
		sub.chosen = t

		for i=#list,1,-1 do
			self:PushState('eval_crossroads', {who=list[i], choice=sub.chosen[i]})
		end
	end
	self:PopState('crossroads')
end

function state_funcs:state_eval_crossroads(sub)
	local c = crossroads_cards[sub.who.crossroads_card]
	local t = {antagonistic='b', benevolent='a'}

	self:ResultLog('%s reveals %s and card %s', sub.who:full_name(true), sub.choice, c.desc)

	self:PopState()
	self.acting = sub.who
	self:Resolve(c[t[sub.choice]])
end

function state_funcs:state_presidents_office(sub)
	if not sub then self.substate = {} return end
	
	if not sub.drawn then
		sub.drawn = true
		self:DrawQuorumCardToHand()
	end
	
	local t = {}
	for k,v in pairs(self.quorum_hand) do
		t[v] = true
	end
	local choices = {'draw', 'play'}
	
	local choice = self.president:Choice(choices, 'draw or play?')
	self:PopState()
	if choice == 'draw' then
		self:DrawQuorumCardToHand()
	else
		self:PushState('play_quorum', {who=self.president})
	end
end

function state_funcs:state_play_quorum(sub)
	local who = sub.who or self.president
	local hand = sub.hand or self.quorum_hand
	if not sub.choice then
		sub.choice = who:Choice(hand, 'quorum card to play')
		for k,v in pairs(hand) do
			if v == sub.choice then
				table.remove(hand, k)
				break
			end
		end
		self:Resolve(find_quorum(sub.choice).action)
		return
	end
	self:ResultLog('%s plays %s', who:full_name(true), sub.choice)
	if self.trash_card then
		self:ResultLog('%s is removed from the game', sub.choice)
	else
		self.quorum_deck:discard(sub.choice)
	end
	local tory = self:FindPlayer('Tory Foster')
	if tory then
		tory:DrawSpecificCards({pol=2})
	end
	self.trash_card = nil
	self:PopState('play_quorum')
end

function state_funcs:state_movement_end(sub)
	self.turn_progress = self.state
	-- encounter allies
	local who = self.current
	-- TODO: technically, these can happen in either order
	if who.name == 'Ellen Tigh' then
		local choices = {'q'}
		for k,v in ipairs(self.players) do
			if who.location.name == v.location.name and v ~= who then tins(choices, v) end
		end
		local result = who:Choice(choices, 'pass card to whom?')
		if result ~= 'q' then
			local card = who:ChooseCard('pass which card?')
			self:ResultLog(who:full_name(true) .. ' passes a card to ' .. result:full_name(true))
			tins(result.hand, card)
			result:PrivateMsg('Ellen passes you ' .. card:formatted())
			who:DrawCards(2)
		end
	end
	self:PopState()
	if self.allies then
		self:EncounterAlly(who)
	end
end

function state_funcs:state_movement(sub)
	self.turn_progress = self.state
	local who = self.acting
	local choices = {'pass'}

	if not sub or not sub.restricted then
		for k,v in pairs(who.hand) do
			if v.movement then
				table.insert(choices, 'card')
				break
			end
		end

		if who.opg and who.opg.movement and not who.opg_used then
			table.insert(choices, 'opg')
		end
		if who.movement then
			table.insert(choices, 'character')
		end
	end
	
	if who.location.ship == "viper" then
		tins(choices, 'viper')
	end
	
	choices = who:GetLegalMovementTargets(choices, sub and sub.infiltrate)

	local move = who:Choice(choices, 'movement step')
	local loc = find_location(move)
	local discard_required = false
	
	-- is this a move to a location?
	if move == "pass" then
		-- nothing to do
		self:ResultLog("Movement step: %s [b]pass[/b]", who:full_name(true))
	elseif move == "opg" then
		if who.opg_used then
			print("OPG already used!\n");
			return
		end
		self:ResultLog("%s uses OPG!\n", who:full_name(true))
		who.opg_used = true
		self:Resolve(who.opg.movement)
	elseif move == "character" then
		-- movement action
		self:Resolve(who.movement)
	elseif move == "card" then
		-- playing a card... which one?
		local choices = {}
		for k,v in ipairs(who.hand) do
			if v.movement then
				print("%d - %s %d %s\n", k, v.type, v.strength, v.name)
				tins(choices, k)
			end
		end
		if #choices == 0 then
			printf("No movement step cards")
			return
		end
		local choice = who:Choice(choices, 'which card?')
		local card = table.remove(who.hand, choice)
		self:ResultLog('%s plays %s', who:full_name(true), card:formatted())
		self:ToDiscard(card)
		self:PopState()
		self:Resolve(card.movement)
		return
	elseif move == 'viper' then
		self:ViperActivation(who, true)
	elseif loc then
		-- is a discard required?
		if who.location.ship ~= loc.ship and (not sub or not sub.infiltrate) then
			if #who.hand == 0 then
				self:ResultLog("Illegal move: required dicard with empty hand")
				return
			end
			discard_required = true
		end
		if who.location.ship == 'cylon' then
			if not who:Cylon() then
				self:ResultLog("Illegal move: non-cylon moving to cylon location")
				return
			end
		end
		self:ResultLog("Movement step: move to [b]%s[/b]", loc.name)
		who:MoveTo(loc)
			
	else
		-- resolve movement card / ability
		panic("Unknown movement: "..move)
		return
	end
	self:PopState('movement')
	if discard_required then
		who:DiscardCards(1, nil, true)
	end
end

function state_funcs:state_set_active_player(sub)
	self.acting = sub.who
	self:PopState()
end

function state_funcs:state_exec(sub)
	local f = loadstring(sub.text)
	local t = setmetatable({state=self, sub=sub}, {__index=_G})
	setfenv(f, t)
	f()
	self:PopState()
end

function state_funcs:state_action(sub)
	if sub and sub.set_acting then
		self.acting = sub.set_acting
		sub.set_acting = nil
	end
	local who = self.acting
	assert(who)
	local discards = 0
	self.turn_progress = self.state
	if not sub then self.substate = {} return end
	if sub and sub.requires_human and who:Cylon() then
		who:ResultLog('Lost action due to being a toaster!')
		state:PopState()
		return
	end
	
	local miracle_needed = 1
	
	local choices = {'pass'}
	if sub.allow_move then tins(choices, 'move') end
	if who.name == 'Gaius Baltar (alt)' then
		miracle_needed = 3
		if who.miracle < 3 then
			for k,v in pairs(self.players) do
				if v ~= who and v.location.name == who.location.name and v.miracle > 0 then
					tins(choices, 'take miracle')
					break
				end
			end
		else
			tins(choices, 'opg')
		end
	end
	if who.location.ship == 'viper' then
		tins(choices, 'viper')
	elseif who.location.action and who:CanActivateLocation() then
		tins(choices, 'loc')
	end
	if who.opg and who.opg.action and who.miracle >= miracle_needed then
		tins(choices, 'opg')
	end
	if who == self.cag then
		if who.location.ship == 'viper' and not self.flags.cag_used then
			tins(choices, 'cag')
		end
		tins(choices, 'cag2')
	end
	if who == self.admiral and self.nukes > 0 then
		tins(choices, 'nuke')
	end
	if who:HiddenCylon() then
		tins(choices, 'reveal')
	end
	if self.president == who then
		tins(choices, "play quorum")
	end
	for k,v in pairs(who.hand) do
		if v.action then
			table.insert(choices, 'card')
			break
		end
	end
	local action = who:Choice(choices, 'action step')
	if action == "?" then
		print("pass - do nothing\nopg - use opg\nloc - activate location\ncard - play card\n")
		return
	end
	
	if action == "pass" then
		-- nothing to do, passing
		who:ResultLog("Action step: %s [b]pass[/b]", who:full_name(true))
		self:PopState()
		return
	elseif action == 'move' then
		self:PopState()
		self:PushState('movement')
		return
	elseif action == "play quorum" then
		self:PopState()
		self:PushState('play_quorum', {who=self.president})
	elseif action == 'take miracle' then
		local players = {}
		for k,v in pairs(self.players) do
			if v ~= who and v.location.name == who.location.name and v.miracle > 0 then
				tins(players, v)
				break
			end
		end
		local target = who:Choice(players, 'take which miracle token?')
		target.miracle = target.miracle - 1
		who.miracle = who.miracle + 1
		self:PopState()
		self:ResultLog("%s takes %s's miracle token", who:full_name(true), target:full_name(true))
	elseif action == 'reveal' then
		self:ResultLog('%s reveals as a cylon!', who:full_name(true))
		self:PopState()
		self:PushState('reveal', {who=who, source='action'})
	elseif action == 'nuke' then
		local sector = who:Choice({'paft','pbow','saft','sbow','rear','front'}, 'nuke where?')
		self.nukes = self.nukes - 1
		self:PopState()
		self:PushState('do_nuke', {where=sector})
	elseif action == 'opg' then
		-- opg use
		if who.miracle < miracle_needed then
			print("%s has already used their OPG", who:internal_name());
			return
		elseif who.name == 'Gaius Baltar (alt)' then
			local res = who:Choice({'food','fuel','morale','pop'})
			who.miracle = who.miracle - 3
			local t = {}
			t[res] = 2
			self:Resolve(t)
		else
			who.miracle = who.miracle - 1
			self:Resolve(who.opg.action)
		end
		self:PopState('action')
	elseif who == self.cag and (action == 'cag' or action == 'cag2') then
		if action == 'cag' and who.location.ship == 'viper' then
			self.turn_flags.cag_used = true
			self:PushState('viper_activations', {qty=1})
		elseif action == 'cag2' then
			local choices = self:FilterPlayers({'real_human','!acting'})
			local choice = who:Choice(choices, 'Pass title to?')
			self.cag = choice
			self:ResultLog('CAG title passes to %s', choice:full_name())
			self:PopState()
			self:PushState('viper_activations', {qty=1})
		end
	elseif action == "loc" then
		local location = who.location
		if not location.action then
			print("%s is at at %s which does not have an action", who:internal_name(), location.name)
			return
		end
		
		-- activate location
		if not who:CanActivateLocation(location) then
			print("%s cannot activate the %s\n", who.name, location.name)
		end
		
		if who.name == "Laura Roslin" then
			--laura must discard 2 cards because she's terrible
			discards = 2
		end
		
		if who.name == 'Louis Hoshi' and (location.name == 'Command' or location.name == 'Communications' or location.name == 'Weapons Control') then
			self:PushState('hoshi_extra_activate', {what=location.name})
		end

		self:ResultLog('%s activates %s', who:full_name(true), location.name)
		self:PushState('resolve_effects', {effect=location.action, source='location', specific=location.name})
		self:PopState('action')
	elseif action == "card" then
		-- playing a card... which one?
		if who.name == 'Louis Hoshi' then
			who:DiscardCards(1)
		end
		
		local card = who:ChooseCard('card', function(c) return c.action end)
		self:ResultLog('%s plays %s', who:full_name(true), card:formatted())
		self:ToDiscard(card)
		self:PopState()
		self:Resolve(card.action)
	elseif action == 'viper' then
		if self:ViperActivation(who) then
			self:PopState('action')
		end
	else
		-- this could be a character action or a card or any other kind of action
		panic("Unknown action: "..action)
	end
	
	if discards > 0 then
		self:DiscardCards(discards)
	end
end

function state_funcs:state_major_victory_check(sub)
	local who = self.acting or self.current
	if who:CheckForCard('Major Victory') then
		if who:YN('Play major victory?') and who:PlayCard('Major Victory') then
			self:Resolve{try={roll=5, pass={morale=1}}}
		end
	end
	self:PopState('major_victory_check')
end

function state_funcs:state_hoshi_extra_activate(sub)
	local hoshi = self:FindPlayer('Louis Hoshi')
	if hoshi:Choice({'y','n'}, 'activate again?') == 'y' then
		local location = find_location(sub.what)
		self:ResultLog('%s activates %s again', hoshi:full_name(true), location.name)
		self:PushState('resolve_effects', {effect=location.action, source='location', specific=location.name})
		self:Resolve({card_draws={['Louis Hoshi']=-1}})
	end
	self:PopState('hoshi_extra_activate')
end

function state_funcs:state_damage_vipers(sub)
	local who = self.current
	while sub.qty > 0 do
		local choices = {}

		if self.viper > 0 then
			tins(choices, 'viper')
		end
		if self.viper7 > 0 then
			tins(choices, 'viper7')
		end
		for k,v in pairs(self.space) do
			if (v.viper or 0) + (v.viper7 or 0) > 0 then
				tins(choices, k)
			end
		end
		local choice = who:Choice(choices, 'damage what?')
		if choice == 'viper' or choice == 'viper7' then
			self:ResultLog('A reserve %s is damaged', names[choice:match('viper7?')])
			self[choice] = self[choice] - 1
			self['damaged_' .. choice] = self['damaged_' .. choice] + 1
		elseif choice == 'damaged_viper' or choice == 'damaged_viper7' then
			self:ResultLog('A %s is destroyed', names[choice:match('viper7?')])
			self[choice] = self[choice] - 1
		elseif self.space[choice] then
			local spacename = choice
			local sp = self.space[choice]
			
			-- we can have both manned and unmanned vipers here
			choices = {}
			local nv = sp.viper or 0
			local nv7 = sp.viper7 or 0
			local na = sp.araptor or 0
			for k,v in pairs(sp.pilots or {}) do
				if v.what == 'viper' then
					nv = nv - 1
				elseif v.what == 'viper7' then
					nv7 = nv7 - 1
				else
					na = na - 1
				end
				tins(choices, {name=v.who.name,who=v.who,what=v.what})
			end
			if nv > 0 then tins(choices, 'unmanned viper') end
			if nv7 > 0 then tins(choices, 'unmanned viper mk7') end
			if na > 0 then tins(choices, 'raptor') end
			
			if #choices == 0 then return end
			
			choice = self.current:Choice(choices, 'raider attacks which viper?')
			
			local pilot
			if type(choice) == 'table' then
				vtype = choice.what
				pilot = choice.who
			elseif choice == 'raptor' then
				vtype = 'araptor'
			elseif choice == 'unmanned viper' then
				vtype = 'viper'
			else
				vtype = 'viper7'
			end
			sp[vtype] = sp[vtype] - 1
			self['damaged_' .. vtype] = self['damaged_' .. vtype] + 1
			if pilot then
				self:ResultLog("%s's viper was damaged", pilot:full_name(true))
				pilot:MoveTo('Sickbay')
			else
				self:ResultLog("An unmanned %s in %s was damaged", names[vtype], names[spacename])
			end
		end
		sub.qty = sub.qty - 1
	end
	self:PopState('damage_vipers')
end

function state_funcs:state_do_nuke(sub)
	local where = sub.where
	if self.roll_result then
		sub.roll = self.roll_result
		self.roll_result = nil
	end
	if not sub.roll then
		self:PushState('do_roll', {why=sub.desc, mod=sub.mod})
		return
	end
	local sector = self.space[where]
	local roll = sub.roll
	if roll <= 2 then
		-- damage twice
		self:PushState('damage', {ship='basestar', qty=2, area=where})
	elseif roll <= 7 then
		-- destroy basestar (and maybe 3 raiders)
		if sector.basestar and #sector.basestar > 0 then
			self:ResultLog('A basestar is destroyed')
			self:PushState('major_victory_check')
		end
		if sector.basestar and #sector.basestar > 1 then
			local which = self.current:Choice({1,2}, 'which basestar?')
			table.remove(sector.basestar, which)
		else
			sector.basestar = nil
		end
		if roll == 7 then
			local n = (sector.raider or 0) - 3
			sector.raider = (n >= 0 and n) or 0
		end
	else
		-- everything
		
		-- land pilots
		panic()
		
		-- wipe it
		self.space[where] = {}
	end
	self:PopState('do_nuke')
end

function state_funcs:state_reveal(sub)
	local who = sub.who
	local src = sub.source
	
	who.miracle = 0
	
	-- move to res ship, this causes :Cylon() to return true
	if not sub.moved then
		sub.in_brig = (who.location.name == 'Brig')
		sub.moved = true
		who:MoveTo('Resurrection Ship')
	end
	
	-- discard down to 3 cards
	if #who.hand > 3 then
		who:DiscardCards(#who.hand - 3)
		return
	end
	-- hand off titles
	for k,v in ipairs({'admiral', 'president', 'cag'}) do
		if who == self[v] then
			self:ResolveEffectsNow{force_title_change={abdicate=true, title=v}}
		end
	end
	
	-- cylon leaders are done at this point
	if who.type == 'cylon' then
		self:PopState()
		return
	end
	
	-- choose which loyalty card to reveal
	if not sub.chosen then
		local choices = {}
		for k,v in ipairs(who.loyalty) do
			if v.cylon then
				table.insert(choices, v.name)
			end
		end
		local choice = who:Choice(choices, 'loyalty to show')
		for k,v in ipairs(who.loyalty) do
			if v.cylon and v.name == choice then
				sub.chosen = v
				table.remove(who.loyalty, k)
				break
			end
		end
		self:ResultLog('\n%s\n', sub.chosen.desc)
	end

	-- hand off excess loyalty cards
	if not sub.handed_off_loyalty then
		sub.handed_off_loyalty = true
		local target = who:Choice(self.players, 'give loyalty to who?')
		self:ResultLog('Extra loyalty cards are passed to %s', target:full_name(true))
		while #who.loyalty > 0 do
			local l = table.remove(who.loyalty)
			table.insert(target.loyalty, l);
			target:PrivateMsg('New loyalty: ' .. print_loyalty_card(l))
		end
	end

	if not sub.reveal_effects then
		sub.reveal_effects = true
		if src == 'action' and not sub.in_brig then
			-- fire the reveal effect
			self:Resolve(sub.chosen.action)
			return
		end
	end
	
	if not sub.got_sc then
		sub.got_sc = true
		if src == 'action' then
			local sc = table.remove(self.supercrisis_deck)
			if not who.supercrisis_hand then who.supercrisis_hand = {} end
			table.insert(who.supercrisis_hand, sc)
			who:PrivateMsg('Supercrisis: %s', find_supercrisis(sc).desc)
		end
	end
	
	if who == self.current then
		-- end turn
		self:ResultLog("%s's turn ends immediately", who:full_name(true))
		self:ChangeState('end_turn')
		return
	end
	
	self:PopState()
end

function state_funcs:state_mysterious_message_effect(sub)
	local who = self.current
	if not sub.dd_sent then
		who:PrivateMsg('Destiny deck')
		for k,v in ipairs(self.destiny_deck) do
			who:PrivateMsg(v:formatted())
		end
		sub.dd_sent = true
		sub.removes = 2
	end
	while sub.removes > 0 do
		local choices = {}
		for k,v in ipairs(self.destiny_deck) do
			print("%d - %s %d %s\n", k, v.type, v.strength, v.name)
			table.insert(choices, k)
		end
		local result = self:Choice(choices, 'discard')
		local card = table.remove(self.hand, tonumber(result))
		self:ToDiscard(card)
		sub.removes = sub.removes - 1
	end
	
	self:ResultLog('The destiny deck is shuffled and has %d cards', #self.destiny_deck)
	self.destiny_deck = shuffle_list(self.destiny_deck)
	self:PopState()
end

function state_funcs:state_full_throttle(sub)
	local who = self.acting
	if not sub.moved then
		local where = who:Choice(space_areas, 'move to sector?')
		self:PilotMove(who, where)
		sub.moved = true
	end

	if not self.activated then
		self:ViperActivation(who, false, true)
		sub.activated = true
	end
	self:PopState('full_throttle')
end

function state_funcs:state_best_of_the_best(sub)
	local who = self.acting
	local roll = self.roll_result
	self.roll_result = nil
	local space = who:FindSpaceSector()
	local n = math.max(0, (space.raider - roll) or 0)
	local destroyed = space.raider - n
	space.raider = n
	self:ResultLog('%d raiders are destroyed', destroyed)
	self:PopState('best_of_the_best')
end

function state_funcs:state_damage_choice(sub)
	if not sub.list_chosen then
		local list = self:GetShipDamageTokens('galactica')
		while #list > sub.choice do
			table.remove_random(list)
		end
		sub.list_chosen = list
		sub.who:PrivateMsg('Choices:')
		for k,v in ipairs(list) do
			sub.who:PrivateMsg(v)
		end
	end
	while sub.qty > 0 do
		local choice = sub.who:Choice(sub.list_chosen, 'damage which?', true)
		for k,v in pairs(sub.list_chosen) do
			if v == choice then table.remove(sub.list_chosen, k) break end
		end
		self:DamageLocation(choice)
		sub.qty = sub.qty - 1
	end
	self:PopState('damage_choice')
end

function state_funcs:state_human_fleet(sub)
	if not sub.scouted then
		sub.scouted = true
		self:PushState('launch_scout_effect', {})
		return
	end
	if not sub.choice then sub.choice = self.current:Choice({'infiltrate', 'draw'}, 'human fleet option') end

	if not sub.primary then
		sub.primary = true
		if sub.choice == 'infiltrate' then
			self:PopState('pre_crisis')
			self:PushState('activate_cylon_ships')
			self:PushState('pre_crisis')
			self:PushState('movement', {infiltrate=true})
		else
			self:Resolve({card_draws={current={any=2},}})
		end
	end
	
	self:PopState('human_fleet')
end

function state_funcs:state_executive_order(sub)
	if not sub.who then
		sub.who = self.acting:Choice(self:FilterPlayers({'human','!current'}), 'XO who?')
	end
	
	if not sub.exec then
		sub.previous = self.acting
		sub.exec = sub.who:Choice({'move','action'}, 'move or 2x action?')
		self.acting = sub.who
		self:PushState('action', {require_human = true})
		if sub.exec == 'move' then
			self:PushState('movement', {restricted = true})
		elseif sub.exec == 'action' then
			self:PushState('action', {require_human = true})
		end
		return
	end
	
	self.acting = sub.previous or self.current
	
	if self.acting.name == 'Lee "Apollo" Adama (alt)' then
		-- Daybreak Lee can activate his location following XO
		if self.acting.location.action and self.acting:Choice({'y','n'}, 'activate location?') == 'y' then
			self:PushState('resolve_effects', {effect=self.acting.location.action, source='location', specific=self.acting.location.name})
		end
	end
	self:PopState('executive_order')
end

function state_funcs:state_nilify(sub)
	self[sub.k] = nil
	self:PopState()
end

function state_funcs:state_action_end()
	self.turn_progress = self.state
	if self.current.name == 'Louanne "Kat" Katraine' and self.current.location.name == self.turn_flags.katraine_starting_location then
		self:ResultLog('Kat has not moved and is sent to sickbay')
		self.current:MoveTo('Sickbay')
	end
	self:PopState()
end

function state_funcs:state_pre_crisis(sub)
	self.crisis_flags = {}
	self:ChangeState('post_crisis')
	if (sub and sub.always_resolve) or self.current.location and self.current.location.name ~= 'Brig' and not self.current:Cylon() then
		self:PushState('crisis', {crisis = (sub and sub.crisis)})
	end
end

function state_funcs:state_mutiny_discard(sub)
	local n = sub.to
	local who = sub.who
	while #who.mutiny_hand > n do
		local choices = {}
		for k,v in ipairs(who.mutiny_hand) do
			print(sfmt('%d - %s\n', k, find_mutiny(v).desc))
			tins(choices, k)
		end
		local which = who:Choice(choices, 'discard which?')
		local t = find_mutiny(who.mutiny_hand[which])
		table.remove(who.mutiny_hand, which)
		self:ResultLog('%s discards %s', who:full_name(true), t.desc)
	end
	self:PopState()
end

function state_funcs:state_post_crisis()
	self.crisis_flags = {}
	if self.flags.new_crisis then
		self.turn_flags.new_crisis = nil
		self:ChangeState('pre_crisis')
	else
		self:PopState()
	end
end

	--[[
See http://boardgamegeek.com/wiki/page/Battlestar_Galactica_FAQ#toc18
Q: How exactly is the timing of the interactions of character abilities, skill check abilities, and interrupts during the handling of a crisis? (thread)
A: The sequence of events is as follows:

1. Draw Crisis Card, taking into account Roslin's "Religious Visions"
2. Read Crisis Card
3. Starbuck’s "Secret Destiny"
4. Baltar’s "Delusional Intuition"
5. Current Player Chooses, taking into account Tory's "Amoral"
6. Helo’s "Moral Compass"
7. Boomer’s "Mysterious Intuition"
8. Political Prowess
9. Dee's "Fast Learner" (if she decides to add the cards to the skill check, set them aside for the moment), Chief of Staff, Arbitrator, Cylon Hatred, Friends in Low Places, Investigative Committee, Scientific Research, and/or one reckless interrupt (Support the People, At Any Cost, Guts & Initiative, Jury Rigged)
10. Destiny
11. Add Dee’s "Fast Learner" cards to the skill check
12. All players play skill cards into the check, in player order, starting left of the current player (Probation may be triggered by the President)
13. Chief’s "Blind Devotion"
14. Shuffle Cards
15. Reveal Cards
16. Six’s "Human Delusion"
17. Cally’s "Quick Fix"
18. Red Tape, Trust Instincts, Protect the Fleet, Broadcast Location, By Your Command, Special Destiny (order decided by current player)
19. Trigger Consequences
20. Total Strength, taking into account Establish Network and Adama's "Inspirational Leader"
21. Declare Emergency
22. Determine and Process Outcome, taking into account Iron Will
23. Adama’s "Command Authority"
24. Discard Cards
25. Activate Cylon Ships
26. Process FTL Icon
27. Discard Crisis Card
	]]
function state_funcs:state_crisis(sub)
	-- The first seven and last three are specific to crisis cards, the rest are general check stuff
	local current = self.current
	local mission = sub.mission
	if current.name == "William Adama" then
		self.crisis_flags.william_adama_crisis = true
	end
	if not sub.crisis then
		-- Step 1
		--draw one
		if current.name == "Laura Roslin" and not current:Cylon() and not sub.roslin_drew then
			-- Roslin's advantage
			if not sub.roslin_msg_sent then
				sub.roslin_msg_sent = true
				current:PrivateMsg("Religious Visions choice:")
				current:PrivateMsg("%s", get_crisis_by_id(self.crisis_deck[1]).desc)
				current:PrivateMsg("%s", get_crisis_by_id(self.crisis_deck[2]).desc)
				self:ResultLog('Roslin makes her Religious Visions choice')
			end
			
			local choice = current:Choice({'1','2'}, 'religous visions', true)
			sub.crisis = self.crisis_deck[tonumber(choice)]
			table.remove(self.crisis_deck, 1)
			table.remove(self.crisis_deck, 1)
			sub.roslin_drew = true
		else
			sub.crisis = table.remove(self.crisis_deck, 1)
		end
	end
	local crisis = mission and find_mission(sub.crisis) or get_crisis_by_id(sub.crisis) or find_supercrisis(sub.crisis)
	if not sub.crisis_shown then
		-- Step 2
		sub.crisis_shown = true
		if mission then
			self:ResultLog('\n[b]Mission:[/b]\n' .. crisis.desc)
		else
			self:ResultLog('\n[b]Crisis:[/b]\n' .. crisis.desc)
		end
	end
	
	local p = self:FindPlayer('starbuck')
	if not mission and p and not p.opg_used and not sub.starbuck_opg_checked then
		-- Step 3
		local choice = p:Choice({'n','y'}, 'Does starbuck use her OPG?')
		if choice == 'y' then
			p.opg_used = true
			sub.crisis = nil
			sub.crisis_shown = nil
			return
		end
		sub.starbuck_opg_checked = true
	end

	self.current_crisis = crisis.id
	
	if not mission and not sub.activation_added then
		sub.activation_added = true
		if type(crisis.activate) == 'table' then
			for k,v in ipairs(crisis) do
				tins(self.activation_list, v)
			end
		else
			tins(self.activation_list, crisis.activate)
		end
	end
	
	if not mission and current.name == "Gaius Baltar" and not sub.baltar_delusional then
		-- Step 4
		current:DrawCards(1, true)
		sub.baltar_delusional = true
	end
	
	if not mission and not sub.jump_prep_checked then
		sub.jump_prep_checked = true
		if crisis.jump or self.flags.engine_room then
			self.jump_prep = self.jump_prep + 1
		end
	end
	
	if crisis.choice then
		if not mission and crisis.choice == 'current' and current.name == 'Tory Foster' then
			-- Step 5 - Tory's amoral
			self:ResultLog("Tory's disadvantage forces her to choose option A")
			sub.crisis_choice_made = 'a'
		end
		if not sub.crisis_choice_made then
			-- Step 5 - the choice
			local chooser = self[crisis.choice]
			sub.crisis_choice_made = chooser:Choice({'a','b'}, 'crisis choice')
		end
		p = self:FindPlayer('helo')
		if not mission and p and not p.opg_used and not sub.helo_opg_checked and 
			(crisis.choice == "current" or crisis.choice == "president" or
			crisis.choice == "admiral" or crisis.choice == "cag")
		then
			-- Step 6
			local choice = p:Choice({'n','y'}, 'Does Helo reverse the choice')
			if choice == 'y' then
				p.opg_used = true
				local rev = {a='b',b='a'}
				sub.crisis_choice_made = rev[sub.crisis_choice_made]
				self:ResultLog('Helo forces the choice to be %s instead', sub.crisis_choice_made:upper())
			end
			sub.helo_opg_checked = true
		end
		
		self:PopState()
		local result = crisis[sub.crisis_choice_made]
		if result then result = table.copy(result) end
		self:Resolve(result, true)
		return
	elseif crisis.check then
		p = self:FindPlayer('boomer')
		if not mission and p and not p.opg_used and not sub.boomer_opg_checked then
			-- Step 7
			local choice = p:Choice({'n','pass','fail'}, 'Does Boomer force the result?')
			if choice ~= 'n' then
				self:ResultLog('Boomer forces the check to %s', choice)
				p.opg_used = true
				self:PopState()
				self:Resolve(crisis.check[choice], true)
				return
			end
			sub.boomer_opg_checked = true
		end
		self:ChangeState('do_check', {info=crisis.check, consequence=crisis.consequence, mission=mission})
	elseif crisis.attack then
		panic('attack crises unimplemented')
	else
		panic('bad crisis - needs check or choice or attack')
	end
	
end

--[[
8. Political Prowess
9. Dee's "Fast Learner" (if she decides to add the cards to the skill check, set them aside for the moment), Chief of Staff, Arbitrator, Cylon Hatred, Friends in Low Places, Investigative Committee, Scientific Research, and/or one reckless interrupt (Support the People, At Any Cost, Guts & Initiative, Jury Rigged)
10. Destiny
11. Add Dee’s "Fast Learner" cards to the skill check
12. All players play skill cards into the check, in player order, starting left of the current player (Probation may be triggered by the President)
13. Chief’s "Blind Devotion"
14. Shuffle Cards
15. Reveal Cards
16. Six’s "Human Delusion"
17. Cally’s "Quick Fix"
18. Red Tape, Trust Instincts, Protect the Fleet, Broadcast Location, By Your Command, Special Destiny (order decided by current player)
19. Trigger Consequences
20. Total Strength, taking into account Establish Network and Adama's "Inspirational Leader"
21. Declare Emergency
22. Determine and Process Outcome, taking into account Iron Will
23. Adama’s "Command Authority"
24. Discard Cards
]]
function state_funcs:state_do_check(sub)
	local active = self.acting
	local current = self.current
	local mission = sub.mission
	local p
	if not sub.started then
		if not sub.consequence then sub.consequence = sub.info.consequence end
		sub.started = true
		sub.contributions = {}
		sub.contrib_order = self:InContribOrder()
		sub.temp = {}
		sub.contrib_qty = {}
		sub.mod = 0
	end

	if (true or sub.source and sub.source == 'location') and self:CheckForCard('Political Prowess') and not sub.pol_prowess_checked then
		-- Step 8
		-- check for political prowess
		sub.pol_prowess_checked = self:GMChoice({'n','pass','fail'}, 'political prowess played?')
		if sub.pol_prowess_checked ~= 'n' and self:PlayInterrupt('Political Prowess') then
			local result = sub.pol_prowess_checked
			self:PopState()
			self:ResultLog('Political Prowess: %s the check', result)
			self:Resolve(sub.info[result], choice == 'y')
			return
		end
	end

	-- Step 9 - interrupts
	if not mission and not sub.interrups_done then
		sub.interrups_done = self:GetSkillCheckInterrupts(sub)
		return
	end
	
	-- Step 10 - destiny
	if sub.gi then
		self:ResultLog('Guts & Initiative prevents destiny deck contributions')
		sub.last_contrib_qty = 0
	elseif not sub.destiny_added then
		sub.destiny_added = true
		self:ResultLog('Destiny adds two cards')
		tins(sub.contributions, self:DrawDestiny())
		tins(sub.contributions, self:DrawDestiny())
		sub.last_contrib_qty = 2
	end
	
	-- Step 11 - resolve fast learner, if applicable
	if sub.fast_learner_cards then
		for k,v in ipairs(sub.fast_learner_cards) do
			tins(sub.contributions, v)
		end
		sub.fast_learner_cards = nil
	end
	
	-- Step 12 - contributions
	local max_count
	while #sub.contrib_order > 0 do
		local who = sub.contrib_order[1]
		local card
		if max_count == nil then max_count = who:GetCheckMaxContributions() end
		if max_count == nil or max_count > 0 then
			print(sfmt('Contributions for %s/%s\n', who.name, who.player))
			card = who:GetCheckContribution()
		end
		if not card then
			max_count = nil
			table.remove(sub.contrib_order, 1)
			if who.name == 'Callandra "Cally" Tyrol' and #sub.contributions == 1 then
				panic("Cally may only contribute 0, or 2+ cards, not 1")
			end
			if sub.ic then
				if sub.last_contrib_qty < #sub.contributions then
					self:ResultLog('%s contributes:', who:full_name(true))
					for i=sub.last_contrib_qty+1,#sub.contributions do
						self:ResultLog('%s', sub.contributions[i]:formatted())
					end
				end
				sub.last_contrib_qty = #sub.contributions
			end
		else
			if type(max_count) == 'number' then max_count = max_count - 1 end
			tins(sub.contributions, card)
			sub.contrib_qty[who.number] = (sub.contrib_qty[who.number] or 0) + 1
		end
	end
	
	-- Step 13 - chief's opg
	p = self:FindPlayer('chief')
	if not mission and p and not p.opg_used and not sub.chief_opg_checked then
		local choice = p:Choice({'n','lea','tac','pol','pil','eng','tre'}, 'Does the chief use his opg?')
		if choice ~= 'n' then
			p.opg_used = true
			sub.chief_opg_result = choice
		end
		sub.chief_opg_checked = true
	end
	
	-- Step 14/15 - reveal
	if not sub.revealed then
		sub.contributions = sort_card_list(shuffle_list(sub.contributions))
		sub.revealed = true

		self:ResultLog('Contributions:')
		for k,v in ipairs(self:InContribOrder()) do
			local n = sub.contrib_qty[v.number] or 0
			self:ResultLog('%s: %d cards', v:full_name(true), n)
		end
		
		self:ResultLog('\n\n')
		
		for k,v in ipairs(sub.contributions) do
			self:ResultLog('%s', v:formatted())
		end
	end
	
	-- Step 16 - six's opg
	p = self:FindPlayer('Caprica Six')
	if not mission and p and not p.opg_used and not sub.six_opg_checked then
		if p:YN('Does six use her opg?') then
			p.opg_used = true
			sub.six_opg_pending = true
			p:ResultLog('Caprica Six contributes:')
		end
		sub.six_opg_checked = true
	end
	while sub.six_opg_pending do
		local card = p:GetCheckContribution()
		if not card then
			sub.six_opg_pending = nil
			sub.contributions = sort_card_list(shuffle_list(sub.contributions))
			break
		end
		p:ResultLog('%s', card:formatted())
		tins(sub.contributions, card)
	end

	local function remove_card_from_check(card)
		assert(card.orig)
		table.remove_specific(sub.contributions_modified, card)
		for k,v in pairs(sub.contributions_modified) do
			if v.orig > card.orig then v.orig = v.orig - 1 end
		end
		local index = card.orig
		return table.remove(sub.contributions, index)
	end

	if not sub.contributions_modified then
		-- this is a deep copy, we can do whatever we want with these entries
		sub.contributions_modified = table.copy(sub.contributions)
		for k,v in pairs(sub.contributions_modified) do
			v.orig = k
		end
	end
	
	-- Step 17 - cally's advantage
	if not mission and current.name == 'Callandra "Cally" Tyrol' and not sub.cally_removed then
		local card = current:ChooseCardFrom('remove which?', sub.contributions_modified)
		if card then
			self:ResultLog('Cally removes: %s', card:formatted())
			self:ToDiscard(table.remove(sub.contributions, card.orig))
		end
		sub.cally_removed = true
	end
	
	-- Step 18 - resolve card precount effects
	if not sub.precount_done then
		sub.precount_done = true
		local t = setmetatable({}, {__index=sub, __newindex=function(t,k,v)
			if type(v) == 'boolean' and v then
				sub[k] = (sub[k] or 0) + 1
			else
				sub[k] = v
			end
		end})
		for k,v in ipairs(sub.contributions_modified) do
			if v.precount_func then v.precount_func(self, sub.info, t) end
		end
		
		for k,v in ipairs(sub.contributions_modified) do
			if v.skill_check then
				sub.consequence_triggers = true
				break
			end
		end
	end
	
	if mission then sub.precount_resolved = true end
	
	while not sub.precount_resolved do
		local choices = {}
		local function check(v) return v ~= nil and (v == true or v > 0) end
		
		if check(sub.establish_network) then tins(choices, 'network') end
		if check(sub.trust_instincts) then tins(choices, 'instincts') end
		if check(sub.red_tape) then tins(choices, 'red tape') end
		if check(sub.quick_thinking) then tins(choices, 'quick thinking') end
		if check(sub.force_hand) then tins(choices, 'force hand') end
		if check(sub.all_hands) then tins(choices, 'all hands') end
		if check(sub.protect_fleet) then tins(choices, 'protect_fleet') end
		if check(sub.dogfight) then tins(choices, 'dogfight') end
		if check(sub.bait) then tins(choices, 'bait') end
		if check(sub.dradis_contact) then tins(choices, 'dradis contact') end
		if check(sub.better_machine) then tins(choices, 'better machine') end
		if check(sub.personal_vices) then tins(choices, 'personal_vices') end
		if check(sub.violent_outbursts) then tins(choices, 'violent outbursts') end
		if check(sub.exploit_weakness) then tins(choices, 'exploit weakness') end

		if #choices == 0 then sub.precount_resolved = true; break end
		
		local choice = current:Choice(choices, 'skill check eval order')
		if choice == "network" then
			sub.establish_network = nil
			self:ResultLog("Establish Network doubles engineering cards")
			for k,v in pairs(sub.contributions_modified) do
				if v.type == "eng" then
				print("found eng card", v.strength)
					sub.precount_changed = true
					v.mod_strength = v.strength * 2
				end
			end
		elseif choice == 'quick thinking' then
			local chooser = self.current
			local choices = {'q'}
			for k,v in pairs(sub.contributions_modified) do
				if v.strength <= 3 and v.name ~= 'Quick Thinking' then
					tins(choices, v)
				end
			end
			if not sub.quick_thinking_shown then
				local desc, count, result, de = self:GetCheckCount(sub.info, sub, sub.contributions)
				sub.quick_thinking_shown = true
				self:ResultLog('Current count: ' .. desc)
			end
			local card = chooser:Choice(choices, 'quick thinking: remove a card?')
			if card ~= 'q' then
				card = remove_card_from_check(card)
				self:ResultLog('%s takes %s and adds it to his hand', chooser:full_name(true), card:formatted())
				tins(chooser.hand, card)
				if card.precount_func then
					local t = setmetatable({}, {__index=sub, __newindex=function(t,k,v)
						if type(v) == 'boolean' and v then
							local n = sub[k] or 0
							if n == true then n = 1 end
							if n > 0 then n = n - 1 end
							sub[k] = n
						end
					end})
					card.precount_func(self, sub.info, t)
				end
			end
			sub.quick_thinking = nil
			sub.precount_changed = true
		elseif choice == "red tape" then
			sub.red_tape = nil
			local discards = {}
			for k,v in pairs(sub.contributions_modified) do
				if v.strength > 4 then
					self:ResultLog('Red tape discards: %s', v:formatted())
					tins(discards, k)
				end
			end
			for k,v in ipairs(discards) do
				sub.precount_changed = true
				table.remove(sub.contributions_modified, v+1-k)
			end
		elseif choice == "instincts" then
			sub.precount_changed = true
			sub.trust_instincts = nil
			self:ResultLog('Trust instincts contributes')
			local c1, c2 = self:DrawDestiny(), self:DrawDestiny()
			self:ResultLog('%s', c1:formatted())
			self:ResultLog('%s', c2:formatted())
			self:ResultLog('')
			self:ResultLog('')
			
			for _,v in ipairs{c1, c2} do
				tins(sub.contributions, v)
				local copy = table.copy(v)
				copy.orig = #sub.contributions
				tins(sub.contributions_modified, copy)
			end
		elseif choice == "violent outbursts" then
			sub.violent_outbursts = nil
			self:ResultLog('%s is sent to Sickbay', self.current:full_name(true))
			self.current:MoveTo("Sickbay")
		elseif choice == 'all hands' then
			sub.all_hands = nil
			sub.mod = sub.mod or 0
			for k,v in pairs(sub.contributions_modified) do
				if v.strength == 0 then
					sub.mod = sub.mod + 1
				end
			end
		elseif choice == 'exploit weakness' then
			local who = self.current:Choice(self:FilterPlayers('human'), 'mutiny for who')
			who:DrawMutiny()
			sub.exploit_weakness = nil
		elseif choice == 'force hand' then
			if not self.current:Cylon() then
				local card = self.current:GetCheckContribution('Force Their Hand play')
				if card then
					-- add card into check
					-- if skill check, resolve it
					if card.precount_func then card.precount_func(self, sub.info, sub) end
					if card.skill_check then
						sub.consequence_triggers = true
					end
					table.insert(sub.contributions, card)
					table.insert(sub.contributions_modified, table.copy(card))
					sub.contributions_modified[#sub.contributions_modified].orig = #sub.contributions
				else
					self.current:DrawMutiny()
				end
			end
			sub.force_hand = nil
		elseif choice == 'protect_fleet' then
			local n = 0
			for k,v in pairs(sub.contributions) do
				if v.type == 'pil' then n = n + v.strength end
			end
			sub.protect_fleet = nil
			if n > 3 then
				self:PushState('viper_activations', {qty=1})
				return
			end
		elseif choice == 'dogfight' then
			if self.current:Choice({'y','n'}, 'damage viper to remove a card?') == 'y' then
				self:Resolve{damage_vipers=1}

				local chooser = self.current
				local choices = {}
				for k,v in pairs(sub.contributions_modified) do
					tins(choices, v)
				end
				local card = chooser:Choice(choices, 'dogfight: remove a card')
				card = remove_card_from_check(card)
				self:ToDiscard(card)
				self:ResultLog('%s removes %s from the skill check', chooser:full_name(true), card:formatted())
				if card.precount_func then
					local t = setmetatable({}, {__index=sub, __newindex=function(t,k,v)
						if type(v) == 'boolean' and v then
							local n = sub[k] or 0
							if n == true then n = 1 end
							if n > 0 then n = n - 1 end
							sub[k] = n
						end
					end})
					card.precount_func(self, sub.info, t)
				end
				sub.precount_changed = true
			end
			sub.dogfight = nil
		elseif choice == 'bait' then
			sub.bait = nil
			self:DeployShips('civ', 1, 'rear')
		elseif choice == 'dradis contact' then
			sub.dradis_contact = nil
			self:DeployShips('raider', 2, 'front')
		elseif choice == 'better machine' then
			for i=1,2 do
				table.insert(self.destiny_deck, self.skill_decks.tre:draw_top())
			end
			self:ResultLog('2 treachery cards are shuffled into the destiny deck (now %d cards)', #self.destiny_deck)
			self.destiny_deck = shuffle_list(self.destiny_deck)
			sub.better_machine = nil
		elseif choice == 'personal_vices' then
			if not self.current:Cylon() then
				self.current:DrawMutiny()
			end
			for k,v in ipairs(self:FilterPlayers('human')) do
				v:DrawSpecificCards{tre=1}
			end
			sub.personal_vices = nil
		else
			panic()
		end
	end
	print('A')
	
	if not mission and sub.chief_opg_result then
		self:ResultLog("Chief Tyrol's OPG negates all %s cards", names[sub.chief_opg_result])
		for k,v in ipairs(sub.contributions_modified) do
			if v.type == sub.chief_opg_result then
				sub.precount_changed = true
				v.mod_strength = 0
			end
		end
	end
	
	-- Step 19 - consequences
	if not mission and sub.consequence and sub.consequence_triggers then
		self:ResultLog('Consequence triggers!')
		self:Resolve(sub.consequence, true)
		sub.consequence = nil
		return --evaluate
	end
	
	-- Step 20 - count
	if sub.precount_changed then
		sub.precount_changed = nil
		-- things got changed, so re-dump everything
		for k,v in ipairs(sub.contributions) do
			self:ResultLog('%s', v:formatted())
		end
	end

	if not sub.count_shown then
		sub.count_shown = true
		local desc, count, result, de, mod_total = self:GetCheckCount(sub.info, sub, sub.contributions_modified)
		sub.declare_emergency_useful = de or (sub.iron_will and mod_total >= -6 and mod_total <= -5)
		self:ResultLog('%s', desc)
		sub.full_count = count
		sub.mod_total = mod_total
		sub.result = result
		if count < 0 and self.exodus and not self.daybreak and not self.no_automatic_reckless_variant then
			sub.reckless = true
			self:ResultLog('Check is now RECKLESS due to total being negative')
		end
	end
	
	-- Step 21 - declare emergency
	if not mission and sub.declare_emergency_useful and not sub.de_checked and self:CheckForCard('Declare Emergency') then
		-- check for DE
		if self:GMChoice({'n','y'}, 'DE played?') == 'y' then
			if self:PlayInterrupt('Declare Emergency') then
				sub.mod_total = sub.mod_total + 2
				if sub.mod_total >= 0 then
					sub.result = 'pass'
				end
			end
		end
		sub.de_checked = true
	end
	
	if sub.iron_will and sub.mod_total >= -4 then
		sub.iron_will_activates = true
	end
	
	if sub.install_upgrades then
		sub.install_upgrades = nil
		local n = (sub.result == 'pass' and 2) or 1
		self.current:DrawSpecificCards{eng=n}
	end
	
	-- Resolve reckless
	if sub.reckless then
		if not sub.reckless_resolved then sub.reckless_resolved = {} end
		local t = sub.reckless_resolved
		for k,v in ipairs(sub.contributions_modified) do
			if not t[v.name] then
				t[v.name] = true
				if v.name == "Broadcast Location" then
					-- place basestar & civvie
					self:ResultLog('Broadcast Location activates')
					self:DeployShips('basestar', 1, 'front')
					self:DeployShips('civ', 1, 'rear')
				elseif v.name == "By Your Command" then
					-- activate stuff
					self:ResultLog('By Your Command activates')
					self.dont_activate_centurion = true
					self:ActivateCylonShip('raider')
					self:ActivateCylonShip('heavy')
				elseif v.name == "Special Destiny" then
					-- draw treachery
					self:ResultLog('Special Destiny activates')
					for i,j in ipairs(self.players) do
						j:DrawSpecificCards({tre=1})
					end
				end
			end
		end
		sub.reckless = nil
		return
	end
	
	-- Step 22 - resolve effects
	if not sub.done_resolution then
		local result = sub.info[sub.result]
		if result then result = table.copy(result) end
		self:ResultLog('Check result is [b]%s[/b]', sub.result)
		if not mission and sub.result == 'pass' and self:CheckForCard('Change Of Plans') then
			if self:GMChoice({'n','y'}, 'Change of plans played?') == 'y' then
				if self:PlayInterrupt('Change Of Plans') then
					self:ResultLog('All human players draw two cards')
					self:Resolve({draw_cards={human=2}})
					sub.done_resolution = true
					return
				end
			end
		end
		sub.done_resolution = true
		if sub.result == 'fail' and sub.iron_will_activates then
			self:ResultLog('Iron Will negates the fail effect')
		else
			self:Resolve(result, true)
		end
		return
	end
	
	-- Step 23 - adama's opg
	p = self:FindPlayer('adama')
	if not mission and p and not p.opg_used and not sub.adama_opg_checked then
		if p:YN('Does adama use his opg?') then
			self:ResultLog('%s draws all the cards to his hand', p:full_name())
			p.opg_used = true
			for k,v in ipairs(sub.contributions_modified) do
				tins(p.hand, sub.contributions[v.orig])
			end
			sub.contributions_modified = {}
		end
		sub.adama_opg_checked = true
	end
	
	-- Step 24 - discard any remaining contributions
	for k,v in ipairs(sub.contributions_modified) do
		self:ToDiscard(setmetatable({strength=v.strength}, {__index=find_card(v.name)}))
	end
	
	self:PopState()
	self:ResultLog('Done')
end

function state_funcs:state_resolve_effects(sub)
	assert(sub)
	if not sub.effect then
		self:ResultLog('No effect')
		self:PopState()
		return
	end
	if self:ResolveEffectsInternal(sub) then
		self:PopState()
	end
end

function state_funcs:state_activate_raiders(sub)
	if not sub.init then
		sub.n = sub.source.raider
		sub.init = true
	end

	if sub.n > 0 then
		self:ActivateRaider(self.space[sub.where], sub.where)
		sub.n = sub.n - 1
	else
		self:PopState()
	end
end

function state_funcs:ActivateCenturions()
	if self.dont_activate_centurion then
		self.dont_activate_centurion = nil
	else
		-- activate centurions
		if self.boarding_track[4] > 0 then
			panic()
		end
		self.boarding_track[4] = self.boarding_track[3]
		self.boarding_track[3] = self.boarding_track[2]
		self.boarding_track[2] = self.boarding_track[1]
		self.boarding_track[1] = 0
	end
end

function state_funcs:state_activate_heavies(sub)
	-- activate heavy raiders
	local next = {
		front = 'pbow', sbow = 'front', saft = 'rear', rear = 'paft'
	}
	local loc_next = next[sub.where]
	local n = sub.source.heavy
	if loc_next and n then
		self.space[loc_next].heavy = (self.space[loc_next].heavy or 0) + n
		self.space[sub.where].heavy = self.space[sub.where].heavy - n
	elseif n then
		self:ResultLog('%d centurions have boarded Galactica!', n)
		self.boarding_track[1] = self.boarding_track[1] + n
		self.space[sub.where].heavy = self.space[sub.where].heavy - n
	end
	self:PopState()
end

function state_funcs:state_do_roll(sub)
	local why = sub.why
	if not sub.d8 then
		if not sub.mod then sub.mod = 0 end
		self.roll_result = nil
		sub.d8 = self:d8()
		sub.interrupt_checked = self:CheckForCard('Strategic Planning') or self:CheckForCard('Calculations')
	end
	if not sub.sp_checked and self:CheckForCard('Strategic Planning') then
		if self:GMChoice({'n','y'}, 'SP played?') == 'y' then
			local card = self:PlayInterrupt('Strategic Planning')
			if card then
				self:ResultLog('Strategic planning is played')
				sub.mod = (sub.mod or 0) + 2
			end
		end
		sub.sp_checked = true
	end
	if not sub.displayed then
		-- clip this to 1-8
		if global_enable_roll_override then
			local override = self:GMChoice({'q',1,2,3,4,5,6,7,8}, 'override roll')
			if override ~= 'q' then sub.d8 = override end
		end

		sub.total = sub.d8 + sub.mod
		if sub.total > 8 then sub.total = 8 end
		if sub.total < 1 then sub.total = 1 end
		
		if sub.mod and sub.mod > 0 then
			self:ResultLog('1d8 + %d = %d + %d = %d', sub.mod, sub.d8, sub.mod, sub.total)
		elseif sub.mod and sub.mod > 0 then
			self:ResultLog('1d8 - %d = %d - %d = %d', -sub.mod, sub.d8, -sub.mod, sub.total)
		else
			self:ResultLog('1d8 = %d', sub.d8)
		end
	end
	if not sub.calc_checked and self:CheckForCard('Calculations') then
		sub.calc_checked = true
		if self:GMChoice({'n','y'}, 'Calc played?') == 'y' then
			local card, who = self:PlayInterrupt('Calculations')
			if card then
				local choice = who:Choice({'+','-'}, 'calculations effect')
				if choice == '-' then sub.mod = sub.mod - 1 end
				if choice == '+' then sub.mod = sub.mod + 1 end
				sub.total = sub.d8 + sub.mod
				if sub.total > 8 then sub.total = 8 end
				if sub.total < 1 then sub.total = 1 end
			end
		end
	end
	
	self.roll_result = sub.total
	print("roll = %d\n", self.roll_result)
	--self:ResultLog('Roll result: %d', self.roll_result)
	self:PopState()
end

function state_funcs:state_increase_pursuit(sub)
	local n = self.pursuit_track + 1
	local t = {
		'Level 1 - Deploy 1 Civilian.',
		'Level 2 - No Effect.',
		'Level 3 - Deploy 2 Civilians.',
		'Level 4 - Cylons Jump In.',
	}
	self:ResultLog('Pursuit Track increases to %s\n', t[n])
	if n == 1 then
		self:DeployShips('civ', 1)
	elseif n == 3 then
		self:DeployShips('civ', 2)
	elseif n == 4 then
		n = 0
		for k,v in pairs(self.cylon_fleet_board) do
			self:CylonJumpsIn(k)
		end
	end
	self.pursuit_track = n
	self:PopState('increase_pursuit')
end

function state_funcs:state_placement_cylon_fleet_board(sub)
	local cfb_rolls = {
		'rear', 'paft', 'saft', 'pbow', 'sbow', 'sbow', 'front', 'front'
	}
	if self.maximums[sub.what] then
		local max = self.maximums[sub.what]
		local n = 0
		for k,v in pairs({self.space, self.cylon_fleet_board}) do
			for i,j in pairs(v) do
				local t = j[sub.what] or 0
				if type(t) == 'table' then t = #t end
				n = n + t
			end
		end
		if n == max then
			self:ResultLog('Cannot place a %s - too many already exist', names[sub.what])
			for i = #cfb_rolls, 1, -1 do
				local where = cfb_rolls[i]
				local t = self.cylon_fleet_board[where][sub.what]
				if (type(t) == 'number' and t > 0) or (type(t) == 'table' and #t > 0) then
					self:ResultLog('CFB sector %s jumps in', names[where])
					self:CylonJumpsIn(where)
					break
				end
			end
			self.roll_result = nil
			self:PopState()
			return
		end
	end
	
	local result = self.roll_result
	local where = cfb_rolls[result]
	self.roll_result = nil
	self:ResultLog('Roll for CFB placement: %d -> %s', result, names[where])
	self:DeployShips(sub.what, 1, where, true)
	self:PopState()
end

function state_funcs:state_damage(sub)
	if not sub.ship or sub.ship == 'choice' then
		local choices = {'galactica'}
		if self.pegasus and not self.pegasus_destroyed then
			tins(choices, 'pegasus')
		end
		sub.ship = self.current:Choice(choices, 'galactica or pegasus?')
	end
	if sub.ship == 'galactica' or sub.ship == 'pegasus' then
		local t = self:GetShipDamageTokens(sub.ship)
		
		if #t == 0 and sub.ship == 'galactica' then
			self:PushState('cylon_win', 'damage')
			return
		end
		
		local v = t[math.random(#t)]
		self:DamageLocation(v)
		
	elseif sub.ship == 'basestar' then
		if not self.space[sub.area].basestar or #self.space[sub.area].basestar == 0 then return self:PopState('damage') end
		if not sub.specific and #self.space[sub.area].basestar == 2 then
			sub.specific = self.current:Choice({1,2}, 'which basestar?')
		else
			sub.specific = 1
		end


		-- do basestar damage
		-- first, figure out what tokens are left
		local tokens = self:BasestarDamageTokens()
		local basestar = self.space[sub.area].basestar[sub.specific]
		local destroyed = false
		if #basestar == 2 or basestar[1] == 'Critical Hit' then
			destroyed = true
		else
			local token = table.remove_random(tokens)
			self:ResultLog('Basestar takes damage: %s', token)
			table.insert(basestar, token)
			if token == 'Collateral Damage' then
				if self.space[sub.area].raider >= 3 then
					self:ResultLog("3 raiders are destroyed")
					self.space[sub.area].raider = self.space[sub.area].raider - 3
				elseif self.space[sub.area].raider > 0 then
					self:ResultLog("%d raiders are destroyed", self.space[sub.area].raider)
					self.space[sub.area].raider = 0
				end
			elseif token == 'Draw Trauma' then
				panic()
			elseif token == 'Critical Hit' and #basestar > 0 then
				destroyed = true
			end
		end
		if destroyed then
			self:ResultLog('The basestar is destroyed!')
			self:PushState('major_victory_check')
			table.remove(self.space[sub.area].basestar, sub.specific)
		end
	else
		panic()
	end
	if sub.qty == 1 or sub.qty == nil then
		self:PopState('damage')
	else
		sub.qty = sub.qty - 1
	end
end

function state_funcs:state_resolve_attack(sub)
	local who = sub.acting or self.current
	if not sub.init then
		sub.init = true
	end
	if sub.target == 'basestar' and not sub.area then
		local choices = {}
		for k,v in pairs(self.space) do
			if v.basestar and #v.basestar > 0 then tins(choices, k) end
		end
		sub.area = who:Choice(choices, 'which location?')
		sub.desc = 'Basestar'
	end

	if sub.target == 'choice' then
		if sub.by == 'basestar' then
--			sub.target = who:Choice({'galactica','pegasus'}, sub.desc)
--			sub.desc = sub.desc .. (names[sub.target] or sub.target)
		else
			local choices = {}
			for k,v in pairs(self.space) do
				if (v.basestar and #v.basestar > 0) or (v.raider or 0) + (v.heavy or 0) + (v.scar or 0) > 0 then
					tins(choices, k)
				end
			end
			local area = who:Choice(choices, 'galcatica attacks where?')
			local space = self.space[area]
			choices = {}
			if space.basestar and #space.basestar > 0 then tins(choices, 'basestar') end
			if space.raider and space.raider > 0 then tins(choices, 'raider') end
			if space.heavy and space.heavy > 0 then tins(choices, 'heavy') end
			local choice = who:Choice(choices, 'galactica attacks what?')
			sub.target = choice
			sub.area = area
			sub.desc = 'Galactica attacks ' .. names[choice]
		end
	end
	if sub.target == 'basestar' then
		-- if there are two basestars in the same sector, differentiate them
		local basestars = self.space[sub.area].basestar
		local chosen = 1
		if #basestars > 1 then
			if #basestars[1] == 0 and #basestars[2] == 0 then
				chosen = 1
			else
				panic()
			end
		end
		sub.specific = chosen
		
		if self:BasestarHasDamage(basestars[chosen], 'Structural Damage') and not sub.structural_damage then
			self:ResultLog('Structural Damage adds +2 to the roll!')
			sub.structural_damage = true
			sub.mod = (sub.mod or 0) + 2
		end
	end
	if self.roll_result then
		sub.roll = self.roll_result
		self.roll_result = nil
	elseif not sub.roll then
		self:PushState('do_roll', {why=sub.desc, mod=sub.mod})
		return
	end
	local attack_table = {
		raider = 3,
		heavy = 7,
		centurion = 7,
		basestar = {viper=8, galactica=5, pegasus=4},
		viper = 5,
		viper7 = 6,
		araptor = 7,
		choice = {raider=8, basestar=4},
		galactica = {raider=8, basestar=4},
		pegasus = {raider=8, basestar=4},
	}
	local function checkishit(attacker, target, roll)
		local t = attack_table[target]
		if type(t) == 'table' then t = t[attacker] end
		return roll >= t
	end
	local ishit = checkishit(sub.by, sub.target, sub.roll)
	local desc = sub.desc
	
	if sub.pilot then
		desc = desc .. ' piloted by ' .. sub.pilot:full_name(not ishit)
	end
	
	local space = self.space[sub.area]
	if ishit and sub.by == 'raider' and (sub.target == 'viper' or sub.target == 'viper7' or sub.target == 'araptor') then
		-- successful raider -> viper attack, check for evasive maneuvers
		self:ResultLog('%s: hit!', desc)

		if self:CheckPlayInterrupt('Evasive Maneuvers') then
			sub.mod = self:GMChoice({0,-2},'modifier')
			sub.roll = nil
			return
		else
			space[sub.target] = space[sub.target] - 1
			local result = 'destroyed'
			if sub.roll < 8 and sub.target ~= 'araptor' then
				result = 'damaged'
				local n = 'damaged_' .. sub.target
				self[n] = (self[n] or 0) + 1
			end
			local pilot = sub.pilot
			self:ResultLog('%s: %s!', desc, result)
			
			if pilot then
				self:ResultLog('%s is sent to Sickay', pilot:full_name())
				pilot:MoveTo('Sickbay')
			end
			for k,v in pairs(space.pilots or {}) do
				if v.who == pilot then table.remove(space.pilots, k) break end
			end
		end
	elseif ishit then
		-- attack successful!
		self:ResultLog('%s: hit!', desc)
		if sub.target == 'basestar' or sub.target == 'choice' then
			self:PushState('damage', {ship=sub.target, area=sub.area, specific = sub.specific})
			if sub.by == 'pegasus' and sub.roll >= 7 then
				self:PushState('damage', {ship=sub.target, area=sub.area, specific = sub.specific})
			end
		else
			space[sub.target] = space[sub.target] - 1
		end
	else
		self:ResultLog('%s: miss!', desc)
		if sub.by == 'pegasus' then
			self:PushState('damage', {ship='pegasus'})
		end
	end
	self:PopState('resolve_attack')
end

function state_funcs:DrawSkillCard(type)
	return self.skill_decks[type]:draw_top()
end

function state_funcs:state_memento_effect(sub)
	-- can only happen once per turn
	if self.memento_turn == self.turn then self:PopState() return end
	local hotdog = self:FindPlayer('hotdog')
	if not sub.cards then
		self:ResultLog("Hotdog's memento ability activates")
		local c = {self:DrawSkillCard('pil'), self:DrawSkillCard('pil'), self:DrawSkillCard('pil')}
		local msg = string.format('Memento draw:\n%s\n%s\n%s', c[1]:formatted(), c[2]:formatted(), c[3]:formatted())
		hotdog:PrivateMsg(msg)
		sub.cards = c
	end

	local card = hotdog:ChooseCardFrom('memento #1', sub.cards)
	if card then tins(hotdog.hand, card) end
	card = hotdog:ChooseCardFrom('memento #2', sub.cards)
	if card then tins(hotdog.hand, card) end

	self:ToDiscard(sub.cards)
	self.memento_turn = self.turn
	self:PopState()
end

function state_funcs:state_activate_basestars(sub)
	local n = #sub.source.basestar
	self:PopState()
	for i=1,n do
		local t = sub.source.basestar[i]
		if not self:BasestarHasDamage(t, 'Weapons Disabled') then
			self:PushState('resolve_attack', {desc='Basestar attacks ', by='basestar', target='choice'})
		end
	end
end

function state_funcs:state_activate_launch(sub)
	local n = 0
	for i=1,#sub.source.basestar do
		local t = sub.source.basestar[i]
		if not self:BasestarHasDamage(t, 'Hangar Disabled') then
			n = n + 3
		end
	end
	self:ResultLog('Basestars launch raiders')
	self:PopState()
	if n > 0 then
		self:DeployShips('raider', n, sub.where)
	end
end

function state_funcs:state_activate_cylon_specific(substate)
	local lookup = {activate_raiders = 'raider', activate_heavies = 'heavy', activate_basestars = 'basestar', activate_launch = 'basestar'}
	local unit = lookup[substate.next]
	local real_choices = {}
	for k,v in pairs(substate.left) do
		local val = substate.source[v][unit]
		if val then
			if (type(val) == 'number' and val > 0) or (type(val) == 'table' and #val > 0) then
				table.insert(real_choices, v)
			end
		end
	end
	
	if #real_choices == 0 then
		self:PopState()
		if self.cylon_fleet and not substate.activated_something then
			-- activation without anything on the board
			self:NoShipsToActivate(substate.next, unit)
		end
		return
	end
	local choice
	if unit == 'raider' then
		choice = self.current:Choice(real_choices, 'activation order')
	else
		-- since there's nothing to really choose for the others, automate it
		choice = real_choices[1]
	end
	for k,v in pairs(substate.left) do if v == choice then table.remove(substate.left, k) break end end
	
	substate.activated_something = true
	self:PushState(substate.next, {source=substate.source[choice], where=choice})
end

function state_funcs:ActivateCylonShip(t)
	local lookup = {
		raiders = "activate_raiders",
		raider = "activate_raiders",
		heavy = "activate_heavies",
		basestar = "activate_basestars",
		basestars = "activate_basestars",
		["launch raiders"] = "activate_launch",
		launch = "activate_launch",
	}
	if not lookup[t] then
		panic("cylon activation: '%s' unknown", t)
	end
	if lookup[t] == 'activate_heavies' then
		self:ActivateCenturions()
	end
	self:PushState('activate_cylon_specific', {source=table.copy(self.space, 2), next=lookup[t], left={'front', 'rear', 'pbow', 'paft', 'sbow', 'saft'}})
end

function state_funcs:state_activate_cylon_ships(substate)
	self.turn_progress = self.state
	if #self.activation_list > 0 then
		local t = table.remove(self.activation_list, 1)
		self:ActivateCylonShip(t)
	else
		self:PopState()
	end
end

function state_funcs:state_draw_mutiny(s)
	s.who:DrawMutiny()
end

function state_funcs:state_jump_prep(sub)
	if self.jump_prep > 0 and self.current == self.mutineer then
		self.current:DrawMutiny()
	end
	while self.jump_prep > 0 do
		self.jump_track = self.jump_track + 1
		self.jump_prep = self.jump_prep - 1
		self:ResultLog('Jump track increases to %s', jump_desc(self.jump_track))
		if self.jump_track == 5 then
			self:PushState('jump', {})
			return
		end
	end
	self:PopState('jump_prep')
end

function state_funcs:state_jump(sub)
	local goals = {kobol = 8, ionian = 8, earth = 10}
	if self.disance == goals[self.goal] then
		self:PushState('human_win')
		return
	end
	
	if self.current_mission then
		if self.current_mission_facedown then
			self.current_mission_facedown = nil
			self.mission_deck:place_top(self.current_mission)
			self.mission_deck:shuffle()
		end
		self.current_mission = nil
	end
	
	local who, qty
	if sub.blind_jump then
		qty = 1
		who = self.admiral
	elseif self.mission_specialist then
		qty = 3
		who = self.mission_specialist
	else
		qty = 2
		who = self.admiral
	end
	
	if not sub.sent then
		sub.sent = true
		local destinations = {}
		for i=1,qty do
			tins(destinations, table.remove(self.destination_deck, 1))
		end
		sub.destinations = destinations
		for i=1,qty do
			local d = find_destination(destinations[i])
			who:PrivateMsg('%s - %d Distance, %s', d.name, d.effect.distance, d.text)
		end
	end
	
	local choice = who:Choice(sub.destinations, 'destination choice')
	local d = find_destination(choice)
	if self.jump_track > 5 then
		self.jump_track = self.jump_track - 5
	else
		self.jump_track = 0
	end
	self:PopState()
	self:Resolve(d.effect)
	
	self:ResultLog('%s receives %d destination cards', who:full_name(true), qty)
	self:ResultLog('Chosen destination: %s - %d Distance, %s', d.name, d.effect.distance, d.text)
	
	local notlanding_pilots = {}
	for k,v in pairs(self.space) do
		for i,j in pairs(v.pilots or {}) do
			if j.what == 'araptor' then
				if j.who:Choice({'y','n'}, 'stay in space?') == 'y' then
					notlanding_pilots[j.who] = true
				end
			end
		end
	end
	
	-- land all pilots
	for k,v in ipairs(self.players) do
		if v.location.ship == 'viper' and not notlanding_pilots[v] then
			v:MoveTo('Hangar Deck')
		end
	end
	
	-- clear the board
	for k,v in pairs(self.space) do
		if self.cylon_fleet then
			local cfb = self.cylon_fleet_board[k]
			
			-- move all cylon ships to the cfb
			cfb.raider = (v.raider or 0) + (cfb.raider or 0)
			cfb.heavy = (v.heavy or 0) + (cfb.heavy or 0)
			cfb.scar = (v.scar or 0) + (cfb.scar or 0)
			cfb.basestar = cfb.basestar or {}
			for i,j in pairs(v.basestar or {}) do
				tins(cfb.basestar, j)
			end
		else
			-- clear any civvies
			panic()
		end
		
		v.raider = nil
		v.heavy = nil
		v.scar = nil
		v.basestar = nil
		
		-- land all vipers
		if v.viper then self.viper = self.viper + v.viper end
		if v.viper7 then self.viper7 = self.viper7 + v.viper7 end
		v.viper = nil
		v.viper7 = nil
	end
end

function state_funcs:state_activate_caprica(sub)
	local who = self.acting
	
	if not sub.sc_choice then
		local choices = {'crisis'}
		if who.supercrisis_hand and #who.supercrisis_hand > 0 then tins(choices, 'super') end
		local choice = who:Choice(choices, 'play SC or draw crisis?')
		sub.sc_choice = true
		sub[choice] = true
	end
	
	if sub.super then
		local super = who.supercrisis_hand[1]
		self:ChangeState('pre_crisis', {crisis=super, always_resolve=true})
		return
	end
	
	if sub.crisis then
		if not sub.shown then
			local c1 = self.crisis_deck[1]
			local c2 = self.crisis_deck[2]
			who:PrivateMsg('Crisis 1: %s\n\n', get_crisis_by_id(c1).desc)
			who:PrivateMsg('Crisis 2: %s\n', get_crisis_by_id(c2).desc)
			sub.shown = true
		end
		
		local choice = who:Choice({1,2}, 'Play which?')
		local id = self.crisis_deck[choice]
		table.remove(self.crisis_deck, 1)
		table.remove(self.crisis_deck, 1)
		self:ChangeState('pre_crisis', {crisis=id, always_resolve=true})
	end
end

function state_funcs:state_combat_veteran(sub)
	if sub.n > 0 then
		if sub.who:Choice({'n','y'}, 'stop early?') == 'n' then
			sub.n = sub.n - 1
			self:PushState('viper_activations', {qty=1})
			return
		end
	end
	self:PopState()
end

function state_funcs:maximum_firepower(sub)
end

function state_funcs:state_viper_activations(sub)
	if sub.qty > 0 and not sub.t then
		local choices = {}
		if self.viper > 0 or self.viper7 > 0 or self.araptor > 0 then
			choices = {'launch pbow','launch paft'}
		end
		for k,v in pairs(self.space) do
			local nvipers = (v.viper or 0) + (v.viper7 or 0) + (v.araptor or 0)
			local npilots = (v.pilots and #v.pilots) or 0
			if nvipers > npilots then
				tins(choices, k)
			end
		end
		if #choices == 0 then
			self:ResultLog('No unmanned or reserve vipers, activations are lost')
			sub.qty = 0
			return
		end
		local choice = self.acting:Choice(choices, 'which sector?')
		if choice == 'launch pbow' then
			self:LaunchViper('pbow')
			sub.qty = sub.qty - 1
			return
		elseif choice == 'launch paft' then
			self:LaunchViper('paft')
			sub.qty = sub.qty - 1
			return
		else
			sub.t = self.space[choice]
		end
	end
	
	if sub.qty > 0 then
		self:ViperActivation(sub.t, false, false, sub.shootonly)
		sub.qty = sub.qty - 1
		--sub.t = nil
	else
		self:PopState('viper_activations')
	end
end

function state_funcs:state_destroy_civs(s)
	while s.qty > 0 do
		local civ
		if #self.civ > 0 then
			self:ResultLog('A civilian ship is destroyed')
			civ = table.remove_random(self.civ)
		else
			panic()
		end
		if not civ then panic() end
		s.qty = s.qty - 1
		for k,v in pairs(civ) do civ[k] = -v end
		self:Resolve(civ)
		return
	end
	self:PopState()
end

function state_funcs:state_make_choice(s)
	local who = self[s.choice]
	assert(who)
	
	local mapping = s.mapping or {a='a',b='b'}
	local desc = s.desc or {a='Option A',b='Option B'}
	local descstr = desc.a .. ' or ' .. desc.b

	local choice = who:Choice({mapping.a, mapping.b}, descstr)
	local result
	if choice == mapping.a then result = s.a
	elseif choice == mapping.b then result = s.b
	else panic() end
	
	self:PopState()
	self:Resolve(result)
end

function state_funcs:state_communications_effect(s)
	if not s.list then
		s.list = {}
		s.chosen = {}
		for _,sector in pairs(self.space) do
			for _,civ in pairs(sector.civ or {}) do
				table.insert(s.list, civ)
			end
		end
	end
	if s.qty == nil then
		s.qty = 2
		if s.who.name == 'Anastasia "Dee" Dualla' then
			s.qty = #s.list
		end
	end
	while s.qty > 0 do
		local letter, desc
		local choices = {}
		for _,v in pairs(s.list) do tins(choices, v.label) end
		letter = s.who:Choice(choices, 'which civ?')
		table.insert(s.chosen, letter)
		for i,v in pairs(s.list) do
			if v.label == letter then
				table.remove(s.list, i)

				desc = self:DescribeCiv(v)
				break
			end
		end
		s.who:PrivateMsg('%s - %s', letter, desc)
		s.qty = s.qty - 1
	end
	while #s.chosen > 0 do
		local letter = s.chosen[1]
		local to = s.who:Choice(space_areas, letter .. ': where to?')
		self:MoveCiv(letter, to)
		table.remove(s.chosen, 1)
	end

	self:PopState()
end

function state_funcs:state_place_new_ally(sub)
	if not sub.ally then
		sub.ally = self:DrawAlly()
		local ally = find_ally(sub.ally)
		self:ResultLog('\nNew ally: %s\n', ally.desc or ally.name)
	end

	if sub.reason == 'destroyed' then
		local n = 0
		for k,v in ipairs(self.players) do
			if v:Cylon() then
				local t = (v.trauma.benevolent or 0) + (v.trauma.antagonistic or 0)
				if t > n then n = t end
			end
		end
		local choices = {}
		for k,v in ipairs(self.players) do
			if v:Cylon() and (v.trauma.benevolent or 0) + (v.trauma.antagonistic or 0) == n then
				tins(choices, v)
			end
		end
		if #choices > 0 and n > 0 then
			sub.who = self.current:Choice(choices, 'which cylon shall place the token?')
		end
	end
	
	local choices = {}
	if sub.who then
		if sub.who.trauma.antagonistic > 0 then tins(choices, 'antagonistic') end
		if sub.who.trauma.benevolent > 0 then tins(choices, 'benevolent') end
	end
	local choice
	if #choices == 0 then
		choice = self:DrawTrauma()
	else
		choice = sub.who:Choice(choices, 'trauma to place')
		sub.who.trauma[choice] = sub.who.trauma[choice] - 1
	end
	
	if self.next_ally_token == nil then self.next_ally_token = 1 end
	local token = self.next_ally_token
	while true do
		local match = false
		for k,v in pairs(self.allies) do
			if token == v.token then match = true end
		end
		if match then
			token = (token + 1) % 12
		else
			break
		end
	end
	
	self.next_ally_token = (token + 1) % 12
	
	tins(self.allies, {trauma=choice, name=sub.ally, token=token})
	self:PopState()
end

function state_funcs:state_resolve_main_batteries(sub)
	local roll = self.roll_result
	local loc = self.space[sub.where]
	self.roll_result = nil
	if roll == 1 then
		if loc.civ then
			panic()
		end
	elseif roll < 3 then
		panic()
	else
		local n = (roll >= 7 and 4) or 2
		if loc.raider then
			if loc.raider > n then
				self:ResultLog('%d of the raiders are destroyed!', n)
				loc.raider = loc.raider - n
			else
				self:ResultLog('All of the raiders are destroyed!')
				loc.raider = 0
			end
		end
	end
	self:PopState()
end

function state_funcs:state_try(sub)
	if not sub.resolved then
		local done = {roll=true, pass=true, fail=true}
		local result = 'pass'
		for k,v in pairs(sub) do
			if not done[k] then
				done[k] = true
				if type(v) == 'number' and self[k] < v or self[k] ~= v then
					result = 'fail'
					break
				end
			end
		end
		if result == 'pass' and sub.roll then
			if self.roll_result then
				if self.roll_result < sub.roll then
					result = 'fail'
				end
				self.roll_result = nil
			else
				self:PushState('do_roll', {why='try-clause'})
				return
			end
		end
		sub.resolved = result
	else
		local t = sub[sub.resolved]
		self:ResultLog('%s', sub.resolved)
		self:PopState()
		self:Resolve(t)
	end
end

function state_funcs:state_cag_to_place_civ(sub)
	while sub.qty > 0 do
		local choices = {}
		for k,v in pairs(self.space) do
			if not v.civ or #v.civ == 0 then
				tins(choices, k)
			end
		end
		if #choices == 0 then
			for k,v in pairs(self.space) do
				tins(choices, k)
			end
		end
		local where = self.cag:Choice(choices, 'civilian ship where?')
		self:DeployShips('civ', 1, where)
		sub.qty = sub.qty - 1
	end
	self:PopState()
end

function state_funcs:state_launch_scout_effect(sub)
	local who = sub.acting or self.acting
	if not sub.deck then
		sub.deck = who:Choice({'crisis','destination'}, 'which deck?')
	end
	local deck = self[sub.deck .. '_deck']
	local f = _G['find_' .. sub.deck]
	local function peek_top(i)
		return deck[i] or deck:peek_top(i)
	end
	local function draw_top()
		return table.remove(deck, 1)
	end
	local function emplace_top(card)
		table.insert(deck, 1, card)
	end
	local function discard()
		table.insert(deck, card)
	end
	local function desc(t)
		return t.desc
	end
	if sub.deck == 'mission' then
		draw_top = function() return deck:draw_top() end
		peek_top = function(i) return deck:peek_top(i) end
		emplace_top = function(card) deck:place_top(card) end
		discard = function(card) deck:discard(card) end
		desc = function(t) return t['desc'] end
	end
	if sub.deck == 'destination' then
		desc = function(tmp)
			return string.format('%s - %d distance. %s', tmp.name, tmp.effect.distance, tmp.text)
		end
	end
	if not sub.shown then
		for i=1,(sub.qty or 1) do
			local t = peek_top(i)
			local tmp = f(t)
			who:PrivateMsg(desc(tmp))
		end
		sub.shown = true
	end
	
	if not sub.processing then
		sub.processing = {}
		for i=1,(sub.qty or 1) do
			tins(sub.processing, draw_top())
		end
	end
	
	while #sub.processing > 0 do
		local choices = {'q'}
		for i=1,#sub.processing do tins(choices, i) end
		local choice = who:Choice(choices, 'on top?')
		if choice == 'q' then break end
		emplace_top(sub.processing[choice])
		table.remove(sub.processing, choice)
	end
	
	while #sub.processing > 0 do
		discard(table.remove(sub.processing, choice))
	end
	
	self:PopState()
end

function state_funcs:state_glimpse_face_of_god(sub)
	local who = self.current
	if not sub.sent_cards then
		self:ResultLog('%s Glimpses the Face of God', who:full_name(true))
		who:PrivateMsg('DD cards are: ' .. self.destiny_deck[1]:formatted() .. ' & ' .. self.destiny_deck[2]:formatted())
		tins(who.hand, 1, table.remove(self.destiny_deck, 1))
		tins(who.hand, 1, table.remove(self.destiny_deck, 1))
		sub.sent_cards = true
		sub.pending = 2
	end
	
	while sub.pending > 0 do
		local card = who:ChooseCard()
		if card then
			tins(self.destiny_deck, card)
			sub.pending = sub.pending - 1
		end
	end
	self:PopState()
end

function state_funcs:state_card_draws_to_tre(sub)
	if not sub.discard and not sub.who:Cylon() then
		sub.who:DiscardCards(sub.qty)
		sub.discard = true
	end
	-- As per http://boardgamegeek.com/thread/637799/discarding-and-drawing-treachery 
	-- this is done in player order (not turn order)
	sub.who:DrawSpecificCards({tre=sub.qty})
	self:PopState('card_draws_to_tre')
end

function state_funcs:state_repair_reserve_vipers(sub)
	while sub.qty > 0 do
		local choices = {}
		if self.damaged_viper > 0 then
			tins(choices, 2)
		end
		if self.damaged_viper7 > 0 then
			tins(choices, 7)
		end
		local choice = sub.who:Choice(choices, 'repair which viper?')
		local lookup = {[2]='viper', [7]='viper7'}
		local n = lookup[choice]
		if n == nil then break end
		self['damaged_' .. n] = self['damaged_' .. n] - 1
		self[n] = self[n] + 1
		self:ResultLog('A %s is repaired', names[n])
		sub.qty = sub.qty - 1
	end
	while sub.qty < 0 do
		local choices = {}
		if self.viper > 0 then
			tins(choices, 2)
		end
		if self.viper7 > 0 then
			tins(choices, 7)
		end
		local choice = sub.who:Choice(choices, 'damage which viper?')
		local lookup = {[2]='viper', [7]='viper7'}
		local n = lookup[choice]
		if n == nil then break end
		self['damaged_' .. n] = self['damaged_' .. n] + 1
		self[n] = self[n] - 1
		self:ResultLog('A %s is damaged', names[n])
		sub.qty = sub.qty + 1
	end
	self:PopState()
end

function state_funcs:state_bb_place_ships(sub)
	local space = { 'front', 'sbow', 'saft', 'rear', 'paft', 'pbow' }
	local sector = self.acting:Choice(space, 'sector')
	local choice = self.acting:Choice({'basestar', 'raiders'}, 'basestar or raiders')
	if choice == 'basestar' then
		self:DeployShips('basestar', 1, sector, true)
	else
		self:DeployShips('raider', 3, sector, true)
	end
	self:PopState()
end
function state_funcs:state_bb_jump_pursuit(sub)
	if not self.roll_result then panic() end
	local roll = self.roll_result
	self.roll_result = nil
	if roll < 4 then
		if self.jump_track > 0 then
			self.jump_track = self.jump_track - 1
			self:ResultLog('Jump Prep drops to %s', jump_desc[self.jump_track])
		end
	else
		self:PushState('increase_pursuit')
	end
	self:PopState('bb_jump_pursuit')
end
function state_funcs:state_bb_try_damage(sub)
	if not self.roll_result then panic() end
	local roll = self.roll_result
	self.roll_result = nil
	local count = 0
	for k,v in pairs(self.space) do
		count = count + (v.raider or 0)
	end
	if roll < count then
		self:ResultLog(string.format('%d < %d, damage occurs', roll, count))
		self:PushState('damage_choice', {who=self.acting, choice=2, qty=1})
	end
	self:PopState('bb_try_damage')
end

function state_funcs:state_basestar_bridge(sub)
	local actions = {
		'bb_place_civ',
		'bb_place_ships',
		'bb_jump_pursuit',
		'bb_try_damage'
	}
	if not sub.actions then sub.actions = {} end
	
	local who = self.acting
	if not sub.action1 then
		sub.action1 = who:Choice(actions, 'bb action #1')
	end
	if not sub.action2 then
		sub.action2 = who:Choice(actions, 'bb action #2')
	end
	for k,v in ipairs({sub.action2, sub.action1}) do
		if v == 'bb_place_civ' then
			self:PushState('state_cag_to_place_civ', {qty=1})
		else
			self:PushState(v, {})
			if v == 'bb_try_damage' or v == 'bb_jump_pursuit' then
				self:PushState('do_roll', {why='basestar bridge action'})
			end
		end
	end
	self:PopState('basestar_bridge')
end

function state_funcs:state_popular_influence(t)
	local who = self.acting
	if not t.cards then
		t.cards = {(self:DrawQuorumCard()), (self:DrawQuorumCard())}
		local msg = string.format("%s\n\n%s",find_quorum(t.cards[1]).desc, find_quorum(t.cards[2]).desc)
		who:PrivateMsg(msg)
	end
	if #t.cards == 2 then
		local which = who:Choice({'1','2'}, 'give which to president?')
		local name = table.remove(t.cards, which)
		local card = find_quorum(name)
		tins(self.quorum_hand, name)
		self.president:PrivateMsg('New Quorum Card: %s', card.desc)
	end
	local choice = who:Choice({'play', 'discard'})
	if choice == 'play' then
		self:PushState('play_quorum', {who=who, hand=t.cards})
	else
		self:ResultLog('Dicarding %s', t.cards[1])
		self.quorum_deck:discard(t.cards[1])
	end

	self:PopState('popular_influence')
end

function state_funcs:state_damage_space_vipers()
	self:PopState()
end

function state_funcs:state_discard_cards_resume(t)
	--t.who:DiscardCardsInternal(t)
	self:PopState()
end

function state_funcs:EndGame()
	self:GMChoice({'game','over'}, 'game over')
	panic()
end

function state_funcs:state_cylon_win(why)
	self:ResultLog('Cylon victory!')
	if why == 'damage' then
		self:ResultLog('Galactica has been destroyed, and the human fleet is doomed.')
	end
	self:EndGame()
end

function state_funcs:state_human_win()
	self:ResultLog('Human victory!')
	self:EndGame()
end

state_machine = {
}
