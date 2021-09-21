
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

function remove_random(list)
	return table.remove(list, math.random(1, #list))
end


local deck_class = {}
deck_class.__index = deck_class

function deck_class:init(card_list)
	self.deck = card_list or {}
end

function deck_class:insert(card)
	table.insert(self.deck, card)
end

function deck_class:draw_bottom()
	if #self.deck == 0 then self:shuffle() end
	return table.remove(self.deck, 1)
end

function deck_class:draw_top()
	if #self.deck == 0 then self:shuffle() end
	return table.remove(self.deck)
end

function deck_class:peek_bottom(n)
	if #self.deck == 0 then self:shuffle() end
	return self.deck[n or 1]
end

function deck_class:peek_top(n)
	if #self.deck == 0 then self:shuffle() end
	return self.deck[#self.deck + 1 - (n or 1)]
end

function deck_class:place_top(card)
	table.insert(self.deck, card)
end

function deck_class:empty()
	return #self.deck == 0
end

function deck_class:count()
	return #self.deck
end

function deck_class:shuffle_existing()
	-- shuffle self.deck
	self.deck = shuffle_list(self.deck)
end

function deck_class:shuffle_list(refresh_list)
	local i = 1
	local deck = {}
	self.deck = deck
	local card_list = refresh_list
	while true do
		local card = card_list[i]
		if not card then break end
		deck[i] = card
		i = i + 1
	end
	return self:shuffle_existing()
end

function deck_class:remove_specific(f)
	for k,v in pairs(self.deck) do
		if f(v) then
			table.remove(self.deck, k)
			return v
		end
	end
end



local deck_discards_class = setmetatable({}, deck_class)
deck_discards_class.__index = deck_discards_class

function deck_discards_class:init(card_list)
	deck_class.init(self, card_list)
	self.discards = {}
end

function deck_discards_class:discard(card)
	table.insert(self.discards, card)
end

function deck_discards_class:shuffle()
	local f = self.on_shuffle or on_shuffle
	if f and self.name and self.name ~= '' then f(self.name) end
	
	local discards = self.discards
	for k,v in pairs(self.deck) do
		table.insert(discards, v)
	end
	self.discards = {}
	return self:shuffle_list(discards)
end

function deck_discards_class:savefunc(recursive_save_func, out)
	out('{loadfunc="load_deck", name="%s", deck=', self.name or '')
	recursive_save_func(self.deck)
	out('discards=')
	recursive_save_func(self.discards)
	return '}'
end

function load_deck(s, t)
	return setmetatable({deck=t.deck, discards=t.discards, name=t.name}, deck_discards_class)
end


function new_deck(cards, name)
	local t = setmetatable({}, deck_discards_class)
	t:init(cards)
	t.name = name
	return t
end
