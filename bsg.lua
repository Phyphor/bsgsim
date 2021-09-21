require "deck"
require "data"

-- This defines card names & listing order
card_types = {
--	lea="Lea", tac="Tac", pol="Pol", pil="Pil", eng="Eng", tre="Tre",
	[1]="lea", [2]="tac", [3]="pol", [4]="pil", [5]="eng", [6]="tre",
}

-- Colors for various things
colors = {
	lea = "limegreen", tac = "mediumorchid", pol = "orange", pil = "red", eng = "dodgerblue", tre = "brown",
	benevolent = "blue", antagonistic = "red",
}

space_areas = {'front', 'rear', 'pbow', 'paft', 'sbow', 'saft'}

-- Display names for stuff
names = {
	lea="Lea", tac="Tac", pol="Pol", pil="Pil", eng="Eng", tre="Tre",
	front = 'Fore', pbow = 'Port Bow', paft = 'Port Quarter', rear = 'Aft',
	sbow = 'Starboard Bow', saft = 'Starboard Aft',
	raider = 'Raider', heavy = 'Heavy Raider', basestar = 'Basestar',
	pop = "Population", fuel = "Fuel", morale = "Morale", food = "Food",
	viper = "Mk II viper",
	viper7 = "Mk VII viper",
	raptor = "Raptor",
	araptor = "Assault Raptor",
	nukes = "Nukes",
	benevolent = "Benevolent", antagonistic = "Antagonistic", disaster = 'Disaster',
	galactica = "Galactica", pegasus = "Pegasus",
	chief_of_staff = "Chief of Staff",
	mission_specialist = 'Mission Specialist',
}

function pairlist(...)
	local t = {...}
	if #t == 0 then return function() end, nil, nil end
	local index = 1
	local function it(t, k)
		t = t[index]
		if not t then return end
		local v
		k, v = next(t, k)
		if k == nil then
			index = index + 1
			return it(t, nil)
		end
	end
	return it, t, nil
end

local function _ripairs(t, var)
	local value = t[var]
	if value == nil then return end
	return var - 1, value
end
function ripairs(t) return _ripairs, t, #t end

local tins = table.insert
local sfmt = string.format

function shuffle_list(list)
	local new_list = {}

	while #list > 1 do
		local index = math.random(1, #list)
		table.insert(new_list, list[index])
		table.remove(list, index)
	end

	table.insert(new_list, list[1])
	return new_list
end

function jump_desc(jump_track)
	local t = {
		[0] = "[color=red]Level 0 - Jump unavailable.[/color]",
		[1] = "[color=red]Level 1 - Jump unavailable.[/color]",
		[2] = "[color=red]Level 2 - Jump unavailable.[/color]",
		[3] = "[color=dodgerblue]Level 3 - Risk loss of 3 population.[/color]",
		[4] = "[color=limegreen]Level 4 - Risk loss of 1 population.[/color]",
		[5] = "[color=limegreen]Auto-jump![/color]",
	}
	assert(t[jump_track])
	return t[jump_track]
end



table.copy = function (s, depth)
	if depth then
		if depth == 0 then return s end
		depth = depth - 1
	end
	local t = {}
	for k,v in pairs(s) do
		if type(v) == "table" then
			v = table.copy(v, depth)
		end
		t[k] = v
	end
	return setmetatable(t, getmetatable(s))
end

table.remove_random = function(t)
	return table.remove(t, math.random(#t))
end

table.remove_specific = function(t, value)
	for k,v in pairs(t) do
		if v == value then
			if type(k) == 'number' then
				table.remove(t, k)
			else
				t[k] = nil
			end
			break
		end
	end
end


local card_meta = {}
card_meta.__index = card_meta

function load_card(s, t)
	local m = find_card(t.name)
	return setmetatable({strength=t.strength, orig=t.orig}, {__index=m})
end
function card_meta:savefunc()
	local extra = ''
	if self.orig then extra = extra .. string.format('orig=%d', self.orig) end
	return string.format('{strength=%d,name=%q, loadfunc="load_card",%s}', self.strength,self.name,extra)
end
function card_meta:formatted()
	local strength
	if self.mod_strength then strength = sfmt('[s]%d[/s] %d', self.strength, self.mod_strength)
	else strength = tostring(self.strength) end
	return sfmt('[b][color=%s]%s %s %s[/color][/b]', colors[self.type], names[self.type], strength, self.name)
end

for k,v in ipairs(skill_card_list) do
	setmetatable(v, card_meta)
end


function card_sort_func(a,b)
	for k,v in ipairs(card_types) do
		if v == a.type and v ~= b.type then return true end
		if v ~= a.type and v == b.type then return false end
	end
	return a.strength < b.strength
end

function sort_card_list(list)
	local t = {}
	for k,v in pairs(list) do tins(t, v) end
	table.sort(t, card_sort_func)
	return t
end


function print_loyalty_card(card)
	local s
	if card.desc then return card.desc end
	
	if card.cylon then
		s = 'You [b]ARE[/b] a cylon'
	else
		s = 'You [b]ARE NOT[/b] a cylon'
	end
	if card.final5 then
		s = s .. '\nFinal Five'
	end
	if card.personal_goal then
		s = s .. string.format('\nPersonal Goal: %s or lose 1 %s', card.personal_goal.goal, names[card.personal_goal.penalty])
	end
	return s
end

local rawget = rawget
function player_funcs:__index(k)
	if k == 'opg_used' then
		if self.miracle == nil then self.miracle = 0 end
		return self.miracle > 0
	end
	return player_funcs[k]
end

local rawset = rawset
function player_funcs:__newindex(k, v)
	if k == 'opg_used' then
		self.miracle = self.miracle - 1
	end
	rawset(self, k, v)
end

function player_funcs:Cylon()
	return self.location and self.location.ship == "cylon"
end

function player_funcs:HiddenCylon()
	if self:Cylon() then return false end
	for k,v in pairs(self.loyalty) do
		if v.cylon then
			return true
		end
	end
	return false
end

function player_funcs:PrivateMsg(fmt, ...)
	local str = sfmt(fmt, ...) .. '\n'

	if not self.state.private_msg then self.state.private_msg = {} end
	stdout('Private ('..self.name..'):\n' .. str)
	self.state.private_msg[self.player] = (self.state.private_msg[self.player] or '') .. str
end

function player_funcs:ResultLog(fmt, ...)
	local str = sfmt(fmt, ...) .. '\n'

	stdout('Result: ' .. str)
	self.state.result_log = (self.state.result_log or '') .. str
end

function player_funcs:DrawMutiny(no_choice, options)
	local zarek = self.state:FindPlayer('Tom Zarek (alt)')
	local card
	if zarek and not no_choice and not zarek:Cylon() then
		local card1 = self.state.mutiny_deck:draw_top()
		local card2 = self.state.mutiny_deck:draw_top()
		zarek:PrivateMsg('For %s:\n%s\n[b]OR[/b]\n%s', self.name, find_mutiny(card1).desc, find_mutiny(card2).desc)
		local choice = zarek:Choice({1,2}, 'which card?')
		local list = {card1, card2}
		card = list[choice]
		local other = list[3-choice]
		self.state.mutiny_deck:discard(other)
	else
		card = self.state.mutiny_deck:draw_top()
	end
	self:ResultLog('%s draws a mutiny card', self:full_name(true))
	self:PrivateMsg('Mutiny card: %s', find_mutiny(card).desc)
	tins(self.mutiny_hand, card)
	local mutiny_limit = 2
	if self.state.mutineer == self then mutiny_limit = 3 end
	if #self.mutiny_hand >= mutiny_limit and not (options and options.no_brig) then
		self:ResultLog('%s holds too many mutiny cards and is sent to the brig', self:full_name(true))
		self:MoveTo('Brig')
		self:ResultLog('%s must discard down to %d mutiny card', self:full_name(), mutiny_limit - 1)
		self.state:PushState('mutiny_discard', {to = mutiny_limit - 1, who=self})
	end
	if self.name == 'Lee "Apollo" Adama (alt)' then
		self:DiscardCards(2)
	end
end

function player_funcs:GetName()
	return self.name
end

function player_funcs:FindSpaceSector()
	for k,v in pairs(self.state.space) do
		if v.pilots then
			for j,u in pairs(v.pilots) do
				if u.who == self then return v,j end
			end
		end
	end
end

function player_funcs:DrawSpecificCards(counts)
	local msg = ' draws'
	for k,v in ipairs(card_types) do
		if counts[v] and counts[v] > 0 then
			msg = msg .. string.format(' [color=%s][b]%d %s[/b][/color]', colors[v], counts[v], names[v])
		end
	end
	if msg == ' draws' then return end

	self:ResultLog('%s %s', self:full_name(true), msg)

	for k,v in pairs(counts) do
		for i=1,v do
			local card = self.state.skill_decks[k]:draw_top()
			if card then
				tins(self.hand, card)
			end
		end
	end
	
	self:PrivateMsg('Your hand (turn %d):', self.state.turn or 1)
	for k,v in ipairs(self.hand) do
		self:PrivateMsg(v:formatted())
	end
	
	return msg
end

function player_funcs:ChooseCard(desc, filter)
	local choices = {'q'}
	for k,v in ipairs(self.hand) do
		if not filter or filter(v) then
			print(sfmt('%d. (%s %d - %s)\n', k, names[v.type], v.strength, v.name))
			tins(choices, k)
		end
	end
	local choice = self:Choice(choices, desc or 'choose card', true)
	if choice ~= 'q' then return table.remove(self.hand, tonumber(choice)) end
end

function player_funcs:ChooseCardFrom(desc, list)
	local choices = {'q'}
	for k,v in ipairs(list) do
		print(sfmt('%d. (%s %d - %s)\n', k, names[v.type], v.strength, v.name))
		tins(choices, k)
	end
	local choice = self:Choice(choices, desc or 'choose card', true)
	if choice ~= 'q' then return table.remove(list, tonumber(choice)) end
end

function player_funcs:DiscardMutiny(qty)
	local n = (qty == 'all' and 0) or (#self.mutiny_hand - qty)
	if #self.mutiny_hand <= n then return end
	self:ResultLog('Mutiny discards:')
	while #self.mutiny_hand > n do
		local choice = self.mutiny_hand[1]
		if n > 0 then
			self:Choice(self.mutiny_hand, 'which card')
		end
		table.remove_specific(self.mutiny_hand, choice)
		self:ResultLog('%s\n\n', find_mutiny(choice).desc)
	end
end
function player_funcs:GetCheckContribution(str)
	local choices = {'q'}
	if str then
		print("%s", str)
	end
	for k,v in ipairs(self.hand) do
		print(sfmt('%d. (%s %d - %s)\n', k, names[v.type], v.strength, v.name))
		tins(choices, k)
	end
	local choice = self:Choice(choices, 'check contribution', true)
	if choice ~= 'q' then return table.remove(self.hand, tonumber(choice)) end
end

function player_funcs:Brigged()
	return self.location.name == 'Brig'
end

function player_funcs:GetCheckMaxContributions()
	if self:Brigged() then return 1 end
	if self:Cylon() then return 1 end
	if self.type == 'cylon' then return 2 end
end

function player_funcs:GetFlexDraw(list, desc)
	if debug_mode then
		return list[math.random(#list)]
	end
	return self:Choice(list, desc)
end

function player_funcs:GetLegalDrawTypes()
	local types = {}
	for k,v in ipairs(card_types) do
		if self.draw[v] or (self.draw.flex and self.draw.flex[v]) then
			table.insert(types, v)
		end
	end
	return types
end

function player_funcs:GetFlexDrawTypes()
	local types = {}
	for k,v in ipairs(card_types) do
		if self.draw.flex and self.draw.flex[v] then
			table.insert(types, v)
		end
	end
	return types
end

function player_funcs:GetLegalMovementTargets(t, infiltrating)
	if not t then t = {} end
	for k,v in pairs(locations) do
		if not v.hazardous and not self.state[v.ship .. '_destroyed'] and v.ship ~= 'viper' then
			-- basic movement restrictions
			local rebel_move = self.state.rebel and self:Cylon() == (self.state.rebel == 'cylon')
			if (v.ship ~= 'rebel' or rebel_move) and ((v.ship == "cylon") == self:Cylon() or infiltrating) then
				-- alignment restrictions
				if self.location.ship == v.ship or #self.hand > 0 then
					table.insert(t, v.alias or v.name)
				end
			end
		end
	end
	return t
end

function RawChoiceFunction(state, choices, choice_str, out_function)
	-- if there's only one choice...
	if choices and #choices == 1 then return choices[1] end
	if choices and #choices == 0 then return nil end
	local help = false
	local s = choice_str .. '\n'
	if choices then
		for k,v in ipairs(choices) do
			local vs = (type(v) == "table" and v.name) or tostring(v)
			s = s .. '[' .. vs .. ']'
			if type(v) == "table" and v.player then
				s = s .. '[' .. v.player:lower() .. ']'
			end
		end
	else
		s = s .. '<free input>'
	end
	
	local funcs
	funcs = {
		help = function()
			help = true
			print("Available commands:\n")
			local strs = {}
			for k,v in pairs(funcs) do
				if v ~= funcs.help then table.insert(strs, '  ' .. k .. ' - ' .. v() .. '\n') end
			end
			table.sort(strs)
			for k,v in ipairs(strs) do print(v) end
			help = false
		end,
		quit = function() if help then return "quit" end
			print("Aborting")
			exit()
		end,
		exec = function() if help then return "run arbitrary Lua code" end
			print("Exec: ")
			while true do
				local str = get_input()
				if str == 'q' then
					break
				else
					local f, err = loadstring(str)
					if f then
						_G.state = state
						local result, err = pcall(f)
						if not result then
							print("Exec error: " .. err)
						end
						_G.state = nil
					else
						print('Error: ' .. err)
					end
				end
			end
		end,
		save = function() if help then return "save current state" end
			state:Save()
		end,
		hand = function() if help then return "print player hands" end
			for k,v in ipairs(state.players) do
				print("%s\n", v:full_name(true))
				for i,j in ipairs(v.hand) do
					print("%s\n", j:formatted())
				end
				print("\n")
			end
		end,
		trauma = function()
			if help then return "print player trauma" end
			for k,v in ipairs(state.players) do
				print("%s: %d total; %d Benevolent, %d Antagonistic\n", v:full_name(true), v.trauma.benevolent + v.trauma.antagonistic, v.trauma.benevolent, v.trauma.antagonistic)
			end
		end,
		post = function(line) if help then return "create a post, save and quit" end
			out_function(s)
			if state:DumpAndSave(line) then
				print("Aborting, post made")
				exit()
			end
		end,
		image = function() if help then return "generate a sitrep image" end
			local name = 'sitrep.png'
			state:ImageSitrep(name)
			print('Saved to '..name..'\n')
		end,
		custom_roll = function() if help then return "toggle roll overrides; current: " .. tostring(global_enable_roll_override or false) end
			global_enable_roll_override = not global_enable_roll_override
			print("Roll override: " .. tostring(global_enable_roll_override))
		end,
	}

	
	while true do
		print(s .. '\nInput: ')
		local line = get_input()
		local cmd = line
		if funcs[cmd] then
			funcs[cmd](line)
		elseif choices then
			for k,v in pairs(choices) do
				local vs = (type(v) == "table" and v.name) or tostring(v)
				if vs:lower() == line:lower() or (type(v) == "table" and v.player and v.player:lower() == line:lower()) then
					return v
				end
			end
			if not state.disallow_overrides and line:match('override:') then
				local sub = line:sub(10)
				if sub ~= '' then return sub end
			end
			print("Unknown choice [%s]\n", line)
		else
			return line
		end
	end
end

function player_funcs:Choice(choices, choice_str, private)
	if debug_mode and debug_get_choice then return debug_get_choice(self.state, self, choices, choice_str, private) end

	local state = self.state
	state.choosing = self
	
	local s = string.format("Choice for %s / %s: ", self.name, self.player)
	if choice_str then
		s = s .. choice_str .. ' '
	end
	
	local result = RawChoiceFunction(state, choices, s,
		function()
			if private then
				self:PrivateMsg('Choice: ' .. choice_str)
			else
				state:ResultLog("Waiting on %s: %s", self:full_name(), choice_str)
			end
		end)
	state.choosing = nil
	return result
end

function player_funcs:RemoveSelectedTrauma()
	local choices = {}
	if self.trauma.antagonistic > 0 then tins(choices, 'antagonistic') end
	if self.trauma.benevolent > 0 then tins(choices, 'benevolent') end
	local c = self:Choice(choices, 'choose trauma')
	self.trauma[c] = self.trauma[c] - 1
	return c
end

function player_funcs:DrawCards(n, any)
	local counts = {lea = 0, tac = 0, pol = 0, pil = 0, eng = 0, tre = 0 }
	local choices = self:GetLegalDrawTypes()
	if any or self:Cylon() then choices = {'lea','tac','pol','pil','eng','tre'} end
	for i=1, n do
		local choice = self:GetFlexDraw(choices, 'card draw')
		counts[choice] = counts[choice] + 1
	end
	self:DrawSpecificCards(counts)
end

function player_funcs:DiscardCardsInternal(t)
	local discard_list = {}
	local draw_mutiny
	if t.n >= #self.hand then
		t.list = self.hand
		self.hand = {}
	else
		while t.n > 0 do
			if #self.hand == 0 then break end
			
			if t.random then
				table.insert(t.list, table.remove_random(self.hand))
			else
				local card = self:ChooseCard('discard')
				table.insert(t.list, card)
				if card.mutiny_on_discard then draw_mutiny = true end
			end
			t.n = t.n - 1
		end
	end
	if #t.list > 0 then
		self:ResultLog('%s discards', self:full_name(true))
		self.state:ToDiscard(t.list)
		for k,v in ipairs(sort_card_list(t.list)) do
			if v.type == 'tre' and not self:Cylon() and not self.state.flags.sabotaged then
				-- check for sabotage!
				if self.state:CheckPlayInterrupt('Sabotage', '!human') then
					self.state.turn_flags.sabotaged = true
					self.state:PushState('damage', {})
				end
			end
			
			self:ResultLog('%s', v:formatted())
		end
	end
	self.state:PopState('discard_cards_resume')
	if draw_mutiny then self:DrawMutiny() end
	return t.list
end

function player_funcs:DiscardCards(n, random, never_random)
	if self.name == 'Lee "Apollo" Adama' and not self:Cylon() then random = true end
	if never_random then random = nil end
	local t = {n = n, list = {}, random = random, who=self}
	local state = self.state
	state:PushState('discard_cards_resume', t)
	return self:DiscardCardsInternal(t)
end

function player_funcs:CanActivateLocation(loc)
	if not loc then loc = self.location end
	if self.state.damage[loc.name] then return end
	if self.name == "Laura Roslin" and #self.hand < 2 then return end
	if self.name == "Tom Zarek" then
		for k,v in ipairs(self.state.players) do if self ~= v and self.location.name == v.location.name then return false end end
	end
	if self.cant_activate then
		if type(self.cant_activate) == 'string' then return loc.name ~= self.cant_activate end
		for k,v in pairs(self.cant_activate) do
			if v == loc.name then return end
		end
	end
	return true
end


function player_funcs:YN(str)
	return self:Choice({'n','y'}, str) == 'y'
end

function player_funcs:CheckForCard(name)
	for k,v in pairs(self.hand) do
		if v.name == name then return true end
	end
end

function player_funcs:LandPilot()
	for k,v in pairs(self.state.space) do
		for i,j in pairs(v.pilots or {}) do
			if j.who == self then
				table.remove(v.pilots, i)
				self:ResultLog('%s returned to the reserves', names[j.what])
				self.state[j.what] = self.state[j.what] + 1
				v[j.what] = v[j.what] - 1
				return
			end
		end
	end
end

function player_funcs:MoveTo(to)
	local loc = to
	if type(to) == 'string' then to = find_location(to) end
	if self.location and self.location.ship == 'viper' then
		-- need to pull out the viper
		self:LandPilot()
	end
	self.location = to
	if to.name == 'Brig' then
		local titles = {'Admiral', 'CAG'}
		for k,v in ipairs{'admiral', 'cag'} do
			if self.state[v] == self then
				local who = self.state:Succession(v)
				local old_name = who:full_name(true)
				self.state[v] = who
				local new_name = who:full_name(true)
				self:ResultLog('%s is no longer %s', self:full_name(true), titles[k])
				self:ResultLog('%s becomes %s', old_name, new_name)
			end
		end
	end
end



state_funcs = {}
state_funcs.__index = state_funcs

function new_state_raw()
	return setmetatable({}, state_funcs)
end


function state_funcs:GMChoice(choices, context)
	return RawChoiceFunction(self, choices, 'GM choice: ' .. context, print)
end

function state_funcs:ResultLog(fmt, ...)
	local str = sfmt(fmt, ...) .. '\n'

	self.result_log = (self.result_log or '') .. str
	stdout('Result: ' .. str)
end


function state_funcs:MakeNewDestinyDeck()
	for k,v in pairs(self.skill_decks) do
		table.insert(self.destiny_deck, v:draw_top())
		table.insert(self.destiny_deck, v:draw_top())
	end
	self:ResultLog('The destiny deck is created with %d cards', #self.destiny_deck)
	self.destiny_deck = shuffle_list(self.destiny_deck)
end

function state_funcs:FindPlayer(name)
	for k,v in ipairs(self.players) do
		if match_name(name, v) then return v end
		if name:lower() == v.player:lower() then return v end
	end
end


function state_funcs:ToDiscard(cards)
	if cards.type then
		self.skill_decks[cards.type]:discard(cards)
	else
		for k,v in pairs(cards) do
			self.skill_decks[v.type]:discard(v)
		end
	end
end

function state_funcs:DealTurnCards()
	local who = self.current
	local draw = who.draw
	local counts = {lea = draw.lea, tac = draw.tac, pol = draw.pol, pil = draw.pil, eng = draw.eng, tre = draw.tre }
	
	if who.name == 'Samuel T. Anders' and not state.anders_skipped then
		state.anders_skipped = true
		return
	end

	if who.location.name == "Sickbay" or who.location.name == "Medical Center" or (who.location.name == 'Resurrection Ship' and who.type == 'cylon') then
		local type = who:GetFlexDraw(who:GetLegalDrawTypes(), "In " .. who.location.name .. ", one card only")
		local t = {}
		t[type] = 1
		self.recieve_skills_msg = who:DrawSpecificCards(t)
		return
	end
	
	-- Revealed cylons that aren't cylon leaders
	if who.type ~= "cylon" and who:Cylon() then
		counts = {}
		-- can only draw two cards, of different types
		local types = {}
		for k,v in ipairs(card_types) do table.insert(types, v) end

		local choice = who:GetFlexDraw(types, '1st cylon card')
		counts[choice] = 1
		types = {}
		for k,v in ipairs(card_types) do
			if v ~= choice then
				table.insert(types, v)
			end
		end
		if who.location.name ~= 'Resurrection Ship' then
			choice = who:GetFlexDraw(types, '2nd cylon card')
			counts[choice] = 1
		end
		self.recieve_skills_msg = who:DrawSpecificCards(counts)
		return
	end
	
	-- deal the new turn cards
	if draw.flex then
		for i=1, draw.flex.qty do
			local choice = who:GetFlexDraw(who:GetFlexDrawTypes(), 'flex draw')
			counts[choice] = (counts[choice] or 0) + 1
		end
	end
	if who.type == "cylon" and not who:Cylon() then
		-- infiltrating cylon leaders get a 3rd card
		local choice = who:GetFlexDraw(who:GetLegalDrawTypes(), "cylon leader infiltrating card")
		counts[choice] = (counts[choice] or 0) + 1
	end
	if who.name == 'Aaron Doral' and not who:Cylon() then
		local choice = who:GetFlexDraw(who:GetLegalDrawTypes(), "doral's extra infiltrating card")
		counts[choice] = (counts[choice] or 0) + 1
	end
	
	if self.current.name == 'Karl "Helo" Agathon (alt)' then
		panic()
	end
	
	self.recieve_skills_msg = self.current:DrawSpecificCards(counts)
end


function state_funcs:DrawTrauma()
	local n = self.trauma.disaster + self.trauma.benevolent + self.trauma.antagonistic
	n = math.random(n)
	local type
	if n <= self.trauma.disaster then
		type = "disaster"
	elseif n<= self.trauma.disaster + self.trauma.benevolent then
		type = "benevolent"
	else
		type = "antagonistic"
	end
	self.trauma[type] = self.trauma[type] - 1
	return type
end

function state_funcs:DrawAlly()
	if #self.allies_deck > 0 then
		return table.remove(self.allies_deck)
	end
end

function state_funcs:RemoveAlly(who)
	for k,v in pairs(self.allies_deck) do
		if v == who then
			table.remove(self.allies_deck, k)
			break
		end
	end
end



function state_funcs:ReturnTrauma(type)
	self.trauma[type] = self.trauma[type] + 1
end

function state_funcs:d8()
	return math.random(8)
end

function state_funcs:FindPlayer(name)
	for k,v in ipairs(self.players) do
		if match_name(name, v) then return v end
		if name:lower() == v.player:lower() then return v end
	end
end
function state_funcs:NextPlayer(who)
	return self.players[(who or self.current).number + 1] or self.players[1]
end
function state_funcs:Succession(title, abdication)
	local list = title_succession[title]
	local who = {}
	for k,v in ipairs(self.players) do
		if not abdication or v ~= self[title] and not v:Cylon() then
			local n = v.name
			--if v.alt then n = n .. ' (alt)' end
			who[n] = v
		end
	end
	for k,v in ipairs(list) do
		if who[v] then
			-- president can go to brigees
			if who[v].location.name ~= "Brig" or title == "president" then
				return who[v]
			end
		end
	end

	-- everyone is in the brig?
	for k,v in ipairs(list) do
		if who[v] then
			return who[v]
		end
	end
end

function state_funcs:CheckEndOfGame()
	return self.morale <= 0 or self.food <= 0 or self.fuel <= 0 or self.pop <= 0 or
		(function ()
			for k,v in pairs(locations) do
				if v.ship == 'galactica' and v.damageable and not self.damage[k] then
					return false
				end
			end
			return true
		end)()
end

function state_funcs:StateStaskDesc()
	local ret = ''
	for k,v in ipairs(self.state_stack) do
		ret = ret .. ' <-- ' .. v.state
	end
	return '--> ' .. self.state .. ret
end

local function format_agenda_text(agenda)
	return string.format("[b]%s[/b] - The %ss have won [b]AND[/b] %s",
		agenda.name, agenda.winner, agenda.extra)
end

function state_funcs:DealStartingLoyalty(p)
	if p.type == "cylon" then
		if p.motives then self:DaybreakLeaderMissions(p) return end

		-- pick agenda
		local hostile = {
			{name = "Genocide", winner="cylon", extra="Both food and population are at 2 or less"},
			{name = "Reduce Them to Ruins", winner="cylon", extra="4 or more Galactica and/or Pegasus locations are damaged and Morale is at 3 or lower"},
			{name = "Show Their True Nature", winner="cylon", extra="The Cylons have won AND Either you are in the “Brig” or “Detention”, or you have been executed at least once"},
			{name = "Siege Warfare", winner="cylon", extra="The Cylons have won AND Every resource is at half or lower (in the red)"},
			{name = "Grant Mercy", winner="human", extra="Population, morale, or food is 2 or lower"},
			{name = "Mutual Annihilation", winner="human", extra="You have played a Super Crisis Card"},
		}
		local benevolent = {
			{name = "Convert the Infidels", winner="human", extra="All resources are at 3 or lower"},
			{name = "Guide Them to Destiny", winner="human", extra="Population and morale values are within 2 of each other"},
			{name = "Join the Colonials", winner="human", extra="you are Infiltrating and not in the “Brig” or “Detention”"},
			{name = "Prove Their Worth", winner="human", extra="at least 5 Raptors/vipers are damaged or destroyed"},
			{name = "The Illusion of Hope", winner="cylon", extra="6 or more units of distance have been travelled"},
			{name = "Salvage their Equipment", winner="cylon", extra="2 or fewer Galactica locations are damaged"},
		}
		local agenda_list = hostile
		local n = #self.players
		-- check for even #
		if n == 2 * math.floor(n / 2) then agenda_list = benevolent end
		p.agenda = table.remove_random(agenda_list)
		p:PrivateMsg('Agenda: ' .. format_agenda_text(p.agenda))
	else
		self:DealLoyaltyTo(p)
		if p.name == "Gaius Baltar" then
			self:DealLoyaltyTo(p)
		end
	end
end

function state_funcs:LaunchViper(where, pilot)
	local choices = {}
	local chooser = pilot or self.acting
	--if not pilot then pilot = self.acting end
	
	if self.viper > 0 then tins(choices, 'mk 2') end
	if self.viper7 > 0 then tins(choices, 'mk 7') end
	if self.araptor > 0 then tins(choices, 'raptor') end
	if #choices == 0 then return false end
	
	local choice = chooser:Choice(choices, 'viper placement')
	if choice == 'mk 2' then
		choice = 'viper'
	elseif choice == 'raptor' then
		choice = 'araptor'
	else
		choice = 'viper7'
	end
	self:DeployShips(choice, 1, where)

	local p = self:FindPlayer('lee')
	if not pilot and p and p.location.ship == 'galactica' and p.location.name ~= 'Brig' then
		-- If unmanned and Lee is playing, not brigged and on Galactica, let him take it over
		local choice = p:Choice({'n','y'},'Does Lee pilot this viper?')
		if choice == 'y' then
			pilot = p
			self:ResultLog('Lee uses Active Viper Pilot to pilot the viper launched to %s', names[where])
			self:PushState('set_active_player', {who=self.acting})
			self:PushState('action', {requires_human = true})
			self.acting = p
		end
	end
	if pilot then
		if not self.space[where].pilots then self.space[where].pilots = {} end
		table.insert(self.space[where].pilots, {who=pilot, what=choice})
		pilot:MoveTo(locations.viper)
	end
	return true
end

function state_funcs:DaybreakLeaderMissions(p)
	p:PrivateMsg('New motives')
	for i = 1,2 do
		local name = table.remove(self.motives)
		p:PrivateMsg(string.format('%s - %s', name, motive_list[name]))
	end
end

function state_funcs:NewCharacterLoyalty(p)
	if p.type == "cylon" then
		if self.motives then return self:DaybreakLeaderMissions(p) end
		
		-- pick agenda
		local hostile = {
			{name = "Genocide", winner="cylon", extra="Both food and population are at 2 or less"},
			{name = "Reduce Them to Ruins", winner="cylon", extra="4 or more Galactica and/or Pegasus locations are damaged and Morale is at 3 or lower"},
			{name = "Show Their True Nature", winner="cylon", extra="The Cylons have won AND Either you are in the “Brig” or “Detention”, or you have been executed at least once"},
			{name = "Siege Warfare", winner="cylon", extra="The Cylons have won AND Every resource is at half or lower (in the red)"},
			{name = "Grant Mercy", winner="human", extra="Population, morale, or food is 2 or lower"},
			{name = "Mutual Annihilation", winner="human", extra="You have played a Super Crisis Card"},
		}
		local benevolent = {
			{name = "Convert the Infidels", winner="human", extra="All resources are at 3 or lower"},
			{name = "Guide Them to Destiny", winner="human", extra="Population and morale values are within 2 of each other"},
			{name = "Join the Colonials", winner="human", extra="you are Infiltrating and not in the “Brig” or “Detention”"},
			{name = "Prove Their Worth", winner="human", extra="at least 5 Raptors/vipers are damaged or destroyed"},
			{name = "The Illusion of Hope", winner="cylon", extra="6 or more units of distance have been travelled"},
			{name = "Salvage their Equipment", winner="cylon", extra="2 or fewer Galactica locations are damaged"},
		}
		local agenda_list = hostile
		local n = #self.players
		-- check for even #
		if n == 2 * math.floor(n / 2) then agenda_list = benevolent end
		p.agenda = table.remove_random(agenda_list)
		p:PrivateMsg('Agenda: ' .. format_agenda_text(p.agenda))
	else
		self:DealLoyaltyTo(p)
		if p.name == "Gaius Baltar" then
			self:DealLoyaltyTo(p)
		end
	end
end

function state_funcs:PlaceSelectedCharacter(p)
	local loc
	if type(p.start) == "table" then
		loc = p:Choice(p.start, 'start choice')
	elseif p.start == "viper" then
		loc = p.start
		local choice = p:Choice({'pbow','paft'}, 'start in port bow or quarter?')
		if not self:LaunchViper(choice, p) then loc = "Hangar Deck" end
	else
		loc = p.start
	end
	p:MoveTo(loc)
	assert(p.location)
	self:ResultLog('%s starts in %s', p:full_name(true), p.location.name)
end

function state_funcs:step()
	print("%s\n", self:StateStaskDesc())
	self:step_while(self.state)
end

function state_funcs:step_game()
	while not self.game_over do
		self:step()
	end
end

function state_funcs:step_until(target)
	while not self.game_over do
		if type(target) == "string" and self.state == target then return true
		elseif type(target) == "function" and target(self) then return true
		elseif type(target) == "table" and target[self.state] then return true end
		
		self:ExecState()
	end
end

function state_funcs:step_while(target)
	while not self.game_over do
		if type(target) == "string" and self.state ~= target then return true
		elseif type(target) == "function" and not target(self) then return true
		elseif type(target) == "table" and not target[self.state] then return true end
		
		self:ExecState()
	end
end



-- Filters players (can prefix filter with ! to invert)
-- all - everyone
-- human - humans, unrevealed cylons and infiltrating leaders
-- real_human - humans, unrevealed cylons (for titles, loyalty handoff, etc)
-- title - has a title
-- galactica - people on galactica
-- loc:<location>
-- <any specific keyword> - the player who matches it, ie "current" "admiral" "cag" "active" as defined by the state
function state_funcs:FilterPlayers(filter, source)
	local ret = {}
	local reversed = false
	if not source then
		source = {}
		for k,v in ipairs(self.players) do
			source[k] = v
		end
	end
	if type(filter) == 'table' then
		local t = source
		for k,v in ipairs(filter) do
			t = self:FilterPlayers(v, t)
		end
		return t
	end
	if filter ~= nil then
		if filter:sub(1,1) == '!' then
			filter = filter:sub(2)
			reversed = true
		end
	end
	local filter_f
	if filter:sub(1,4) == "loc:" then
		local where = find_location(filter:sub(5))
		filter_f = function (v) return v.location.name == where.name end
	end
	for _,v in ipairs(source) do
		if (filter == nil or filter == 'all' or
		   (filter_f and filter_f(v)) or
		   (filter == 'human' and not v:Cylon()) or
		   (filter == 'galactica' and v.location.ship == 'galactica') or
		   (filter == 'real_human' and not v:Cylon() and v.type ~= 'cylon') or
		   (filter == 'title' and (v == self.president or v == self.admiral or v == self.cag)) or
		   (filter == v.name) or
		   (self[filter] == v)) ~= reversed then

			table.insert(ret, v)
		end
	end
	return ret
end

function state_funcs:SortTurnOrder(p, reversed)
	local t = {}
	for k,v in pairs(p) do
		table.insert(t, (type(v) == 'table' and v) or k)
	end
	local cur = self.current.number
	table.sort(t, function (a,b)
		if reversed then a,b = b,a end
		local an, bn = a.number, b.number
		if an < cur then an = an + 100 end
		if bn < cur then bn = bn + 100 end

		if reversed then
			return bn > an
		else
			return an < bn
		end
	end)
	return t
end

function state_funcs:UnionPlayers(...)
	local t = {}
	local tmp = {}
	for k,v in ipairs(arg) do
		for _,p in pairs(v) do
			tmp[p] = true
		end
	end
	for k,v in pairs(tmp) do
		table.insert(t, k)
	end
	table.sort(t, function (a, b) return a.number < b.number end)
	return t
end

function state_funcs:IntersectPlayers(...)
	local t = {}
	local counts = {}
	local n = #arg
	for k,v in ipairs(arg) do
		for _,p in pairs(v) do
			counts[p] = (counts[p] or 0) + 1
		end
	end
	for k,v in pairs(counts) do
		if v == n then
			table.insert(t, k)
		end
	end
	table.sort(t, function (a, b) return a.number < b.number end)
	return t
end


function state_funcs:IncreasePursuit()
	self:PushState('increase_pursuit')
end

function state_funcs:CylonJumpsIn(k)
	local v = self.cylon_fleet_board[k]
	local t = self.space[k]
	for i,j in pairs(v) do
		if i == 'basestar' then
			t.basestar = t.basestar or {}
			for k,l in pairs(j) do
				table.insert(t.basestar, l)
			end
		else
			t[i] = (t[i] or 0) + j
		end
	end
	self.cylon_fleet_board[k] = {}
end

function state_funcs:NothingHappensActivation(activation, ship)
	if self.cylon_fleet then
		if ship == 'heavy' then
			-- if we have boarders then they prevent this from triggering
			for k,v in pairs(self.boarding_track) do
				if v > 0 then return end
			end
		end

		self:IncreasePursuit()

		-- whoops, something does happen!
		self:PushState('placement_cylon_fleet_board', {what=ship})
		self:PushState('do_roll', {why='cylon fleet placement of ' .. names[ship]})
	end
end

function state_funcs:NoShipsToActivate(activation, ship)
	if ship == 'raider' then
		-- Basestars launch 2 raiders if possible, otherwise nothing happens
		local found
		for k,v in pairs(self.space) do
			if v.basestar and #v.basestar > 0 then
				found = true
				for _,u in pairs(v.basestar) do
					if not u.damage_hangar then
						self:DeployShips('raider', 2, k)
					end
				end
			end
		end
		if found then return end
	elseif ship == 'heavy' then
		-- Basestars launch a heavy is possible, otherwise nothing happens
		local found
		for k,v in pairs(self.space) do
			if v.basestar and #v.basestar > 0 then
				found = true
				for _,u in pairs(v.basestar) do
					if not u.damage_hangar then
						self:DeployShips('heavy', 1, k)
					end
				end
			end
		end
		if found then return end
	elseif ship == 'basestar' then
		-- Nothing to try
	else
		panic("Unknown ship type '%s'", ship or '?')
	end

	-- Nothing happens
	self:NothingHappensActivation(activation, ship)
end

function state_funcs:CenturionBoarded(qty)
	self:ResultLog("%d centurions have boarded Galactica!", qty)
	self.boarding_track[1] = self.boarding_track[1] + qty
end

function state_funcs:GetUnusedCivLabel()
	local civ_labels = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'}
	local used_labels = {}
	for k,v in pairs(self.space) do
		if v.civ then
			for _,u in pairs(v.civ) do
				used_labels[u.label] = true
			end
		end
	end
	for k,v in ipairs(civ_labels) do
		if not used_labels[v] then
			return v
		end
	end
end

function state_funcs:FixCylonCounts()
	local counts = {}
	for k,v in pairs(self.space) do
		for i,j in pairs(v) do
			counts[i] = (counts[i] or 0) + ((type(j) == 'table' and #j) or j)
		end
	end
	for k,v in pairs({'raider','heavy','basestar'}) do
		self[v] = self.maximums[v] - (counts[v] or 0)
	end
end

function state_funcs:DeployShips(what, qty, where, cylon_fleet_board)
	self:FixCylonCounts()
	local desc = {basestar = 'jumps into', raider = 'jumps into', heavy='launches in', viper='launches to', viper7='launches to', araptor = 'launches to'}
	local board = self.space

	if where ~= nil and type(where) == 'string' then
		-- deploy directly
		if cylon_fleet_board then
			board = self.cylon_fleet_board
		end
	else
		if what == 'civ' then
			if self.cag then
				self:PushState('cag_to_place_civ', {qty=qty})
				return
			end
			panic("Placing civ in unknown location without CAG!")
		end
		
		if self.cylon_fleet then
			cylon_fleet_board = true
			board = self.cylon_fleet_board
			if type(where) ~= number then
				where = self:d8()
			end
			local mapping = {'rear', 'paft', 'saft', 'pbow', 'sbow', 'sbow', 'front', 'front' }
			where = mapping[where]
		end
		error("No location for deployment")
	end
	
	if not board[where] then
		error(string.format("Unknown space location: [%s]", where))
	end
	local loc = board[where]
	for i = 1, qty do
		if what == 'basestar' and self.basestar > 0 then
			if not loc.basestar then
				loc.basestar = {}
			end
			table.insert(loc.basestar, {})
			self.basestar = self.basestar - 1
			if cylon_fleet_board then
				self:ResultLog('Basestar deployed to sector %s of the cylon fleet board', names[where])
			else
				self:ResultLog('Basestar jumps in to sector %s', names[where])
			end
		elseif what == 'civ' then
			if #self.civ > 0 then
				local civ = table.remove_random(self.civ)
				if not loc.civ then loc.civ = {} end
				civ.label = self:GetUnusedCivLabel()
				table.insert(loc.civ, civ)
				self:ResultLog('Civilian placed in sector %s', names[where])
			end
		elseif self[what] > 0 then
			self[what] = self[what] - 1
			loc[what] = (loc[what] or 0) + 1
			
			if i == 1 then
				local qtystr = 'A ' .. names[what]
				if qty > 1 then qtystr = string.format('%d %ss', qty, names[what]) end
				if cylon_fleet_board then
					self:ResultLog('%s deployed to sector %s of the cylon fleet board', qtystr, names[where])
				else
					self:ResultLog('%s %s to sector %s', qtystr, desc[what] or 'jumps in', names[where])
				end
			end
		end
	end
end

function state_funcs:AddLoyaltyCard()
	if self.exodus then
		table.insert(self.loyalty_deck, table.remove_random(self.unused_loyalty))
		self.loyalty_deck = shuffle_list(self.loyalty_deck)
	end
end

function state_funcs:DealLoyaltyTo(who, sleeper_mutineer_extra)
	local card = table.remove(self.loyalty_deck, 1)
	if not card then return end
	
	table.insert(who.loyalty, card)
	who:PrivateMsg('Loyalty: ' .. print_loyalty_card(card))
	if card.mutineer then
		self.mutineer = who
		self:ResultLog('%s is the [b]mutineer[/b]', who:full_name())
		if #self.loyalty_deck > 0 and not sleeper_mutineer_extra then
			self:DealLoyaltyTo(who)
			who:DrawMutiny()
			for k,v in pairs({'cag','admiral','president'}) do
				if who == self[v] then
					s:Succession(v, true)
				end
			end
		end
	end
end

function state_funcs:EncounterAlly(who)
	local at = {}
	for k,v in pairs(self.allies) do
		if find_ally(v.name).location == who.location.name then
			table.insert(at, v.name)
		end
	end
	local encounter_choice
	if #at == 1 then
		encounter_choice = at[1]
	elseif #at > 1 then
		encounter_choice = who:Choice(at, 'encounter ally choice')
	end
	if encounter_choice then
		for k,v in pairs(self.allies) do
			if v.name == encounter_choice then
				local ally = table.remove(self.allies, k)
				local trauma = ally.trauma
				local result = find_ally(ally.name)[trauma]
				self.trauma[trauma] = self.trauma[trauma] + 1
				if trauma ~= 'disaster' then
					assert(result)
					result = result.action
				end
				
				self:ResultLog('%s encounters [b]%s[/b] - %s', who:full_name(true), ally.name, names[trauma])
				self:ResultLog('%s', find_ally(ally.name).desc or '')

				self:PushState('place_new_ally',{reason='encounter', who=who})
				if result then
					self:Resolve(result)
				end
				break
			end
		end
	end
end

function state_funcs:Execute(who)
	local is_current = (who == self.current)
	local is_cylon = who:HiddenCylon()
	if is_cylon then
		self:ResultLog('%s is executed and is a cylon!', who:full_name(true))
	else
		self:ResultLog('%s is executed and is human!', who:full_name(true))
	end
	if is_current then
		self:PushState('end_turn')
	end
	if is_cylon then
		local n = #who.hand
		if n > 0 then
			who:DiscardCards(n, true)
		end
		self:PushState('reveal', {src='executed', who=who})
	else
		local name = self:GMChoice(nil, 'new character')
		local char = find_char(name)
		local orig_char = find_char(who.name)
		assert(char)
		who:DiscardCards(#who.hand, true)
		self:ResolveEffectsNow{morale=-1}
		who.miracle = 0
		who.trauma = {benevolent = 0, antagonistic = 0}
		
		who:MoveTo(char.start)
		
		local effects = {}
		if #who.loyalty > 0 then
			self:ResultLog('Loyalty cards:')
			for k,v in ipairs(who.loyalty) do
				self:ResultLog(print_loyalty_card(v))
				if v.final5 then
					effects.draw_cards = {human=-2}
				end
			end
		end
		self:Resolve(effects)
		
		who:DiscardMutiny('all')
		
		local titles = {}
		for k,v in ipairs{'admiral','cag','president'} do
			if self[v] == who then tins(titles, v) end
		end
		
		-- install the new character now
		for k,v in pairs(orig_char) do
			who[k] = nil
		end
		for k,v in pairs(char) do
			who[k] = v
		end
		
		if self.exodus then
			self:ResultLog('%s is dealt a new loyalty card', who:full_name(true))
			self:AddLoyaltyCard()
			self:DealLoyaltyTo(who)
		end
		
		if #titles > 0 then
			panic()
		end
	end
end

function state_funcs:UnusedCivLabel()
	local civ_labels = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'}
	local used_labels = {}
	for k,v in pairs(self.space) do
		for _,u in pairs(v.civ or {}) do
			used_labels[u.label] = true
		end
	end
	for k,v in ipairs(civ_labels) do
		if not used_labels[v] then
			return v
		end
	end
end

function state_funcs:PilotMove(pilot, to)
	local sector, idx = pilot:FindSpaceSector()
	local new_sector = self.space[to]
	local what = sector.pilots[idx].what
	new_sector[what] = (new_sector[what] or 0) + 1
	sector[what] = sector[what] - 1
	if not new_sector.pilots then new_sector.pilots = {} end
	tins(new_sector.pilots, table.remove(sector.pilots, idx))
	self:ResultLog('%s piloting a %s moves to sector %s', pilot:full_name(true), names[what], names[to])
end

function state_funcs:ViperActivation(t, move_only, nomove, shootonly)
	local chooser = self.acting
	local pilot, sector, sectoridx
	local what
	if t.name then
		pilot = t
		chooser = t
		sector, sectoridx = pilot:FindSpaceSector()
		if not sector then panic('cant find pilot sector') end
		what = sector.pilots[sectoridx].what
	else
		sector = t
		local choices = {}
		if t.viper and t.viper > 0 then
			tins(choices, 'viper')
		end
		if t.viper7 and t.viper7 > 0 then
			tins(choices, 'viper7')
		end
		if (t.araptor or 0) > 0 then
			tins(choices, 'raptor')
		end
		if #choices == 0 then panic() end
		what = chooser:Choice(choices, 'activate what?')
	end
	
	local area
	for k,v in pairs(self.space) do
		if v == sector then area = k end
	end
	
	-- now, figure out what to do with this viper
	local choices = {'move'}
	if nomove or shootonly then choices = {} end
	if not move_only then
		if not shootonly and self.exodus and sector.civ and #sector.civ > 0 then tins(choices, 'escort') end
		for k,v in ipairs({'raider','scar','heavy'}) do
			if sector[v] and sector[v] > 0 then tins(choices, v) end
		end
		if sector.basestar and #sector.basestar > 0 then tins(choices,'basestar') end
		if (pilot or self.acting):HasCard('Best of the Best') then
			tins(choices, 'botb')
		end
	end
	
	if #choices == 0 then return end
	
	local choice = chooser:Choice(choices, 'Do what?')
	if choice == 'move' then
		local range = 1
		if what == 'viper7' then range = 2 end
		local choices = {}
		for k,v in ipairs(SpaceAreas) do
			local d = math.abs(GetSpaceDistance(area, v))
			if d > 0 and d <= range then
				tins(choices, v)
			end
		end
		local choice = chooser:Choice(choices, 'Move where?')
		if pilot then
			self:PilotMove(pilot, choice)
		else
			local new_sector = self.space[choice]
			new_sector[what] = (new_sector[what] or 0) + 1
			sector[what] = sector[what] - 1
			self:ResultLog('Unmanned viper in %s moves to %s', names[area], names[choice])
		end
	elseif choice == 'escort' then
		local choices = {}
		if not sector.civ then panic() end
		for k,v in pairs(sector.civ) do
			tins(choices, v.label)
		end
		local choice = chooser:Choice(choices, 'escort which?')
		for k,v in pairs(sector.civ) do
			if v.label == choice then
				self:ResultLog('Civilian %s is escorted off', v.label)
				v.label = nil
				tins(self.civ, table.remove(sector.civ, k))
				return true
			end
		end
		return false
	elseif choice == 'botb' then
		local who = (pilot or self.acting)
		who:PlayCard('Best of the Best')
		self:PushState('best_of_the_best', {acting=who})
		self:PushState('do_roll', {why="best of the best"})
	else
		-- attacking something
		self:PushState('resolve_attack', {desc='Viper attacks '..names[choice], target=choice, by='viper', area=area})
	end
	
	return true
end

function state_funcs:SleeperPhase()
	-- Everybody gets a new loyalty card, Boomer gets 2 and goes to the brig
	-- Cylon leaders in Daybreak get new motives
	self:ResultLog('Sleeper phase is activated')
	for k,v in ipairs(self.players) do
		if v.type == 'cylon' then
			self:DaybreakLeaderMissions(v)
		else
			self:DealLoyaltyTo(v)
		end
	end
	local boomer = self:FindPlayer('boomer')
	if boomer then
		self:DealLoyaltyTo(boomer)
		self:ResultLog('Boomer is brigged')
		boomer:MoveTo('Brig')
	end
end

function state_funcs:Resolve(e, even_if_nil)
	if e or even_if_nil then
		self:PushState('resolve_effects', {effect=e})
	end
end

function state_funcs:ResolveEffectsNow(effects)
	self:ResolveEffectsInternal{effect=effects}
end

do
	local function mod_resource(state, info, n, t)
		if t == 'distance' then
			if state.distance < 4 and state.distance + n >= 4 then
				state:SleeperPhase()
			end
			if state.ionian_nebula and state.distance < 8 and state.distance + n >= 8 then
				state.crossroads = true
				state:ResultLog('Activating crossroads phase')
			end
		end
		if n < 0 and state.flags.iron_will_triggered then
			state:ResultLog('Iron will prevents loss of %s', t)
			return
		end
		if n < 0 and state.flags.preventativepolicy == t then
			state:ResultLog('Preventative Policy prevents the loss of 1 %s', t)
			state.turn_flags.preventativepolicy = nil
			n = n + 1
		end
		if n ~= 0 then
			state[t] = state[t] + n
			if state[t] < 0 then state[t] = 0 end
			if state.maximums and state.maximums[t] and state.maximums[t] < state[t] then state[t] = state.maximums[t] end
			if n > 0 then
				state:ResultLog('%s increases to %d', names[t] or t, state[t])
			else
				state:ResultLog('%s decreases to %d', names[t] or t, state[t])
				local p = state:FindPlayer('hotdog')
				if p and t == 'pop' then
					-- do hot dog's memento ability
					state:PushState('memento_effect', {})
				end
			end
		end
	end
	
	function add_card_qty(deltas, who, v)
		if not deltas[who] then deltas[who] = {} end
		if type(v) == "number" then
			if v < 0 then
				deltas[who].any = (deltas[who].any or 0) + v
			else
				deltas[who].set = (deltas[who].set or 0) + v
			end
		else
			for t,n in pairs(v) do
				deltas[who][t] = (deltas[who][t] or 0) + n
			end
		end
	end
	
	local function card_draw_discard_func(state, info, draw_list, name)
		local deltas = {}
		local random_discard = false
		if name == 'random_discard' or state.current.name == 'Lee "Apollo" Adama' then
			random_discard = true
			if type(draw_list) == 'number' then
				local n = draw_list
				draw_list = {acting=n}
			end
		end

		-- this takes care of both transforming to a standard
		-- format (set / any / pol/lea/tac/etc)
		-- and combining cases where multiple people discard
		-- but they're the same person, and expanding all
		-- players
		for k,v in pairs(draw_list) do
			for _,u in ipairs(state:FilterPlayers(k)) do
				add_card_qty(deltas, u.number, v)
			end
			if k == 'quorum' then
				if not random_discard then panic() end
				for i=1,v do
					local card = table.remove_random(state.quorum_hand)
					if card then
						state:ResultLog('Quorum card discarded: %s', card)
						state.quorum_deck:discard(card)
					end
				end
			end
		end

		for k,v in pairs(deltas) do
			-- make [k] draw [v] cards
			local who = state.players[k]
			if type(v) == 'number' and v < 0 then
				who:DiscardCards(-v, random_discard)
				v = -math.abs(v)
			else
				for j,u in pairs(v) do
					if not random_discard and u > 0 then
						if j == 'set' or j == 'any' then
							who:DrawCards(u, j == 'any')
						else
							local t = {}
							t[j] = u
							who:DrawSpecificCards(t)
						end
					elseif random_discard or u < 0 then
						who:DiscardCards(math.abs(u), random_discard)
					end
				end
			end
		end
	end
	
	local function force_move(s,i,v,k)
		local filters = {}
		if v.who then tins(filters, v.who) end
		if v.from then tins(filters, 'loc:' .. v.from) end
		if v.chooser then
			s.chooser = s[v.chooser]
			if v.not_self then tins(filters, '!chooser') end
		end
		local p = s:FilterPlayers(filters)
		if v.chooser then
			local opt = (k == 'choice_force_move' and not v.forced)
			if opt then tins(p, 1, 'none') end
			local p = s.chooser:Choice(p, 'Move who to ' .. v.to .. (opt and ' (optional)' or ''))
			if p ~= 'none' then
				p:MoveTo(v.to)
				s:ResultLog('%s moves to %s', p:full_name(true), p.location.name)
			end
		else
			for k,pp in ipairs(p) do
				pp:MoveTo(v.to)
				s:ResultLog('%s moves to %s', pp:full_name(true), pp.location.name)
			end
		end
	end


	local function nothing() end
	
	local effect_list = {
		morale = mod_resource,
		food = mod_resource,
		pop = mod_resource,
		fuel = mod_resource,
		raptor = mod_resource,
		raptors = function(s,i,v,k) return mod_resource(s,i,v,'raptor') end,
		distance = mod_resource,
		nukes = mod_resource,

		try = function(s, i, v,k)
			s:PushState('try', v)
		end,
		check = function(s, i, v,k)
			s:PushState('do_check', {info=v})
		end,
		choice = function(s,i,v,k)
			s:PushState('make_choice', i)
		end,
		civ = function (s,i,v,k)
			if v < 0 then
				s:PushState('destroy_civs', {qty=-v})
			else
				panic()
			end
		end,
		execute_in_location = function(s,i,v,k)
			local who = s.current
			local list = s:FilterPlayers('loc:' .. who.location.name)
			local target = who:Choice(list)
			s:Execute(target)
		end,
		execute = function (s,i,v,k)
			local who = s[v] or s[v.who]
			if not who then
				if v.who == 'choice' then
					local chooser = s[v.chooser]
					local choices = s:FilterPlayers('!' .. v.chooser)
					if not v.forced then
						tins(choices, 'pass')
					end
					local choice = chooser:Choice(choices, 'Execute who?')
					if choice == 'pass' then
						s:ResultLog('%s chooses to execute nobody', chooser:full_name(true))
						return
					end
					who = choice
				else
					panic()
				end
			end
			s:Execute(who)
		end,
		choice_force_move = force_move,
		force_move = force_move,
		place_basestar = function (s,i,v,k) s:DeployShips('basestar', 1, v) end,
		set_flag = function (s,i,v,k) s.flags[v] = true end,
		set_turn_flag = function (s,i,v,k) s.turn_flags[v] = true end,
		centurion = function (s, i, v, k) s:CenturionBoarded(v) end,
		new_crisis = function (s, i, v, k) s.turn_flags.new_crisis = true end,
		vipers = function (s, i, v, k)
			-- repair or damage reserve vipers
			s:PushState('repair_reserve_vipers', {qty=v, who=s.acting})
		end,
		space_vipers = function (s, i, v, k)
			if v == 'reserve' then
				s:ResultLog('All vipers in space return to the reserves')
				for k,v in pairs(s.players) do
					if v.location.ship == 'viper' then
						s:ResultLog('%s lands in the Hangar Deck', v:full_name(true))
						v:MoveTo('Hangar Deck')
					end
				end
				for k,v in pairs(s.space) do
					for _,type in pairs({'viper','viper7','araptor'}) do
						s[type] = s[type] + (v[type] or 0)
						v[type] = 0
					end
				end
			else
				s:PushState('damage_space_vipers', {qty=-v})
			end
		end,
		place_raiders = function (s, i, v, k) return s:DeployShips('raider', v.qty, v.at) end,
		place_civ = function(s, i, v, k)
			if type(v) == "number" then
				s:DeployShips('civ', v)
			elseif type(v) == "string" then
				s:DeployShips('civ', 1, v)
			elseif type(v) == "table" then
				s:DeployShips('civ', v.qty or 1, v.at)
			else
				panic("Bad place_civ table")
			end
		end,
		force_title_change = function(s, i, v, k)
			if v.chooser then
				s:Resolve({choose_player={filter='human', why='become ' .. v.title,
					effect={force_title_change={to='chosen', title=v.title}}}})
			elseif v.to then
				local who_to = s[v.to]
				local old_name = who_to:full_name(true)
				s[v.title] = who_to
				local new_name = who_to:full_name()
				s:ResultLog("%s becomes %s", old_name, new_name)
				if v.title == 'president' then
					who_to:PrivateMsg('Quorum Hand:')
					for k,v in pairs(s.quorum_hand) do
						who_to:PrivateMsg(find_quorum(v).desc .. '\n--')
					end
				end
			elseif v.abdicate then
				local to = s:Succession(v.title, true)
				local old_name = to:full_name(true)
				s[v.title] = to
				local new_name = to:full_name()
				s:ResultLog("%s becomes %s", old_name, new_name)
			else
				panic("Title change needs 'chooser' or 'to'")
			end
		end,
		card_draws = card_draw_discard_func,
		draw_cards = card_draw_discard_func,
		random_discard = card_draw_discard_func,
		jump_prep = function (s, i, v, k)
			if v < 0 then
				s.jump_track = s.jump_track + v
				if s.jump_track < 0 then s.jump_track = 0 end
				s:ResultLog('Jump Track decreases to %d', s.jump_track)
			else
				s.jump_track = s.jump_track + v
				s:ResultLog("Jump prep increases by %d", v)
			end
			if s.jump_track >= 5 then
				s:PushState('jump', {})
			end
		end,
		activate_hangar_deck = function(s,i,v,k)
			local who = s.acting
			local where = who:Choice({'pbow','paft'}, 'Launch to where?')
			if not s:LaunchViper(where, who) then
				panic()
			end
			s:PushState('action',{requires_human=true})
		end,
		activate_presidents_office = function(s,i,v,k)
			if s.daybreak then
				s:Resolve({card_draws = { acting={pol=2} }})
			else
				s:PushState('presidents_office')
			end
		end,
		activate_press_room = function(s,i,v,k)
			if s.daybreak then
				s:PushState('daybreak_press_room', {})
			else
				s:Resolve({card_draws = { acting={pol=2} }})
			end
		end,
		activate_quorum = function(s,i,v,k)
			s:PushState('presidents_office')
		end,
		activate_caprica = function(s,i,v,k) s:PushState('activate_caprica',{}) end,
		maximum_firepower = function(s,i,v,k) s:PushState('viper_activations',{t=s.acting, qty=4, shootonly=true}) end,
		executive_order = function(s,i,v,k) s:PushState('executive_order',{}) end,
		activate_weapons_control = function(s,i,v,k)
			s:PushState('resolve_attack', {by='galactica', target='choice', who=s.active})
		end,
		launch_scout_effect = function(s,i,v,k) s:PushState('launch_scout_effect', table.copy(v)) end,
		damage = function(s,i,v,k) s:PushState('damage', {qty=v}) end,
		activate = function(s,i,v,k)
			if type(v) == 'string' then
				s:ActivateCylonShip(v)
			else
				for i=#v,1,-1 do
					s:ActivateCylonShip(v[i])
				end
			end
		end,
		placement = function(s,i,v,k)
			for area,list in pairs(v) do
				for type,qty in pairs(list) do
					s:DeployShips(type, qty, area)
				end
			end
		end,
		baltar_ally_antagonistic=function(s,i,v,k)
			-- add a "not a cylon" card into the deck
			panic()
		end,
		centurion_retreat=function(s,i,v,k)
			self:ResultLog('Centurions retreat!')
			self.boarding_track[1] = self.boarding_track[1] + self.boarding_track[2]
			self.boarding_track[2] = self.boarding_track[2] + self.boarding_track[3]
			self.boarding_track[3] = self.boarding_track[3] + self.boarding_track[4]
			self.boarding_track[4] = 0
			for k,v in pairs(self.boarding_track) do
				if v > 4 then self.boarding_track[k] = 4 end
			end
		end,
		baltar_ally_antagonistic=function(s,i,v,k)
		end,
		unmanned_activation = function(s,i,v,k)
			if type(v) == 'boolean' then v = 1 end
			if type(v) == 'table' then v = v.qty end
			s:PushState('viper_activations', {qty=v})
		end,
		unmanned_activations = function(s,i,v,k)
			if type(v) == 'boolean' then v = 1 end
			s:PushState('viper_activations', {qty=v})
		end,
		look_at_loyalty = function(s,i,v,k) panic() end,
		card_draws_to_tre=function(s,i,v,k)
			local who = {}
			for i,j in pairs(v) do
				local t = s:FilterPlayers(i)
				for k,v in pairs(t) do
					who[v] = (who[v] or 0) + j
				end
			end
			local t = s:SortTurnOrder(who)
			for k,v in ripairs(t) do
				s:PushState('card_draws_to_tre', {who=v, qty=who[v]})
			end
		end,
		damage_any_vipers=function(s,i,v,k)
			s:PushState('damage_vipers', {qty=v})
		end,
		strange_beacon_effect=function(s,i,v,k)
			local choice = self.acting:Choice(space_areas, 'where?')
			local space = self.space[choice]
			self:ResultLog('All cylon ships in %s are destroyed', names[choice])
			space.raider = nil
			space.heavy = nil
			space.basestar = nil
		end,
		mysterious_message_effect=function(s,i,v,k) self:PushState('mysterious_message_effect', {}) end,
		land_all_vipers=function(s,i,v,k) panic() end,
		pursuit=function(s,i,v,k) s:PushState('increase_pursuit') end,
		cylon_genocide=function(s,i,v,k)
			s:ResultLog('All cylon ships are destroyed')
			for k,v in pairs(s.space) do
				for _k,_v in pairs({raider=0, heavy=0, basestar={}}) do
					v[_k] = _v
				end
			end
		end,
		tre_to_destiny=function(s,i,v,k)
			s:ResultLog('%d treachery cards are added to the destiny deck', v)
			for i=1,v do
				tins(s.destiny_deck, s.skill_decks.tre:draw_top())
			end
			s.destiny_deck = shuffle_list(s.destiny_deck)
		end,
		free_move = function(s,i,v,k)
			self:PushState('movement', {restricted=true})
		end,
		gas_cloud_effect=function(s,i,v,k) panic() end,
		mining_asteroid_effect=function(s,i,v,k) panic() end,
		ragnar_anchorage_effect=function(s,i,v,k)
			if s.raptor < s.maximums.raptor then s.raptor = s.raptor + 1 end
			s:PushState('repair_reserve_vipers', {qty=3, allow_destroyed = true, who=s.admiral})
		end,
		return_to_duty_effect=function(s,i,v,k) panic() end,
		aobf_effect=function(s,i,v,k)
			local choice = s.acting:Choice({'raider','heavy','centurion'}, 'AoBF effect?')
			if choice == 'centurion' then
				s:Resolve({destroy_centurion=1})
			else
				panic()
			end
		end,
		todo=function(s,i,v,k) end,
		pardon_effect=function(s,i,v,k) panic() end,
		civ_self_defense_effect=function(s,i,v,k) panic() end,
		consult_oracle_effect=function(s,i,v,k) panic() end,
		resignation_effect=function(s,i,v,k) panic() end,
		starbuck_benevolent_effect=function(s,i,v,k) panic() end,
		communications_effect=function(s,i,v,k)
			if s.acting.name == 'Anastasia "Dee" Dualla' then
				v.all = true
			end
			panic()
		end,
		hot_dog_effect=function(s,i,v,k)
			local choice = s.acting:Choice(space_areas, 'which area?')
			local space = s.space[choice]
			local r = space.raider or 0
			if r < 0 then r = 0 end
			space.raider = r
		end,
		glimpse_effect=function(s,i,v,k) s:PushState('glimpse_face_of_god', {}) end,
		six_effect=function(s,i,v,k)
			local who = s.chosen
			s.chosen = nil
			local card = table.remove_random(who.hand)
			s.current:PrivateMsg('You got ' .. card:formatted())
			table.insert(s.current.hand, card)
			who:PrivateMsg('Six took ' .. card:formatted())
			local type = s.current:Choice(card_types, 'card to draw')
			local t = {}
			t[type] = 1
			who:DrawSpecificCards(t)
		end,
		activate_brig=function(s,i,v,k)
			local t = {}
			for k,v in pairs(locations) do
				if v.ship == 'galactica' then tins(t, v.alias or v.name) end
			end
			local where = s.acting:Choice(t, 'move to')
			s.acting:MoveTo(where)
		end,
		repair_card=function(s,i,v,k)
			local who = s.acting
			if who.location.name == 'Hangar Deck' and who:Choice({'y','n'}, 'repair vipers?') == 'y' then
				panic()
			elseif s.damage[who.location.name] then
				s:ResultLog('%s is repaired', who.location.name)
				s.damage[who.location.name] = nil
			else
				panic()
			end
		end,
		critical_situation = function(s,i,v,k)
			s:PushState('action',{requires_human=true})
		end,
		activate_ftl_control = function(s,i,v,k)
			if s.jump_track > 2 then
				s:PushState('jump', {})
				s:Resolve{try={roll=6, fail={pop=-(1-2*(s.jump_track - 4))}}}
			end
		end,
		trauma = function(s,i,v,k)
			s:PushState('draw_trauma', {qty=v, who=s.current, random=v.random})
		end,
		draw_trauma = function(s,i,v,k) s:PushState('draw_trauma', {qty=v}) end,
		crossroads_strange_music = function(s,i,v,k)
			s:ResultLog('%s is dealt a new loyalty card', s.acting:full_name(true))
			s:AddLoyaltyCard()
			s:DealLoyaltyTo(s.acting)

			for k,v in ipairs(s.players) do
				if v.type ~= "cylon" and v:Cylon() then
					s:PushState('draw_trauma', {qty=1, who=v})
				end
			end
		end,
		crossroads_miraculous_return_antagonistic = function(s,i,v,k)
			local c = s:GMChoice(space_areas, 'which basestar')
			s:PushState('damage', {ship='basestar', area=c})
		end,
		damage_choice = function(s,i,v,k)
			local who = v.chooser or s.acting
			s:PushState('damage_choice', {who=who, choice=v.choice, qty=v.qty})
		end,
		discard_trauma = function(s,i,v,k)
			local who = s.chosen or s.acting
			for i=1,v do
				local t = who:RemoveSelectedTrauma()
				if t then
					s.trauma[t] = s.trauma[t] + 1
				end
			end
		end,
		activate_cylon_fleet = function(s,i,v,k)
			local choice = s.acting:Choice({'raider','heavy','basestar','launch'}, 'cylon fleet action?')
			if choice == 'launch' then
				panic()
			else
				s:ActivateCylonShip(choice)
			end
		end,
		damage_vipers = function(s,i,v,k)
			s:PushState('damage_vipers', (type(v) == 'number' and {qty=v, space=true, reserve=true}) or v)
		end,
		activate_basestar_bridge = function(s,i,v,k)
			s:PushState('basestar_bridge', {})
		end,
		draw_supercrisis = function(s,i,v,k)
			local who = s.acting
			local sc = table.remove(self.supercrisis_deck)
			if not who.supercrisis then who.supercrisis = {} end
			table.insert(who.supercrisis, sc)
			who:PrivateMsg('Supercrisis: %s', find_supercrisis(sc).desc)
		end,
		lee_ally_benevolent=function(s,i,v,k)
			for k,v in pairs(s.space) do
				local n = (s.viper or 0) + (s.viper7 or 0) - ((self.pilots and #self.pilots) or 0)
				local r = s.raider - n
				if r < 0 then r = 0 end
				if r ~= s.raider then
					self:ResultLog('%d raiders are destroyed in %s', s.raider - r, names[k])
				end
				s.raider = r
			end
		end,
		activate_communications = function(s,i,v,k)
			s:PushState('communications_effect', {who=s.acting})
		end,
		full_throttle = function(s,i,v,k)
			s:PushState('full_throttle', {})
		end,
		best_of_the_best = function(s,i,v,k)
			s:PushState('best_of_the_best', {})
			s:PushState('do_roll', {why='Best of the best roll'})
		end,
		trash_card = function(s,i,v,k) s.trash_card = true end,
		activate_human_fleet = function(s,i,v,k)
			s:PushState('human_fleet', {})
		end,
		captains_cabin_effect = function(s,i,v,k)
			local choice = s.acting:Choice(card_types, 'card type')
			local t = {card_draws={all={}}}
			t.card_draws.all[choice] = 1
			s:Resolve(t)
		end,
		quorum_assign = function(s,i,v,k)
			local p = s.acting:Choice(s.players)
			s:ResultLog('%s becomes the %s', p:full_name(true), names[v])
			s[v] = p
		end,
		draw_mutiny = function(s,i,v,k)
			local players = s:FilterPlayers(v)
			for i,j in pairs(players) do
				j:DrawMutiny()
			end
		end,
		preventative_policy = function(s,i,v,k)
			local res = s.current:Choice({'fuel','morale','pop','food'}, 'which resource?')
			s.preventative_policy = res
		end,
		popular_influence = function(s,i,v,k)
			s:PushState('popular_influence', {})
		end,
		start_mission = function(s,i,v,k)
			s:PopState('pre_crisis')
			s:PushState('pre_mission', {})
		end,
		retry_mission = function(s,i,v,k) s.current_mission_facedown = true end,
		activate_pegasus_batteries = function(s,i,v,k)
			local area = s.acting:Choice(space_areas, 'where')
			s:PushState('resolve_main_batteries', {where=area})
			s:PushState('do_roll', {why='main batteries activation'})
		end,
		state_of_emergency = function(s,i,v,k)
			s:PushState('exec', {who=s.acting, text=[[state.acting = sub.who]]})
			for k,v in pairs(s:SortTurnOrder(s:FilterPlayers('human'), true)) do
				s:PushState('action', {set_acting=v, allow_move=true})
			end
		end,
		combat_veteran = function(s,i,v,k)
			s:PushState('combat_veteran',{n=3, who=s.acting})
		end,
		launch_reserves = function(s,i,v,k)
			s:PushState('combat_veteran',{n=4, who=s.acting})
		end,
		choose_player = function(s,i,v,k)
			s:PushState('nilify', {k='chosen'})
			local set = s:FilterPlayers(v.filter or 'all')
			local who = s:GMChoice(set, v.why or 'choose_player')
			if who then s.chosen = who end
			s:PushState('clear_chosen')
			s:Resolve(v.effect or v)
		end,
		crossroads_scanned = function(s,i,v,k)
			for i=1,4 do
				local c = s:GMChoice(space_areas, 'remove raider at')
			end
		end,
		administration = function(s,i,v,k)
			if s.daybreak then
				local who = s.acting
				who:DrawMutiny()
				if #s.president.mutiny_hand > 0 then
					s:Resolve({force_title_change={title="president", chooser="acting"}})
				end
			else
				local check={val=5,pol=true,lea=true,pass={force_title_change={title="president", chooser="acting"}}}
				s:Resolve(check)
			end
		end,
		hoshi_opg=function(s,i,v,k)
			local list = {}
			for k,v in pairs(locations) do
				if v.ship ~= 'cylon' and not s.damage[v.name] and v.action then
					tins(list, v.name)
				end
			end
			local choices = {}
			for i=1,3 do
				local choice = s.acting:Choice(list, 'activatte which?')
				table.remove_specific(list, choice)
				tins(choices, find_location(choice).action)
				if choice == 'Command' or choice == 'Communications' or choice == 'Weapons Control' then
					s:PushState('hoshi_extra_activate', {what=choice})
				end
			end
			s:Resolve{sequence=choices}
		end,
		destroy_centurion = function(s,i,v,k)
			for i=4,1,-1 do
				if s.boarding_track[i] > 0 then
					s.boarding_track[i] = s.boarding_track[i] - 1
					s:ResultLog('A centurion is destroyed!')
					s:PushState('major_victory_check')
				end
			end
		end,
		insubordinate_effect = function(s,i,v,k)
			for k,v in ipairs(s.players) do
				if not v:Cylon() then
					if not v.mutiny_hand then v.mutiny_hand = {} end
					if #v.mutiny_hand == 0 then
						s:PushState('draw_mutiny', {who=v})
					end
				end
			end
		end,
		activate_pegasus_cic = function(s)
			s:PushState('resolve_attack', {by='pegasus', target='basestar', who=s.active})
		end,
	}

	function state_funcs:ResolveSingleEffect(name, result, effect)
		local f = effect_list[name] or self['resolve_' .. name]
		if f then
			if type(f) == 'function' then
				f(self, effect, result, name)
			elseif type(f) == 'string' then
				self:PushState(f, result)
			else
				self:Resolve(result)
			end
		else
			panic('unknown effect: ' .. name)
		end
	end
end

-- return true if finished
function state_funcs:ResolveEffectsInternal(info)
	local e = info.effect
	local order = info.order
	if not order then
		-- decide what order we're doing things in\

		local done = {sequence=true,a=true,b=true,condition=true,desc=true,mapping=true,}
		-- the sequence element first
		info.order = {'sequence'}
		order = info.order
		
		-- numerical elements
		for k,v in ipairs(e) do
			tins(order, k)
			done[k] = true
		end
		
		-- in order specified
		for k,v in ipairs({
				'food','fuel','morale','pop',
			}) do
			done[v] = true
			tins(order, v)
		end
		
		local tmp = {}
		for k,v in pairs(e) do
			if type(k) == 'string' and not done[k] then
				done[k] = true
				tins(tmp, k)
			end
		end
		
		-- alphabetical for everything else
		table.sort(tmp)
		for k,v in ipairs(tmp) do tins(order, v) end
	end
	
	while #order > 0 do
		local k = order[1]
		local v = e[k]
		if not v then
			-- no effect by this name
			table.remove(order, 1)
		elseif type(k) == 'number' or k == 'sequence' then
			-- these only ever contain lists of effects
			table.remove(order, 1)
			self:Resolve(v)
			return
		else
			self.state_changed = nil
			self:ResolveSingleEffect(k, v, e)
			table.remove(order, 1)
			if self.state_changed then return end
		end
	end
	return true
end

function state_funcs:GetShipDamageTokens(ship)
	local t = {}
	for k,v in pairs(locations) do
		if v.damageable and v.ship == ship and not self.damage[v.name] then
			tins(t, v.name)
		end
	end
	if ship == 'galactica' then
		if not self.food_token_hit then tins(t, 'food') end
		if not self.fuel_token_hit then tins(t, 'fuel') end
	end
	return t
end

function state_funcs:DamageLocation(name)
	if name == 'fuel' then
		self:Resolve({fuel=-1})
		self.fuel_token_hit = true
	elseif name == 'food' then
		self:Resolve({food=-1})
		self.food_token_hit = true
	else
		self:ResultLog('%s is damaged\n', name)
		self.damage[name] = true

		-- allies get removed
		if self.allies then
			local allies = {}
			for i,j in ipairs(self.allies) do
				if find_ally(j.name).location ~= name then
					tins(allies, j)
				else
					self:PushState('place_new_ally',{reason='destroyed'})
					self:ResultLog('%s is removed', j.name)
					self.trauma[j.trauma] = self.trauma[j.trauma] + 1
				end
			end
			self.allies = allies
		end
	end
	
	for i,j in ipairs(self.players) do
		if j.location and j.location.name == name then
			self:ResultLog('%s is sent to Sickbay', j:full_name(true))
			j:MoveTo('Sickbay')
		end
	end
	
	-- check if pegasus is destroyed
	if not self.pegasus_destroyed then
		local destroyed = true
		for k,v in pairs(locations) do
			if v.ship == 'pegasus' and not self.damage[v.name] then
				destroyed = false
				break
			end
		end
		if destroyed then
			self.pegasus_destroyed = true
			self:ResultLog('Pegasus is destroyed!')
			for k,v in ipairs(self.players) do
				if v.location.ship == 'pegasus' then
					self:ResultLog('%s is sent to Sickbay', v:full_name())
					self:MoveTo('Sickbay')
				end
			end
		end
	end
end

-- This just draws the card
function state_funcs:DrawQuorumCard()
	local name = self.quorum_deck:draw_top()
	return name, find_quorum(name)
end

-- This draws the card to the quorum hand
function state_funcs:DrawQuorumCardToHand()
	local name, card = self:DrawQuorumCard()
	tins(self.quorum_hand, name)
	self.president:PrivateMsg('New Quorum Card: %s', card.desc)
	self:ResultLog('The president draws a Quorum card')
end

function state_funcs:DrawDestiny()
	local card = table.remove(self.destiny_deck)
	-- Personally, I prefer an 18 card variant for DDs where at 6 cards an additional
	-- 12 get dealt in, limiting the usefulness of card tracking
	if #self.destiny_deck == 0 or (#self.destiny_deck <= 6 and self.large_destiny_variant) then
		self:MakeNewDestinyDeck()
	end
	return card
end

function state_funcs:CheckPlayInterrupt(card, filter)
	if self:CheckForCard(card, filter) then
		if self:GMChoice({'n','y'}, card .. ' played?') == 'y' then
			if self:PlayInterrupt(card, filter) then
				return true
			end
		end
	end
end

function state_funcs:CheckForCard(name, filter)
	for k,v in ipairs(self:FilterPlayers(filter or 'human')) do
		if v:CheckForCard(name) then return true end
	end
end

function player_funcs:HasCard(name)
	for k,v in ipairs(self.hand) do
		if v.name == name then
			return true
		end
	end
	return false
end

function player_funcs:PlayCard(name)
	local state = self.state
	choices = {}
	for k,v in ipairs(self.hand) do
		if v.name == name then
			tins(choices, v.strength)
		end
	end
	table.sort(choices)
	choice = state:GMChoice(choices, 'Which strength?')
	local card
	for k,v in ipairs(self.hand) do
		if v.name == name and v.strength == choice then
			card = table.remove(self.hand, k)
			break
		end
	end
	if not card then return false end
	state:ToDiscard(card)
	state:ResultLog('%s plays %s', self:full_name(true), card:formatted())
	return true
end

function state_funcs:PlayInterrupt(name, filter)
	local choices = {}
	for k,v in ipairs(self:FilterPlayers(filter or 'human')) do
		if v:CheckForCard(name) then tins(choices, v) end
	end
	
	if #choices == 0 then return end
	
	local choice = self:GMChoice(choices, 'Who will play ' .. name .. '?')
	
	choices = {}
	local who = choice
	
	for k,v in ipairs(who.hand) do
		if v.name == name then
			tins(choices, v.strength)
		end
	end
	table.sort(choices)
	choice = self:GMChoice(choices, 'Which strength?')
	local card
	for k,v in ipairs(who.hand) do
		if v.name == name and v.strength == choice then
			card = table.remove(who.hand, k)
			break
		end
	end
	self:ToDiscard(card)
	self:ResultLog('%s plays %s', who:full_name(true), card:formatted())
	return true, who
end

function state_funcs:InContribOrder()
	local t = self:InTurnOrder()
	table.insert(t, t[1])
	table.remove(t, 1)
	return t
end

function state_funcs:InTurnOrder()
	local t = {}
	for i = self.current.number, #self.players do
		table.insert(t, self.players[i])
	end
	for i = 1, self.current.number - 1 do
		table.insert(t, self.players[i])
	end
	return t
end


--9. Dee's "Fast Learner" (if she decides to add the cards to the skill check, set them aside for the moment)
--Chief of Staff
--Arbitrator
--Cylon Hatred / Friends in Low Places (location modifiers)
--Investigative Committee
--Scientific Research
--and/or one reckless interrupt (Support the People, At Any Cost, Guts & Initiative, Jury Rigged)
function state_funcs:GetSkillCheckInterrupts(info)
	if info.dee_pending then
		local p = self:FindPlayer('dee')
		info.fast_learner_choice = p:Choice({'hand','check'}, 'Add to hand or check?')
		self:ResultLog('Dee chooses to add the cards to: %s', choice)
		if info.fast_learner_choice == 'hand' then
			for k,v in pairs(info.fast_learner_cards) do
				tins(p.hand, v)
			end
			info.fast_learner_cards = nil
		end
		info.dee_pending = nil
	end
	if info.stp_pending then
		while #info.stp_pending > 0 do
			local p = info.stp_pending[1]
			if #p.hand <= 4 then
				p:DrawCards(2)
			end
			table.remove(info.stp_pending, 1)
		end
		info.stp_pending = nil
	end
	
	while true do
		local choices = {'done'}
		p = self:FindPlayer('dee')
		if p and not p.opg_used then tins(choices, 'dee') end
		if not info.reckless then
			if self:CheckForCard('Support the People') then tins(choices, 'StP') end
			if self:CheckForCard('At Any Cost') then tins(choices, 'AAC') end
			if self:CheckForCard('Guts & Initiative') then tins(choices, 'G&I') end
			if self:CheckForCard('Jury Rigged') then tins(choices, 'jury rigged') end
		end
		if not info.ic and self:CheckForCard('Investigative Committee') then tins(choices, 'IC') end
		if not info.scientific and self:CheckForCard('Scientific Research') then tins(choices, 'SR') end
		if self.chief_of_staff then tins(choices, 'chief_of_staff') end
		
		if info.source and info.source == 'location' then
			if info.specific == 'Administration' and FindPlayer('zarek') and not info.zarek_mod then tins(choices, 'zarek') end
			if info.specific == "Admiral's Quarters" and FindPlayer('tigh') and not info.tigh_mod then tins(choices, 'tigh') end
			if info.specific == "Admiral's Quarters" and self.arbitrator then tins(choices, 'arbitrator') end
		end
		
		local choice = self:GMChoice(choices, 'interrupt phase ordering')
		if choice == 'done' then return true end
		
		if choice == 'dee' then
			p = FindPlayer('dee')
			assert(p)
			local choice = p:Choice(card_types, 'Fast learner deck')
			p.opg_used = true
			self:ResultLog('Dee uses her OPG to look at the %s deck', names[choice])
			
			local deck = self.skill_decks[choice]
			info.fast_learner_cards = {}
			p:PrivateMsg('Fast learner cards:')
			for i=1,3 do
				tins(info.fast_learner_cards, deck:draw_top())
				p:PrivateMsg(info.fast_learner_cards[1]:formatted())
			end
			info.dee_pending = true
			return
		end
		
		if choice == 'zarek' then
			local choice = self:FindPlayer('zarek'):Choice({'+','-'}, 'Increase or decrease?')
			info.zarek_mod = true
			if choice == '+' then
				self:ResultLog('Zarek increases the difficulty by 2')
				info.mod = info.mod + 2
			else
				self:ResultLog('Zarek decreases the difficulty by 2')
				info.mod = info.mod - 2
			end
		end
		if choice == 'tigh' then
			info.tigh_mod = true
			self:ResultLog('Tigh decreases the difficulty by 3')
			info.mod = info.mod - 3
		end
		if choice == 'arbitrator' then
			self:ResultLog(sfmt('The arbitrator (%s) increases the difficulty by 3', self.arbitrator.name))
			info.mod = info.mod + 3
			self.arbitrator = nil
		end
		if choice == 'chief_of_staff' then
			self:ResultLog('%s makes [b][color=%s]politics[/color][/b] positive',
				self.chief_of_staff:full_name(true), colors.pol)
			info.chief_of_staff = true
			self.chief_of_staff = nil
		end
		if choice == "StP" then
			info.reckless = self:PlayInterrupt('Support the People')
			info.stp_pending = self:FilterPlayers('human', self:InTurnOrder())
			self:ResultLog('Check is now [b]RECKLESS[/b]')
			return
		end
		if choice == "AAC" then
			info.reckless = self:PlayInterrupt('At Any Cost')
			self:ResultLog('Check is now [b]RECKLESS[/b]')
			info.aac = info.reckless
		end
		if choice == "G&I" then
			info.reckless = self:PlayInterrupt('Guts & Initiative')
			self:ResultLog('Check is now [b]RECKLESS[/b]')
			info.gi = info.reckless
		end
		if choice == "jury rigged" then
			info.reckless = self:PlayInterrupt('Jury Rigged')
			self:ResultLog('Check is now [b]RECKLESS[/b]')
			info.jr = info.reckless
		end
		if choice == "IC" then
			info.ic = self:PlayInterrupt('Investigative Committee')
		end
		if choice == "SR" then
			info.scientific = self:PlayInterrupt('Scientific Research')
		end
	end
end

function state_funcs:GetResourceColor(r)
	local default = {fuel=8, food=8, morale=10, pop=12}
	if self[r] and default[r] then
		local color = 'limegreen'
		local ratio = self[r] / default[r]
		if ratio <= 0.5 then
			color = 'red'
		end
		return color
	end
	return ''
end

function state_funcs:GetSitrepImgUrl()
	local s = self.sitrep_img_base_url or IMAGE_BASE_URL
	if s then
		if s:sub(#s,#s) ~= '/' then s = s .. '/' end
		return s .. sfmt('%s/%s_state_%d.png', self.short_name, self.short_name, self.file_index)
	end
	return ''
end
function state_funcs:GetGalacticaDamageDesc()
	local s = ''
	for k,v in ipairs(locations) do
		if v.ship == 'galactica' and self.damage[k] then
			if s ~= '' then s = s .. ', ' end
			s = s .. v.name
		end
	end
	if s == '' then return 'No damage.' end
	return s
end
function state_funcs:GetPegasusDamageDesc()
	local s = ''
	for k,v in ipairs(locations) do
		if v.ship == 'pegasus' and self.damage[k] then
			if s ~= '' then s = s .. ', ' end
			s = s .. v.name
		end
	end
	if s == '' then return 'No damage.' end
	return s
end
function state_funcs:GetReservesDesc()
	local avail = {}
	local damage = {}
	local str = ''
	if self.viper > 0 then table.insert(avail, self.viper .. ' ' .. names['viper'] ..'s') end
	if self.viper7 and self.viper7 > 0 then table.insert(avail, self.viper7 .. ' ' .. names['viper7'] ..'s') end
	if self.raptor > 0 then table.insert(avail, self.raptor .. ' ' .. names['raptor'] ..'s') end
	if self.damaged_viper > 0 then table.insert(damage, self.damaged_viper .. ' ' .. names['viper'] ..'s') end
	if self.damaged_viper7 and self.damaged_viper7 > 0 then table.insert(damage, self.damaged_viper7 .. ' ' .. names['viper7'] ..'s') end
	local str = ''
	if #avail > 0 then
		str = table.concat(avail, ' and ') .. ' available'
	end
	if #damage > 0 then
		local s = table.concat(damage, ' and ')
		if str == '' then str = s
		else str = str .. ', ' .. s end
		str = str .. ' damaged'
	end
	if str == '' then return 'None.' end
	return str .. '.'
end
function state_funcs:DescribeSpace(space)
	local str = '\n'
	local order = {{"front","Fore (9 o'clock)"}, {"sbow","Starboard-bow (11 o'clock)"}, {"saft", "Starboard-quarter (1 o'clock)"}, {"rear","Aft (3 o'clock)"}, {"paft","Port-quarter (5 o'clock) ",}, {"pbow","Port-bow (7 o'clock)"}}
	
	for k,v in ipairs(order) do
		str = str .. v[2] .. ' - '
		local e = space[v[1]]
		local contents = {}
		
		-- Display order: vipers, civilians, basestars, heavy raiders, scar, raiders
		if e.viper7 and e.viper7 > 0 then table.insert(contents, string.format('%d %ss', e.viper7, names['viper7'])) end
		if e.viper and e.viper > 0 then table.insert(contents, string.format('%d %ss', e.viper, names['viper'])) end
		if e.civ and #e.civ > 0 then table.insert(contents, string.format('%d Civilian Ships', #e.civ)) end
		if e.basestar and #e.basestar > 0 then
			for k,v in ipairs(e.basestar) do
				table.insert(contents, 'Basestar')
			end
		end
		if e.heavy and e.heavy > 0 then table.insert(contents, string.format('%d %ss', e.heavy, names['heavy'])) end
		if e.scar and e.scar > 0 then table.insert(contents, 'Scar') end
		if e.raider and e.raider > 0 then table.insert(contents, string.format('%d %ss', e.raider, names['raider'])) end
		
		if e.pilots and #e.pilots then
			for k,v in ipairs(e.pilots) do
				table.insert(contents, sfmt("%s piloting a %s", v.who:full_name(true), names[v.what]))
			end
		end
		
		if #contents == 0 then table.insert(contents, 'None') end
		str = str .. table.concat(contents, ', ') .. '.\n'
	end
	
	return str
end

function state_funcs:Sitrep()
	local str = ''
	local nospoiler = ''
	
	local function image(url)
		if url and url ~= '' then return '[img]'..url..'[/img]' end
		return ''
	end
	
	local sitrep_url = self:GetSitrepImgUrl()
	
	nospoiler = nospoiler .. sfmt('[b]Turn %d[/b]\n\n', self.turn)
	nospoiler = nospoiler .. '[b]Receive Skills Step[/b]: ' .. self.current:full_name(true) .. (self.recieve_skills_msg or '') .. '\n\n'
	nospoiler = nospoiler .. '[b]Current Situation[/b]\n' .. image(sitrep_url)
	
	local name = 'sitrep_' .. self.state
	if type(self[name]) == 'function' then
		local t = self[name](self)
		if type(t) == 'string' then nospoiler = nospoiler .. t .. '\n' end
	end

	local function fmt_res(r) return sfmt('[color=%s][b]%s - %d[/b][/color]', self:GetResourceColor(r), names[r], self[r]) end
	str = str .. sfmt('[b]Resources[/b]: %s, %s, %s, %s\n', fmt_res('fuel'), fmt_res('food'), fmt_res('morale'), fmt_res('pop'))
	str = str .. sfmt('[b]Jump Preparation[/b]: %s\n', jump_desc(self.jump_track))
	if self.cylon_fleet then
		str = str .. sfmt('[b]Pursuit Track[/b]: Level %d.\n', self.pursuit_track)
	end
	str = str .. sfmt('[b]Distance Covered[/b]: %d\n', self.distance)
	str = str .. sfmt('[b]Galactica[/b]: %s\n', self:GetGalacticaDamageDesc())
	if self.pegasus then
		str = str .. sfmt('[b]Pegasus[/b]: %s\n', self:GetPegasusDamageDesc())
	end
	str = str .. sfmt('[b]Nuke Tokens[/b]: %d remain.\n', self.nukes)
	str = str .. sfmt('[b]Quorum Cards[/b]: %d in hand.\n', #self.quorum_hand)
	str = str .. sfmt('[b]Ship Reserves[/b]: %s\n', self:GetReservesDesc())
	str = str .. sfmt('[b]Mission Status[/b]: %s\n', (function()
		return (self.current_mission_facedown and "Facedown") or
		       (self.current_mission and "Active") or "Inactive"
	end)())
	str = str .. sfmt('[b]Characters[/b]:\n')
	for k,v in ipairs(self.players) do
		local name = v:full_name(true)
		name = name .. ' in ' .. v.location.name
		if v == self.current then
			name = '[u]' .. name .. '[/u] <-- Current Player'
		end
		str = str .. name .. '\n'
	end
	str = str .. '\n'
	if self.allies then
		str = str .. sfmt('[b]Allies[/b]:\n[spoiler]')
		for k,v in ipairs(self.allies) do
			local ally = find_ally(v.name)
			str = str .. sfmt('%s\n\n', ally.desc)
		end
		str = str .. '[/spoiler]\n'
	end
	str = str .. sfmt('[b]Galactica Space[/b]: %s\n', self:DescribeSpace(self.space))
	if self.cylon_fleet then
		str = str .. sfmt('[b]Cylon Space[/b]: %s\n', self:DescribeSpace(self.cylon_fleet_board))
	end
	
	return nospoiler .. '[spoiler]' .. str .. '[/spoiler]'
end

function state_funcs:GetCheckCount(check, flags, contributions)
	local types = {lea=check.lea,pol=check.pol,pil=check.pil,eng=check.eng,tac=check.tac,tre=check.tre}
	if flags.scientific then types.eng = true end
	if flags.aac then types.tre = true end
	if flags.chief_of_staff then types.pol = true end
	local val = check.val
	local desc = ''
	local total = 0
	
	for k,v in ipairs(contributions) do
		local str = v.mod_strength or v.strength
		local positive = (v.strength == 1 and self.flags.william_adama_crisis) or (types[v.type] ~= nil)
		if flags.chief_opg_result == v.type then str = 0 end -- Chief's OPG
		local s
		if (v.mod_strength and v.mod_strength ~= v.strength) or flags.chief_opg_result == v.type then
			s = sfmt('[color=%s][b][i]%d[/i][/b][/color]', colors[v.type], str)
		else
			s = sfmt('[color=%s]%d[/color]', colors[v.type], str)
		end
		if desc == '' then
			if not positive then desc = '-' .. s
			else desc = s end
		else
			desc = desc .. ' ' .. ((positive and '+') or '-') .. ' ' .. s
		end
		total = total + ((positive and str) or -str)
	end
	
	if flags.mod and flags.mod ~= 0 then
		desc = desc .. ' + ' .. tostring(flags.mod)
		total = total + flags.mod
	end
	
	desc = desc .. ' = ' .. tostring(total) .. ' '
	
	local result
	local declare_emerg
	if total >= val - 2 and total < val then
		declare_emerg = true
	end
	
	if total >= val then
		result = 'pass'
		desc = desc .. '[color=limegreen]PASS[/color]'
	elseif check.partial and total >= check.partialval then
		result = 'partial'
		desc = desc .. '[color=yellow]PARTIAL PASS[/color]'
	else
		result = 'fail'
		desc = desc .. '[color=red]FAIL[/color]'
	end
	
	return desc, total, result, declare_emerg, total - val
end

function state_funcs:DestroySpaceCivvie(where)
	-- destroy the first civ
	local civ = table.remove(self.space[where].civ, 1)
	local res = {}
	for k,v in pairs({'morale','fuel','pop'}) do
		if civ[v] then
			res[v] = -civ[v]
		end
	end
	self:Resolve(res)
end

function state_funcs:FindCiv(which)
	for _,sector in pairs(self.space) do
		for _,civ in pairs(sector.civ or {}) do
			if civ.label == which then return civ end
		end
	end
end

function state_funcs:DescribeCiv(civ)
	local desc = ""
	for k,r in ipairs({'morale','fuel','pop'}) do
		if civ[r] then
			if desc ~= "" then desc = desc .. ', ' end
			desc = desc .. sfmt("%d %s", civ[r], names[r])
		end
	end
	return sfmt("%s - %s", civ.label, desc)
end

function state_funcs:MoveCiv(which, to)
	self:ResultLog('Civilian %s moves to %s', which, names[to])
	for _,sector in pairs(self.space) do
		for i,civ in pairs(sector.civ or {}) do
			if civ.label == which then
				table.remove(sector.civ, i)
				self.space[to].civ = self.space[to].civ or {}
				table.insert(self.space[to].civ, civ)
				return
			end
		end
	end
end

do
	-- this is the clockwise ordering
	local connectivity = { 'front', 'sbow', 'saft', 'rear', 'paft', 'pbow' }
	SpaceAreas = connectivity
	function GetSpaceDistance(from, to)
		if from == to then return 0 end
		
		for k,v in pairs(connectivity) do
			if from == v then from = k end
			if to == v then to = k end
		end
		
		-- converted 1-6
		if to < from then to = to + 6 end
		-- from is [1,6], to is [2,11] (to can't stay as 1 and doesn't get increased if 6)
		local fwd = to - from
		local target
		if fwd <= 3 then
			-- cw
			return fwd -- [1,3]
		else
			-- ccw
			return fwd - 6 -- [-1,2]
		end
	end
	function SpaceMove(from, dir)
		for k,v in pairs(connectivity) do
			if from == v then from = k end
		end
		if dir < 0 then from = from - 1
		else from = from + 1 end
		if from == 7 then from = 1
		elseif from == 0 then from = 6 end
		
		return connectivity[from]
	end
end

function state_funcs:ActivateRaider(src, area)
	-- 1. Attack a viper
	if (src.viper or 0) > 0 or (src.viper7 or 0) > 0 or (src.araptor or 0) > 0 then
		local choice
		local choices = {}
		local vtype
		local pilot
		local desc = 'Raider attacks '
		local nv = src.viper or 0
		local nv7 = src.viper7 or 0
		local na = src.araptor or 0
		local pilots = src.pilots or {}
		
		for k,v in pairs(pilots) do
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
		
		choice = self.current:Choice(choices, 'raider attacks which viper?')
		
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
		
		desc = desc .. names[vtype]
		
		self:PushState('resolve_attack', {desc=desc, by='raider', target=vtype, area=area, pilot=pilot})
		return
	end
	
	-- 2. Destroy a civvie
	if src.civ and #src.civ > 0 then
		self:DestroySpaceCivvie(area)
		return
	end
	
	-- 3. Move to engage a civvie
	local best
	for k,v in pairs(self.space) do
		if v.civ and #v.civ > 0 then
			local distance = GetSpaceDistance(area, k)
			if not best or math.abs(distance) < math.abs(best) then
				best = distance
			end
		end
	end
	
	if best then
		-- Move
		local to = SpaceMove(area, best)
		self:ResultLog('Raider moves to %s', names[to])
		self.space[to].raider = (self.space[to].raider or 0) + 1
		self.space[area].raider = self.space[area].raider - 1
		return
	end
	
	-- 4. Attack Galactica
	self:PushState('resolve_attack', {desc='Raider attacks Galactica', by='raider', target='galactica', area=area})
end

function state_funcs:BasestarDamageTokens()
	local list = {
		'Critical Hit',
		'Hangar Disabled',
		'Structural Damage',
		'Weapons Disabled',
	}
	if self.ionian_nebula then
		table.insert(list, 'Draw Trauma')
		table.insert(list, 'Collateral Damage')
	end
	
	-- remove any existing damage tokens
	for k,v in pairlist(self.space, self.cylon_fleet_board) do
		for i,j in pairs(v.basestar or {}) do
			for k,l in pairs(j) do
				table.remove_specific(list, l)
			end
		end
	end
	return list
end

function state_funcs:BasestarHasDamage(basestar, damage)
	for k,v in pairs(basestar) do
		if k == damage or v == damage then return true end
	end
	return false
end

require "bsg_state_machine"
require "bsg_init"
