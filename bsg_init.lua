local tins = table.insert

function create_game_decks(flags)
	local crisis_list = {}
	local quorum_deck = new_deck(nil, 'Quorum Deck')
	local destination_deck = {}
	local skill_decks = {}
	local supercrisis_deck = {}
	local mutiny_deck = new_deck(nil, 'Mutiny Deck')
	local mission_deck = new_deck(nil, 'Mission Deck')
	local subtypes = {
		base='base', pegasus='peg', exodus='exo', daybreak='day'
	}

	-- Crisis cards
	for _,t in pairs({base_crisis_cards,
			(flags.pegasus and pegasus_crisis_cards) or {},
			(flags.exodus and exodus_crisis_cards) or {},
			(flags.daybreak and daybreak_crisis_cards) or {},
			}) do
		for k,v in pairs(t) do
			tins(crisis_list, v.id)
		end
	end

	-- Skill decks
	for _,t in ipairs(card_types) do
		skill_decks[t] = new_deck(nil, names[t] .. ' Deck')
		for q,u in pairs(subtypes) do
			if flags[q] and (q ~= 'pegasus' or not flags.daybreak or t ~= 'tre') then
				for k,v in pairs(_G[u .. '_' .. t .. '_deck'] or {}) do
					for i=1,v.qty do
						skill_decks[t]:insert(setmetatable({strength=v.strength}, {__index=v.card}))
					end
				end
			end
		end
		skill_decks[t]:shuffle()
	end

	for k,v in pairs(destination_cards) do
		if not v.module or flags[v.module] then
			for i=1,(v.qty or 1) do
				tins(destination_deck, v.name)
			end
		end
	end

	for _,deck in pairs({base_supercrisis,(flags.pegasus and pegasus_supercrisis),(flags.exodus and exodus_supercrisis)}) do
		for k,v in pairs(deck) do
			tins(supercrisis_deck, v.name)
		end
	end

	for _,deck in pairs({base_quorum,(flags.pegasus and pegasus_quorum),(flags.exodus and exodus_quorum)}) do
		for k,v in ipairs(deck) do
			for i=1,(v.qty or 1) do
				quorum_deck:insert(v.name)
			end
		end
	end
	
	if flags.daybreak then
		-- build mission & mutiny decks here
		for k,v in pairs(mission_cards) do
			mission_deck:insert(v.name)
		end
		for k,v in pairs(mutiny_cards) do
			mutiny_deck:insert(v.name)
		end
	end

	mutiny_deck:shuffle()
	mission_deck:shuffle()
	quorum_deck:shuffle()
	return shuffle_list(crisis_list), skill_decks, quorum_deck, shuffle_list(destination_deck), shuffle_list(supercrisis_deck), mutiny_deck, mission_deck
end

function create_loyalty_deck(state)
	local cylon_deck = new_deck()
	local nocylon_deck = new_deck()
	local loyalty_deck = {}
	
	local not_a_cylon = 11
	if state.pegasus then not_a_cylon = not_a_cylon + 1 end
	if state.exodus then not_a_cylon = not_a_cylon + 5 end
	
	for k,v in pairs(loyalty_cards) do
		if not v.type or state[v.type] then
			if v.cylon then
				cylon_deck:insert(v)
			else
				nocylon_deck:insert(v)
			end
		end
	end
	
	-- blank loyalty cards
	for i=1,not_a_cylon do
		nocylon_deck:insert({name="vanilla",cylon=false})
	end
	
	local makeup = {
		[3] = { cylon = 1, nocylon = 6 },
		[4] = { cylon = 1, nocylon = 7, sympathizer = true, mutineer = true },
		[5] = { cylon = 2, nocylon = 9 },
		[6] = { cylon = 2, nocylon = 10, sympathizer = true, mutineer = true },
	}
	for k,v in pairs(state.players) do
		if v.type == "cylon" then
			makeup = {
				[4] = { cylon = 1, nocylon = 6 },
				[5] = { cylon = 1, nocylon = 8, mutineer = true },
				[6] = { cylon = 2, nocylon = 9 },
				[7] = { cylon = 2, nocylon = 11, mutineer = true },
			}
			break
		end
	end

	local e = makeup[#state.players]
	if not e then error('Illegal player count / cylon leader conbination') end

	cylon_deck:shuffle()
	nocylon_deck:shuffle()
	for i = 1, e.cylon do
		local card = cylon_deck:draw_top()
		tins(loyalty_deck, card)
	end
	local nocylon = e.nocylon
	if state:FindPlayer('boomer') then nocylon = nocylon + 1 end
	if state:FindPlayer('baltar') then nocylon = nocylon + 1 end
	for i = 1, nocylon do
		local card = nocylon_deck:draw_top()
		tins(loyalty_deck, card)
	end

	if e.sympathizer then
		state.sympathizer_variant = true
		tins(loyalty_deck, {sympathizer=true})
	end
	if e.mutineer and state.daybreak then
		tins(loyalty_deck, {mutineer =true, name="mutineer", type="mutineer", desc=[[You are the mutineer!]]})
	end
	return shuffle_list(loyalty_deck), shuffle_list(nocylon_deck.deck)
end


function newgame_state(modules, players, short_name, game_name)
	local type = "base"
	local goal = "kobol"
	local final5 = false
	local personal_goals = false
	local cylon_fleet = false
	local pegasus = false
	local exodus = false
	local daybreak = false
	
	if not modules then modules = {} end
	
	if modules.all then
		pegasus = true
		exodus = true
		cylon_fleet = true
		personal_goals = true
		final5 = true
		goal = "ionian"
		type = "exodus"
	end
	if modules.pegasus then
		pegasus = true
		type = "pegasus"
	end
	if modules.exodus then
		exodus = true
		type = "exodus"
	end
	if modules.daybreak then
		daybreak = true
		type = "daybreak"
	end
	if modules.new_caprica then
		if not pegasus then error('new caprica without pegasus?') end
		goal = "new_caprica"
		state.new_caprica = true
	end
	if modules.cylon_fleet then
		if not exodus then error('cylon fleet without exodus?') end
		cylon_fleet = true
	end
	if modules.personal_goals then
		if not exodus then error('personal goals without exodus?') end
		personal_goals = true
	end
	if modules.final_five then
		if not exodus then error('final five without exodus?') end
		final5 = true
	end
	if modules.confliced_loyalties then
		if not exodus then error('conflicted loyalties without exodus?') end
		personal_goals = true
		final5 = true
	end
	if modules.ionian_nebula then
		if not exodus then error('ionian nebula without exodus?') end
		goal = "ionian"
	end
	if modules.search_for_home then
		goal = "earth"
	end

	local function format_bin(s)
		if not s then return end
		local t={}
		for i = 1,#s do
			table.insert(t, s:byte(i))
		end
		return t
	end
	local s = {
		base = true,
		game_name = game_name, short_name = short_name,
		type = base, goal = goal, exodus = exodus, pegasus = pegasus, daybreak = daybreak, final5 = final5, personal_goals = personal_goals, cylon_fleet = cylon_fleet,
		search_for_home = modules.search_for_home,
		food = 8, fuel = 8, morale = 10, pop = 12, raptor = 4,
		viper = 8, damaged_viper = 0, viper7 = 0, damaged_viper7 = 0, araptor = 0,
		nukes = 2, distance = 0,
		maximums = { basestar = 2, heavy = 4, raider = 16, raptor = 4, araptor = 4, nukes = 2, viper = 8, viper7 = 0, food = 15, fuel = 15, morale = 15, pop = 15, },
		civ = {{pop=1},{pop=1},{pop=1},{pop=1},{pop=1},{pop=1},{pop=1,fuel=1},{pop=1,morale=1},{},{},{pop=2},{pop=2}}, destroyed_civ = {},
		space = { front = {}, rear = {}, pbow = {}, paft = {}, sbow = {}, saft = {} },
		flags = {}, jump_flags = {}, crisis_flags = {}, turn_flags = {}, check_flags = {},
		players = {}, destiny_deck = {},
		current = nil, admiral = nil, president = nil, cag = nil, --just placeholders, does nothing
		turn = 0,
		rng_seed = format_bin(mersenne_twister_seed),
		rebel_basestar = 'neutral',
		
		-- someone check these numbers
		basestar = 2, raider = 20, heavy = 4,
		
		locations = {},
		damage = {},
		fuel_token_hit = nil, food_token_hit = nil,
		
		quorum_hand = {},
		boarding_track = {[1]=0, [2]=0, [3]=0, [4]=0},
		pursuit_track = 0, jump_track = 0,
		
		substate = nil,
		state = "game_setup",
		state_stack = {},
	}
	if exodus then
		s.maximums.nukes = 3
		s.maximums.viper = 6
		s.maximums.viper7 = 4
		s.maximums.raider = 20
		s.viper = 6
		s.viper7 = 0
		s.damaged_viper7 = 4
	end
	if s.cylon_fleet then
		s.cylon_fleet_board = { front = {}, rear = {}, pbow = {}, paft = {}, sbow = {}, saft = {} }
	end
	if daybreak then
		s.araptor = 1
	end

	s.crisis_deck, s.skill_decks, s.quorum_deck, s.destination_deck, s.supercrisis_deck, s.mutiny_deck, s.mission_deck = create_game_decks(s)
	local num_players = #players
	for k,v in ipairs(players) do
		local t = {number = k, loyalty = {}, hand = {},
			name = v.name, player = v.player,
			trauma = {benevolent=0, antagonistic=0}, miracle = 1, mutiny_hand = {}, location = '', state = s,
		}
		if v.type == "cylon" then t.cylon = true end -- leaders start out toastery
		s.players[k] = setmetatable(t, {__index=v})
		s.players[v.name] = s.players[k]
		if not t.player then t.player = t.name end
	end
	setmetatable(s.flags, { __index = function(t,k) return s.jump_flags[k] or s.crisis_flags[k] or s.turn_flags[k] or s.check_flags[k] end })
	setmetatable(s, state_funcs)
	
	if modules.motives then
		-- choose 4 random motives for our cylon leader
		s.motives = {}
		local t = {}
		for k,v in pairs(motive_list) do
			table.insert(t, k)
		end
		for i = 1, 4 do
			table.insert(s.motives, table.remove_random(t))
		end
	end

	-- starting quorum card
	tins(s.quorum_hand, s.quorum_deck:draw_top())

	if goal == "ionian" then
		s.ionian_nebula = true
		s.trauma = { disaster = 0, benevolent = 18, antagonistic = 18 }

		for k,v in ipairs(s.players) do
			for i=1,3 do
				-- Starting trauma can't contain disaster tokens
				local trauma = s:DrawTrauma()
				v.trauma[trauma] = v.trauma[trauma] + 1
			end
			v:PrivateMsg('Trauma: %d Benevolent, %d Antagonistic', v.trauma.benevolent, v.trauma.antagonistic)
		end

		-- Skip disasters for the initial assignments, but they can go on ally cards
		s.trauma.disaster = 2

		local allies_deck = {}
		for k,v in pairs(allies) do
			if not s:FindPlayer(v.name) then
				table.insert(allies_deck, v.name)
			end
		end
		s.allies = {}
		s.allies_deck = shuffle_list(allies_deck)
		
		-- 3 allies
		for i=1,3 do
			local ally = s:DrawAlly()
			local trauma = s:DrawTrauma()
			table.insert(s.allies, {name=ally,trauma=trauma})
		end
	end
	if cylon_fleet then
		-- remove all attack crises
		local i = 1
		while s.crisis_deck[i] do
			local c = get_crisis_by_id(s.crisis_deck[i])
			if c.attack then
				table.remove(s.crisis_deck, i)
			else
				i = i + 1
			end
		end
		
		if not s.destination_mining_asteroid_variant then
			for k,v in pairs(s.destination_deck) do
				if v.name == "Mining Asteroid" then
					table.remove(s.destination_deck, k)
					break
				end
			end
		end
	end

	s.loyalty_deck, s.unused_loyalty = create_loyalty_deck(s)
	s.current = s.players[1] -- the current player as per turns
	s.acting = s.players[1] -- the current acting player, changed by XO et al
	s.president = s:Succession('president')
	s.admiral = s:Succession('admiral')
	if s.cylon_fleet then
		s.cag = s:Succession('cag')
	end
	
	s:DeployShips('basestar', 1, 'front')
	s:DeployShips('raider', 3, 'front')
	s:DeployShips('civ', 2, 'rear')
	s:DeployShips('viper', 1, 'pbow')
	s:DeployShips('viper', 1, 'paft')
	s:MakeNewDestinyDeck()
	
	s.result_log = ''
	s:ResultLog('Game is starting')
	s:ResultLog('Players')
	for k,v in ipairs(s.players) do
		s:ResultLog('%s', v:full_name(true))
	end
	s:ResultLog('')
	s:PostLoadFixup()
	
	for k,v in pairs(s.players) do
		if v.name == 'Tom Zarek (alt)' then
			v:DrawMutiny(true)
		end
	end
	
	return s
end

function save_state(state)
	state.rng_count = rng_count
	local save_temp_state = {}
	local references = {}
	local output_tmp = {}
	local function out(s, ...)
		local str = string.format(s, ...)
		table.insert(output_tmp, str)
	end
	
	local function savename(k, v)
		out("[%q]=%q, ", k, v.name)
	end
	
	local function fmt(v)
		if type(v) == "number" then return tostring(v) end
		if type(v) == "string" then return string.format('%q', v) end
		return tostring(v)
	end
	
	local function recursive_dump(t, skiplist, noclose, nofunc)
		if not nofunc and t.savefunc then
			out(t:savefunc(recursive_dump, out)..',')
			return
		end
		out("{")
		for k,v in pairs(t) do
			if type(k) == "table" then panic() end
			if type(v) == "table" then
				if not skiplist or not skiplist[k] then
					out("[%s] = ", fmt(k))
					recursive_dump(v)
				end
			elseif type(v) ~= 'function' then
				out("[%s] = %s, ", fmt(k), fmt(v))
			end
		end
		if not noclose then
			out("},")
		end
	end
	
	local special = {
		players = function (k, v)
			out("[%q]={", k)
			for i=1,#v do
				local p = v[i]
				local skip = {hand=true, location=true, state=true}
				recursive_dump(p, skip, true, true)
				out("location=%q,", (p.location and p.location.name) or '')
				out(" hand={")
				for _,card in pairs(p.hand) do
					out("{strength=%d,name=%q},", card.strength, card.name)
				end
				out("}},")
			end
			out("},\n")
		end,
		
		file_index = function () end,
		flags = function () end,
	}
	
	out("return {\n")
	for k,v in pairs(state) do
		if special[k] then
			special[k](k,v)
		elseif type(v) == "table" then
			out("[%q] = ", k)
			recursive_dump(v)
			out("\n")
		else
			out("[%q]=%s, \n", k, fmt(v))
		end
	end
	out("}")
	
	return table.concat(output_tmp)
end


-- take the raw state and prepare it for use
local function restore_state(s)
	local players = s.players
	s.players = {}
	
	for k,v in pairs(players) do
		local p = find_char(v.name)
		setmetatable(v, {__index=p})
		s.players[p.name] = v
		s.players[v.number] = v
		
		local hand = v.hand
		local new_hand = {}
		v.hand = new_hand
		v.state = s
		
		v.location = find_location(v.location)
		
		for _,u in pairs(hand) do
			table.insert(new_hand, setmetatable({strength=u.strength}, {__index=find_card(u.name)}))
		end
	end

	s.flags = {}
	setmetatable(s.flags, { __index = function(t,k) return s.jump_flags[k] or s.crisis_flags[k] or s.turn_flags[k] or s.check_flags[k] end })
	setmetatable(s, state_funcs)
	
	local function postload(t)
		if t.loadfunc then
			t = _G[t.loadfunc](s, t)
		end
		
		for k,v in pairs(t) do
			if s ~= v and s.players ~= v and type(v) == "table" then
				t[k] = postload(v)
			end
		end
		return t
	end
	
	postload(s)
	
--	s.quorum_deck = load_deck(s, s.quorum_deck)
--	for k,v in pairs(s.skill_decks) do
--		s.skill_decks[k] = load_deck(s, v)
--	end
	if mersenne_twister_seedfunc and s.rng_seed then
		rng_count = s.rng_count
		mersenne_twister_seedfunc(string.char(unpack(s.rng_seed)), s.rng_count or 0)
	else
		if not s.rng_seed_plain then
			s.rng_seed_plain = os.time()
		end
		math.randomseed(s.rng_seed_plain)
		for i=1, s.rng_count do math.random() end
		local f = math.random
		rng_count = s.rng_count
		math.random = function(...) rng_count = rng_count + 1; return f(...) end
	end
	s:PostLoadFixup()
	return s
end

function load_from_file(f)
	local func = assert(loadfile(f))
	return restore_state(func())
end

function load_from_string(s)
	local func = assert(loadstring(s))
	return restore_state(func())
end


function save_to_file(state, f)
	local s = save_state(state)
	local file = io.open(f, 'w')
	if not file then
		print("Couldn't open '%s'\n", f)
		return false
	end
	file:write(s)
	file:close()
	return true
end

local real_open = io.open
io.open = function(name, mode)
	return real_open(string.gsub(string.gsub(name, '["\\:*<>|]', ''), '[ ]', '_'), mode)
end

function state_funcs:SaveSitrep(fn)
	local file = io.open(fn, 'w')
	if file then
		file:write(self:Sitrep())
		file:close()
	end
end

function state_funcs:Save()
	local index = (self.file_index or 0)
	self.file_index = index + 1
	local f = string.format('%s/state_%d.txt', self.short_name, index + 1)
	print("Saved to file %s\n", f);
	return save_to_file(self, f)
end

function state_funcs:TryAutoPost(credentials_file, data, id, is_thread)
end

function state_funcs:DumpAndSave(type)
	local dump_all = (type == 'post')
	local result_log = self.result_log or ''
	local msgs = self.private_msg
	local function spawn_notepad(file)
		if os and os.execute and file then
			os.execute(string.format('start notepad "%s"', file))
		end
	end
	
	local function write_f(name, txt)
		local file = io.open(name, 'w')
		file:write(txt)
		file:close()
	end
	
	local function do_post(str)
	end
	
	if dump_all then
		self.result_log = nil
	else
		result_log = nil
	end
	self.private_msg = nil
	if not self:Save() then
		print("Save failed!\n")
		self.result_log = result_log
		self.private_msg = msgs
		return false
	end
	if dump_all then
		local f = string.format('%s/results_%d.txt', self.short_name, self.file_index)
		self:SaveSitrep(string.format('%s/sitrep_%d.txt', self.short_name, self.file_index))
		local results = result_log .. '\n\n\n\n' .. self:Sitrep()
		write_f(f, results)
		self:ImageSitrep(string.format('%s/%s_state_%d.png', self.short_name, self.short_name, self.file_index))
		spawn_notepad(f)
	end
	local messages = {}
	messages.thread = {msg=results, file=f}
	for k,v in pairs(msgs or {}) do
		local f = string.format('%s/pm_%d_%s.txt', self.short_name, self.file_index, k:gsub(' ','_'))
		if v ~= '' then
			write_f(f, v)
			messages[k] = {msg=v, file=f}
		end
	end
	for k,v in pairs(messages) do
		spawn_notepad(v.file)
	end
	return true
end

function get_upload_func(func_str)
	if func_str then
		local f = loadstring(func_str)
		if f then
			local ok, g = pcall(func)
			return ok and g
		end
	end
	return sitrep_img_upload_func
end

function state_funcs:ImageSitrep(name)
	if os and os.remove then os.remove(name) end
	local function f()
		require "lua_gfx"
		if new_gfx then
			new_gfx(self):main_state(name)
		end
	end
	local result, err = pcall(f)
	if result then
		local func = get_upload_func(self.sitrep_img_upload_func)
		if func and not debug_mode then
			if self:GMChoice({'n','y'}, 'Upload sitrep image? ') == 'y' then
				local ok, err = pcall(func, name)
				if not ok then
					print("error: " .. err)
				end
			end
		end
	else
		print("gfx error: " .. err)
	end
end

function state_funcs:PostLoadFixup()
	local function on_shuffle(deck)
		self:ResultLog('[b]%s is shuffled[/b]', deck)
	end
	for k,v in pairs{'quorum_deck','mutiny_deck','mission_deck'} do
		if self[v] then self[v].on_shuffle = on_shuffle end
	end
	for k,v in pairs(card_types) do
		self.skill_decks[v].on_shuffle = on_shuffle
	end
end
