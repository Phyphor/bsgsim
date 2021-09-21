-- set various config options in here
dofile("config.lua")

if not unpack then unpack = table.unpack end

function log_all(s)
end

function stdout(s)
	io.stdout:write(s)
	log_all(s)
end

function print(fmt, ...)
	local s = string.format(fmt, ...)
	stdout(s)
end

function get_input(nolog)
	local line = io.stdin:read("*line")
	if nolog then
		log_all('***\n')
	else
		log_all(line .. '\n')
	end
	return line
end

function tryload(name, i)
	local state = load_from_file(string.format('%s/state_%d.txt', name, i))
	if state then state.file_index = i end
	return state
end

function exists(name, i)
	local f = io.open(string.format('%s/state_%d.txt', name, i))
	if f then f:close() return true end
end

function load_main()
	require "bsg"
end

function load_from_dir(name)
	local best
	local lo, hi = 0, 8
	
	while exists(name, hi) do
		best = hi
		lo = hi
		hi = hi * 2
	end
	
	while lo <= hi do
		local mid = math.floor((lo+hi)/2)
		if exists(name, mid) then
			best = mid
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	local n = hi
	print("Attempting to load state %d\n", n)
	return tryload(name, n)
end

local funcs = {
	create = function (args)
		if #args < 5 then
			print('create <name> <long name> <modules> -p <player info>\n')
			print('name: local name you use\n')
			print('long name: name included in updates\n')
			print('modules: list of modules to include: exodus, pegasus, new_caprica, cylon fleet, personal_goals, final_five, ionian_nebula\n\tall means exodus + pegasus + cylon fleet, personal_goals, final_five')
			print('player info: tuples of <player name> <character name> in turn order\n')
			print('Example command: create game1 "My Awesome Game" all ionian_nebula -p mrblarney cain jdarksun leoben cayrus starbuck phyphor zarek\n\n')
			return
		end
		local name = table.remove(args, 1)
		local friendlyname = table.remove(args, 1)
		local modules = {}
		local players = {}
		
		while #args > 0 do
			if args[1] == '-p' then
				break
			end
			modules[table.remove(args, 1)] = true
		end
		if args[1] ~= '-p' then
			print('Expected -p for playter list\n')
			return
		end
		table.remove(args, 1)
		while #args > 1 do
			local name, char, p
			name = args[1]
			char = args[2]
			table.remove(args, 1)
			table.remove(args, 1)
			
			p = find_char(char)
			if not p then
				p = find_char(name)
				if not p then
					print('Can\'t find character named "%s" or "%s"\n', name, char)
					return
				end
				-- they messed up the order, so fix it
				name, char = char, name
			end
			local t = {player = name}
			table.insert(players, setmetatable(t, {__index=p}))
		end
		
		print("Confirm:\nGame '%s' (%s)\n%d player game\nModules: ", friendlyname, name, #players)
		for k,v in pairs(modules) do print("%s; ", k) end
		print("\nPlayers:\n")
		for k,v in ipairs(players) do print("\t%d: %s (%s)\n", k, v.name, v.player) end
		while true do
			print("Correct (y/n)? ")
			local inp = get_input()
			if inp == "n" then print("Aborted") return end
			if inp == "y" then break end
		end
		
		local state = newgame_state(modules, players, name, friendlyname)
		os.execute('mkdir "' .. name .. '"')
		save_to_file(state, name .. '/state_0.txt')
	end,
	
	
	status = function (args)
		local game = load_from_dir(args[1])
		if not game then
			print('Can\'t load game "%s"\n', args[1])
			return
		end
		table.remove(args, 1)
		
		print(game:Sitrep())
	end,
	
	step = function (args)
		if #args == 0 then
			print('step <name> [-i [imgname]]\n')
			print('step the game state, optionally creating an image at the end\n')
			print('exec is a synonym for step\n')
		end
		local ok, game = pcall(load_from_dir, args[1])
		if not ok or not game then
			print('Can\'t load game "%s" err: %s\n', args[1], game)
			return
		end
		table.remove(args, 1)
		
		local imgname
		local dump_image
		while #args > 0 do
			if args[1] == "-i" then
				dump_image = true
				table.remove(args, 1)
				
				imgname = args[1]
				table.remove(args, 1)
			else
				print("step: unknown argument '%s'\n", args[1])
				return
			end
		end
		
		print("Cylon-Human Extermination Simulator v1.0\n")
		print("Game state is loaded, beginning execution...\n")
		game:step_game()
	end,
}
funcs.exec = funcs.step

function main(args)
	if #args == 0 then
		print("Possible commands")
		for k,v in pairs(funcs) do
			print("\t%s", k)
		end
		return
	end
	local command = table.remove(args, 1)
	if command ~= 'test' then load_main() end
	
	if command and funcs[command] then
		return funcs[command](args)
	else
		print("Unknown command: %s\nPossible commands:\n", command or '<none>')
		for k,v in pairs(funcs) do
			print('\t%s\n', k);
		end
		print("Run the command without arguments to get more information\n\n")
	end
end

function panic(t, ...)
	error('panic: ' .. (t and string.format(t, ...) or 'no message'))
end

function exit()
	os.exit(0)
end

if debug_mode then
	print("*** DEBUG MODE ***")
	math.randomseed(0)
	load_main()
elseif mersenne_twister then
	math.random = mersenne_twister
	math.randomseed = mersenne_twister_seedfunc
end

if not running_embedded then
	return main({...})
end
