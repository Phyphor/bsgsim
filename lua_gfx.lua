local function copy(s)
	if not s then return end
	local t = {}
	for k,v in pairs(s) do t[k] = v end
	return setmetatable(t, getmetatable(s))
end

local gfx_meta = {}

local rect_funcs = {}
rect_funcs.__index = rect_funcs

function rect_funcs:width()
	return self.x1-self.x0
end
function rect_funcs:height()
	return self.y1-self.y0
end
function rect_funcs:wh()
	return self.x1-self.x0, self.y1-self.y0
end
function rect_funcs:do_stride(s)
	if not s then s = self.stride end
	self.x0 = self.x0 + s
	self.x1 = self.x1 + s
end

function rect_funcs:do_stridey(s)
	if not s then s = self.stride_y end
	self.y0 = self.y0 + s
	self.y1 = self.y1 + s
end

function rect_funcs:translate(x,y)
	local t = copy(self)
	t:do_stride(x * (t.stride or 0))
	t:do_stridey((y or 0) * (t.stride_y or 0))
	return t
end

local function rectr(x,y,w,h, extra)
	local r = {x0=x,y0=y,x1=x+w+1,y1=y+h+1}
	if extra then
		for k,v in pairs(extra) do
			r[k] = v
		end
	end
	return setmetatable(r, rect_funcs)
end
local function recta(x,y,x1,y1, extra)
	local r = {x0=x,y0=y,x1=x1,y1=y1}
	if extra then
		for k,v in pairs(extra) do
			r[k] = v
		end
	end
	return setmetatable(r, rect_funcs)
end

local font_funcs = {}

function font_funcs:predraw(s)
	local t = s
	if type(s) == "number" then s = tostring(s) end
	
	if type(s) == "string" then
		t = {}
		for i = 1, #s do
			table.insert(t, s:sub(i,i))
		end
	end
	
	local ret = {}
	local x = 0
	for k,v in ipairs(t) do
		local ch = self.chars[v]
		assert(ch)
		table.insert(ret, {x=x, ch=ch})
		x = x + ch:width() + 0
	end
	return ret, x
end

function font_funcs:draw(target, src, target_rect, str, opts)
	local chars, sw = self:predraw(str)
	local tw = target_rect:width()
	local ox = math.floor((tw-sw) / 2 + 0.5)
	local oy = math.floor((target_rect:height()-chars[1].ch:height()) / 2 + 0.5)
	if opts then
		if opts.align then
			if opts.align == "left" then
				ox = 0
			end
		end
	end
	local tx = target_rect.x0 + ox
	for k,v in ipairs(chars) do
		target:Blit(src, tx + v.x, target_rect.y0 + oy, v.ch.x0, v.ch.y0, v.ch:width(), v.ch:height())
	end
end

local function make_fixed_numeric_font(x0,y0,width,extra_stride,height,order)
	local t = {x0=x0,y0=y0,chars={}}
	local c = t.chars
	if not order then order = {'1','2','3','4','5','6','7','8','9','0'} end
	for k,v in ipairs(order) do
		c[v] = rectr(x0 + (k-1) * (width + extra_stride), y0, width, height)
	end
	return setmetatable(t,{__index=font_funcs})
end
local function make_full_font(rows)
	local t = {chars={}}
	local c = t.chars
	for _,row in pairs(rows) do
		local sumw = 0
		for k,v in ipairs(row.order) do
			local stride = row.stride
			if not stride then stride = row.strides[k] end
			c[v] = rectr(row.x0 + sumw, row.y0, stride - 1, row.h)
			sumw = sumw + stride
		end
	end
	return setmetatable(t,{__index=font_funcs})
end

-- things that are common to everything
local layout_blarney_cross_common = {
	res_fuel = rectr(283, 27, 6, 14, {stride=8}),
	res_food = rectr(283, 27+16, 6, 14, {stride=8}),
	res_morale = rectr(283, 27+32, 6, 14, {stride=8}),
	res_pop = rectr(283, 27+48, 6, 14, {stride=8}),
	damage_icon = rectr(7, 102, 9, 15),
	civs = recta(200,117,225,134,{stride=27, stride_y=19}),
	fuel_token = recta(132,82,156,99),
	food_token = recta(158,82,182,99),
	civ_order = {
		{{pop1=true},{pop1=true},{empty=true},{empty=true}},
		{{pop1=true},{pop1=true},{pop2=true},{pop2=true},},
		{{pop1=true},{pop1=true},{popf=true},{popm=true}},
	},
}
layout_blarney_cross_common.__index = layout_blarney_cross_common



local layout_blarney_daybreak_icons = {
	daybreak = true,
	imgname = 'BSG-CustomBoard-4-icons.png',
	img2name = 'BSG-CustomBoard-3-font.png',
	full_font = make_full_font{
		{h=11,x0=710,y0=408, stride=8, order={'1','2','3','4','5','6','7','8','9','0'}},
		{h=11,x0=710,y0=421, strides={8,8,8,8,8,8,8,8,8,8,8,8,10}, order={'A','B','C','D','E','F','G','H','I','J','K','L','M'}},
		{h=11,x0=710,y0=434, strides={8,8,8,8,8,8,8,8,8,10,8,8,8}, order={'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}},
		{h=11,x0=710,y0=445, strides={6,6,6,6,6,6,6,6,6,6,6,6,8,6}, order={'a','b','c','d','e','f','g','h','i','j','k','l','m',' '}},
		{h=11,x0=710,y0=456, strides={6,6,6,6,6,6,6,6,6,8,6,6,6}, order={'n','o','p','q','r','s','t','u','v','w','x','y','z'}},
	},
	colonial_one_destroyed_overlay = recta(17,6,  183,92),
	res_fuel = rectr(283, 27, 6, 14, {stride=8}),
	res_food = rectr(283, 27+16, 6, 14, {stride=8}),
	res_morale = rectr(283, 27+32, 6, 14, {stride=8}),
	res_pop = rectr(283, 27+48, 6, 14, {stride=8}),
	civ_order = {
		{{pop1=true},{pop1=true},{empty=true},{empty=true}},
		{{pop1=true},{pop1=true},{pop2=true},{pop2=true},},
		{{pop1=true},{pop1=true},{popf=true},{popm=true}},
	},
	civs = recta(200,117,225,134,{stride=27, stride_y=19}),
	fuel_token = recta(132,98,156,115),
	food_token = recta(158,98,182,115),
	damage_icon = rectr(7, 117, 9, 15),
	tokens = recta(132,104+16,138,115+16,{stride=7,stride_y=16}),
	ally_tokens = recta(132,137+16,138,147+16,{stride=7,stride_y=16}),

	viper2 = {
		reserve = recta(321,224-83,334,243-83),
		active = recta(338,224-83,351,243-83),
		damaged = recta(355,224-83,368,243-83),
	},
	viper7 = {
		damaged = recta(389,223-83,402,244-83),
		active = recta(372,223-83,385,244-83),
		reserve = recta(389,200-83,402,221-83)
	},
	raptor_h = recta(319,165,337,180),
	araptor_h = {
		reserve = recta(319,184,338,199),
		active = recta(385,184,404,199),
	},
	
	distance = recta(271,234,278,249,{stride=8}),
	jump = recta(301,211,316,226,{stride=16}),
	pursuit= recta(281,280,296,295,{stride=16}),

	admiral = recta(468,195,481,207),
	cag = recta(486,195,497,207),
	president = recta(420,212,429,223),
	
	centurions = rectr(335 - 48,257,14,14, {stride=16}),
	pegasus_destroyed_overlay = recta(6, 268+16, 183, 353+16),

	green_font = make_fixed_numeric_font(291,13,7,1,11),
	grey_font = make_fixed_numeric_font(437-5,180,7,1,11),
	brown_font = make_fixed_numeric_font(437-5,212,7,1,11),
	miracle_font = make_fixed_numeric_font(480,164,7,1,11,{'0','1','2','3'}),
	mutiny_font = make_fixed_numeric_font(432,164,7,1,11,{'0','1','2'}),
	red_font = make_fixed_numeric_font(437-5,196,7,1,11,{'0','1','2','3'}),
	

	ally_names = {
		x={[0]=478, 563, 641, 721, 780},
		y = 166,
		stride_y = 16
	},
	player_names = {
		x={[0]=537,[1]=599,[2]=667,[3]=735, [4]=816},
		y=9,
		stride_y=16,
	},
	space = {
		viper = recta(667,346,686,359),
		viper7 = recta(666,362,687,375),
		araptor = recta(667,378,686,393),
		basestar = recta(716,362,765,393),
		heavy = recta(692,379,713,392),
		scar = recta(692,346,711,359),
		raider = recta(692,362,711,375),
		civ = recta(423,474,438,489,{stride=17}),
	},
}
layout_blarney_daybreak_icons.__index = layout_blarney_daybreak_icons

-- icons
local layout_blarney_icons = setmetatable({
	imgname = 'BSG-CustomBoard-3-icons.png',
	img2name = 'BSG-CustomBoard-3-font.png',
	distance = recta(484,172,490,186,{stride=8}),
	jump = recta(514,149,528,163,{stride=16}),
	pursuit= recta(701,172,715,186,{stride=16}),
	tokens = recta(132,104,138,115,{stride=7,stride_y=16}),
	ally_tokens = recta(132,137,138,147,{stride=7,stride_y=16}),
	opg_avail = recta(421,201,438,212),
	opg_used = recta(441,201,458,212),
	president = recta(425,265,434,276),
	cag = recta(505,249,516,260),
	admiral = recta(477,249,490,260),
	centurions = rectr(756 - 48,149,14,14, {stride=16}),
	pegasus_destroyed_overlay = recta(6, 268, 183, 353),
	colonial_one_destroyed_overlay = recta(17,6,  183,75),
	green_font = make_fixed_numeric_font(291,13,7,1,11),
	grey_font = make_fixed_numeric_font(437,217,7,1,11),
	brown_font = make_fixed_numeric_font(437,265,7,1,11),
	red_font = make_fixed_numeric_font(437,249,7,1,11,{'0','1','2','3'}),
	full_font = make_full_font{
		{h=11,x0=710,y0=408, stride=8, order={'1','2','3','4','5','6','7','8','9','0'}},
		{h=11,x0=710,y0=421, strides={8,8,8,8,8,8,8,8,8,8,8,8,10}, order={'A','B','C','D','E','F','G','H','I','J','K','L','M'}},
		{h=11,x0=710,y0=434, strides={8,8,8,8,8,8,8,8,8,10,8,8,8}, order={'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}},
		{h=11,x0=710,y0=445, strides={6,6,6,6,6,6,6,6,6,6,6,6,8,6}, order={'a','b','c','d','e','f','g','h','i','j','k','l','m',' '}},
		{h=11,x0=710,y0=456, strides={6,6,6,6,6,6,6,6,6,8,6,6,6}, order={'n','o','p','q','r','s','t','u','v','w','x','y','z'}},
	},
	viper2 = {
		reserve = recta(321,224,334,243),
		active = recta(337,224,350,243),
		damaged = recta(353,224,366,243),
	},
	viper7 = {
		damaged = recta(385,223,398,244),
		active = recta(369,223,382,244),
		reserve = recta(385,200,398,221),
	},
	raptor_h = recta(319,246,337,259),
	raptor_v = recta(329,166,341,183),
	ally_names = {
		x={[0]=483, 568, 646, 726, 785},
		y = 219,
		stride_y = 16
	},
	player_names = {
		x={[0]=533,[1]=631,[2]=709,[3]=775},
		y=25,
		stride_y=41-25,
	},
	space = {
		viper = recta(628,418,647,431),
		viper7 = recta(627,434,648,446),
		basestar = recta(676,417,727,448),
		raider = recta(652,418,671,431),
		scar = recta(652,402,671,415),
		heavy = recta(650,434,673,447),
		civ = recta(199,433,214,448,{stride=17}),
	},
	basestar_damage_tokens = nil,
}, layout_blarney_cross_common)

local function get_ally_name(icons,x,y)
	local v = icons.ally_names
	local r = recta(v.x[x], v.y + v.stride_y * y, v.x[x+1], v.y + v.stride_y * y + 11)
	return r
end

local function get_token(icons,n)
	n = n - 1
	local x,y = n % 7, math.floor(n / 7)
	return icons.tokens:translate(x,y)
end

local function get_ally_token(icons,n)
	n = n - 1
	local x,y = n % 7, math.floor(n / 7)
	return icons.ally_tokens:translate(x,y)
end

local ally_name_chart = {
	["Cavil"] = {x=0,y=4},
	["Brother Cavil"] = {x=0,y=4},
	["Leoben Conoy"] = {x=0,y=5},
	["D'Anna Biers"] = {x=0,y=6},
	["Simon O'Neill"] = {x=0,y=7},
	["Aaron Doral"] = {x=0,y=8},
	["Caprica Six"] = {x=0,y=9},
	['Lee "Apollo" Adama'] = {x=1,y=0},
	['William Adama'] = {x=1,y=1},
	['Karl "Helo" Agathon'] = {x=1,y=2},
	['Samuel T. Anders'] = {x=1,y=3},
	['Gaius Baltar'] = {x=1,y=4},
	['Helena Cain'] = {x=1,y=5},
	['Brendan "Hot Dog" Costanza'] = {x=1,y=6},
	['Dr. Sherman Cottle'] = {x=1,y=7},
	['Anastasia "Dee" Dualla'] = {x=1,y=8},
	['Margaret "Racetrack" Edmondson'] = {x=1,y=9},
	['Priestess Elosha'] = {x=2,y=0},
	['Tory Foster'] = {x=2,y=1},
	['Felix Gaeta'] = {x=2,y=2},
	['Louis Hoshi'] = {x=2,y=3},
	['Louanne "Kat" Katraine'] = {x=2,y=4},
	['Billy Keikeya'] = {x=2,y=5},
	['Aaron Kelly'] = {x=2,y=6},
	['Romo Lampkin'] = {x=2,y=7},
	['Alex "Crashdown" Quartararo'] = {x=2,y=8},
	['Laura Roslin'] = {x=2,y=9},
	['Diana "Hardball" Seelix'] = {x=3,y=0},
	['Kendra Shaw'] = {x=3,y=1},
	['Kara "Starbuck" Thrace'] = {x=3,y=2},
	['Ellen Tigh'] = {x=3,y=3},
	['Saul Tigh'] = {x=3,y=4},
	['Callandra "Cally" Tyrol'] = {x=3,y=5},
	['"Chief" Galen Tyrol'] = {x=3,y=6},
	['Sharon "Boomer" Valerii'] = {x=3,y=7},
	['Tom Zarek'] = {x=3,y=8},
}

local player_name_chart = {
	["Cavil"] = {x=0,y=0},
	["Leoben Conoy"] = {x=0,y=1},
	['"Caprica" Six'] = {x=0,y=2},
	["Felix Gaeta"] = {x=0, y=3},
	["Tory Foster"] = {x=0,y=4},
	["Samuel T. Anders"] = {x=0,y=5},
	['Callandra "Cally" Tyrol'] = {x=0,y=6},
	['William Adama'] = {x=1,y=0},
	['Saul Tigh'] = {x=1,y=1},
	['Karl "Helo" Agathon'] = {x=1,y=2},
	['Laura Roslin'] = {x=1,y=3},
	['Gaius Baltar'] = {x=1,y=4},
	['Tom Zarek'] = {x=1,y=5},
	['Lee "Apollo" Adama'] = {x=1,y=6},
	['Kara "Starbuck" Thrace'] = {x=2,y=0},
	['Sharon "Boomer" Valerii'] = {x=2,y=1},
	['"Chief" Galen Tyrol'] = {x=2,y=2},
	['Helena Cain'] = {x=2,y=3},
	['Ellen Tigh'] = {x=2,y=4},
	['Louanne "Kat" Katraine'] = {x=2,y=5},
	['Anastasia "Dee" Dualla'] = {x=2,y=6},
}

local player_name_chart_daybreak = {
	["Cavil"] = {x=3,y=1},
	["Leoben Conoy"] = {x=3,y=2},
	['"Caprica" Six'] = {x=3,y=6},
	["D'Anna Biers"] = {x=3,y=3},
	["Simon O'Neill"] = {x=3,y=4},
	["Aaron Doral"] = {x=3,y=5},
	['Sharon "Athena" Agathon'] = {x=3,y=7},
	["Felix Gaeta"] = {x=2, y=0},
	["Tory Foster"] = {x=2,y=1},
	["Samuel T. Anders"] = {x=2,y=2},
	['Callandra "Cally" Tyrol'] = {x=2,y=3},
	['Louis Hoshi'] = {x=2,y=4},
	['Romo Lampkin'] = {x=2,y=5},
	['Brendan "Hot Dog" Costanza'] = {x=2,y=6},
	['Sherman "Doc" Cottle'] = {x=2,y=7},
	['William Adama'] = {x=0,y=1},
	['Saul Tigh'] = {x=0,y=2},
	['Karl "Helo" Agathon'] = {x=0,y=3},
	['Laura Roslin'] = {x=0,y=4},
	['Gaius Baltar'] = {x=0,y=5},
	['Tom Zarek'] = {x=0,y=6},
	['Lee "Apollo" Adama'] = {x=0,y=7},
	['Kara "Starbuck" Thrace'] = {x=1,y=1},
	['Sharon "Boomer" Valerii'] = {x=1,y=2},
	['"Chief" Galen Tyrol'] = {x=1,y=3},
	['Helena Cain'] = {x=1,y=4},
	['Ellen Tigh'] = {x=1,y=5},
	['Louanne "Kat" Katraine'] = {x=1,y=6},
	['Anastasia "Dee" Dualla'] = {x=1,y=7},
}

local function get_ally_name_rect(icons, name)
	local t = ally_name_chart[name]
	return get_ally_name(icons, t.x, t.y)
end

local function get_player_name(icons,x,y)
	local v = icons.player_names
	local r = recta(v.x[x], v.y + v.stride_y * y, v.x[x+1], v.y + v.stride_y * y + 11)
	return r
end

local function daybreak_name(name)
	local n = name:match('(.*) %(alt%)')
	return n or name, n ~= nil
end

local function get_player_name_rect(icons, name)
	local n = daybreak_name(name)
	if icons.daybreak_icons and player_name_chart_daybreak[n] then
		return get_player_name(icons.daybreak_icons, player_name_chart_daybreak[n].x, player_name_chart_daybreak[n].y), icons.daybreak_icons
	end
	local t = player_name_chart[n]
	if t then
		return get_player_name(icons, t.x, t.y), icons
	end
end

-- things that are common to all layouts
local layout_blarney_common = setmetatable({
	locations = {
		["Press Room"] = rectr(131,28,49,12),
		["President's Office"] = rectr(131,28+16,49,12),
		["Administration"] = rectr(131,28+32,49,12),

		["FTL Control"] = rectr(131,103,49,12),
		["Weapons Control"] = rectr(131,103+16,49,12),
		["Command"] = rectr(131,103+16*2,49,12),
		["Communications"] = rectr(131,103+16*3,49,12),
		["Admiral's Quarters"] = rectr(131,103+16*4,49,12),
		["Research Lab"] = rectr(131,103+16*5,49,12),
		["Hangar Deck"] = rectr(131,103+16*6,49,12),
		["Armory"] = rectr(131,103+16*7,49,12),
		["Sickbay"] = rectr(131,103+16*8,49,12),
		["Brig"] = rectr(131,103+16*9,49,12),
		
		["Pegasus CIC"] = rectr(131,290,49,12),
		["Airlock"] = rectr(131,290+16,49,12),
		["Main Batteries"] = rectr(131,290+32,49,12),
		["Engine Room"] = rectr(131,290+48,49,12),
		
		["Caprica"] = rectr(131,388,20,12),
		["Cylon Fleet"] = rectr(131,388+16,20,12),
		["Human Fleet"] = rectr(131,388+32,20,12),
		["Resurrection Ship"] = rectr(131,388+48,20,12),
		["Basestar Bridge"] = rectr(131,388+64,20,12),
	},
	damage_locations = {
		["FTL Control"] = rectr(7, 103, 9, 15),
		["Weapons Control"] = rectr(7, 103+16, 9, 15),
		["Command"] = rectr(7, 103+16*2, 9, 15),
		["Admiral's Quarters"] = rectr(7, 103+16*4, 9, 15),
		["Hangar Deck"] = rectr(7, 103+16*6, 9, 15),
		["Armory"] = rectr(7, 103+16*7, 9, 15),
		["Pegasus CIC"] = rectr(7, 290, 9, 15),
		["Airlock"] = rectr(7, 290+16, 9, 15),
		["Main Batteries"] = rectr(7, 290+32, 9, 15),
		["Engine Room"] = rectr(7, 290+48, 9, 15),
	},
	fuel_number = recta(263,27,282,42),
	food_number = recta(263,27+16,282,42+16),
	morale_number = recta(263,27+32,282,42+32),
	pop_number = recta(263,27+48,282,42+48),
	space = {
		offset = {7,12},
		front = {
			polygon = {
				{9,63},{102,118},{102,180},{9,234}
			},
			exclusion = {
				{9,156},{39,156},{39,143},{9,143}
			},
			cylon_prefer = "left",
			colonial_prefer = "right",
		},
		rear = {
			polygon = {
				{313,65},{313,230},{225,180},{225,116}
			},
			exclusion = {
				{293,141},{313,141},{313,155},{293,155}
			},
			cylon_prefer = "right",
			colonial_prefer = "left",
		},
		pbow = {
			polygon = {
				{8,240},{131,173},{161,187},{161,282},{8,262}
			},
			exclusion = {
				{8,273},{65,273},{65,282},{8,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		paft = {
			polygon = {
				{165,282},{165,187},{197,173},{313,238},{313,282}
			},
			exclusion = {
				{240,273},{313,273},{313,282},{240,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		sbow = {
			polygon = {
				{8,13},{162,13},{162,121},{119,121},{8,56}
			},
			exclusion = {
				{8,30},{94,30},{94,13},{8,13}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		saft = {
			polygon = {
				{166,14}, {313,14},{313,60},{203,121},{166,121},
			},
			exclusion = {
				{211,13},{313,14},{313,30},{211,30}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
	},
	cylon_fleet_board = {
		offset = {7,12},
		front = {
			polygon = {
				{328,68},{414,116},{414,181},{328,228}
			},
			exclusion = {
				{328,141},{352,141},{352,155},{328,155}
			},
			cylon_prefer = "left",
			colonial_prefer = "right",
		},
		rear = {
			polygon = {
				{542,114},{632,64},{632,233},{542,182}
			},
			exclusion = {
				{623,140},{632,140},{632,156},{623,156}
			},
			cylon_prefer = "right",
			colonial_prefer = "left",
		},
		sbow = {
			polygon = {
				{328,17},{475,17},{475,127},{328,57}
			},
			exclusion = {
				{328,17},{353,17},{353,33},{328,33}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		saft = {
			polygon = {
				{479,17},{632,17},{632,56},{479,132}
			},
			exclusion = {
				{624,17},{632,17},{632,33},{624,33}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		pbow = {
			polygon = {
				{328,239},{474,165},{474,282},{328,282}
			},
			exclusion = {
				{328,270},{337,270},{337,282},{328,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		paft = {
			polygon = {
				{479,163},{632,241},{632,282},{479,282}
			},
			exclusion = {
				{632,271},{632,285},{624,285},{624,271}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
	},
}, layout_blarney_cross_common)
layout_blarney_common.__index = layout_blarney_common

-- different layouts
local layout_blarney_5 = setmetatable({
	imgname = 'BSG-CustomBoard-3-5p.png',
	main_area = {x=190,y=186},
	tokens = recta(418, 47, 425, 59, {stride_y=16}),
	names = recta(429, 47, 523, 59, {stride_y=16}),
	chars = recta(527, 47, 601, 59, {stride_y=16}),
	opg = recta(605, 47, 623, 59, {stride_y=16}),
	skill_count = recta(627, 47, 644, 60, {stride_y=16}),
	trauma_count = recta(647, 47, 664, 60, {stride_y=16}),
	admiral = recta(668, 47, 681, 59, {stride_y=16}),
	president = recta(682, 47, 695, 59, {stride_y=16}),
	cag = recta(696, 47, 709, 59, {stride_y=16}),
	boarding = recta(707,140,721,154, {stride=16}),
	allies = recta(731,79,812,92,{stride_y=16}),
	allies_token = recta(720,79,727,91,{stride_y=16}),
	turn = recta(448,8,465,21),
	nukes= recta(747,31,764,44),
	quorum = recta(796,31,813,44),
	jump_prep = rectr(514,140,14,14,{stride=16}),
	pursuit = rectr(701,163,14,14,{stride=16}),
	distance = rectr(484,163,6,14,{stride=8}),
	horizontal_raptors = true,
	viper2 = recta(321, 117, 335,136,{stride=16, stride_y=140-117}),
	viper7 = recta(369,116, 382,137, {stride=16, stride_y =139-116}),
	raptor = recta(319,162,337,175, {stride=340-319})
}, layout_blarney_common)
local layout_blarney_6 = setmetatable({
	imgname = 'BSG-CustomBoard-3-6p.png',
	main_area = {x=190,y=186},
}, layout_blarney_common)
local p7_ofs=103
local layout_blarney_7 = setmetatable({
	imgname = 'BSG-CustomBoard-3-7p.png',
	main_area = {x=190,y=196},
	tokens = recta(418+p7_ofs, 24, 425+p7_ofs, 36, {stride_y=16}),
	names = recta(429+p7_ofs, 24, 523+p7_ofs, 36, {stride_y=16}),
	chars = recta(527+p7_ofs, 24, 601+p7_ofs, 36, {stride_y=16}),
	opg = recta(605+p7_ofs, 24, 623+p7_ofs, 36, {stride_y=16}),
	skill_count = recta(627+p7_ofs, 24, 644+p7_ofs, 37, {stride_y=16}),
	trauma_count = recta(647+p7_ofs, 24, 664+p7_ofs, 37, {stride_y=16}),
	admiral = recta(668+p7_ofs, 24, 681+p7_ofs, 36, {stride_y=16}),
	president = recta(682+p7_ofs, 24, 695+p7_ofs, 36, {stride_y=16}),
	cag = recta(696+p7_ofs, 24, 709+p7_ofs, 36, {stride_y=16}),
	nukes= recta(445,40,461,53),
	quorum = recta(494,40,511,53),
	turn = recta(459,8,476,21),
	horizontal_raptors = false,
	jump_prep = rectr(514,149,14,14,{stride=16}),
	distance = rectr(484,172,6,14,{stride=8}),
	pursuit = rectr(701,172,14,14, {stride=16}),
	boarding = rectr(707,149,14,14, {stride=16}),
	allies_token = recta(417,87,427,102,{stride_y=16}),
	allies = recta(429,87,512,102,{stride_y=16}),
	viper2 = recta(321, 117, 335,136,{stride=16, stride_y=141-117}),
	viper7 = recta(369,116, 382,137, {stride=16, stride_y =140-116}),
	raptor = recta(329,166,342,184, {stride=345-329}),
	distance_nr = recta(464,172,483,187),
}, layout_blarney_common)

db_ofs=41
local layout_db_7 = setmetatable({
	imgname = 'BSG-Daybreak_wCFB.png',
	main_area = {x=190,y=208},
	fuel_token = recta(132,99,156,115),
	food_token = recta(158,99,182,115),

	locations = {
		["Quorum Chamber"] = rectr(131,28,49,12),
		["Press Room"] = rectr(131,28+16,49,12),
		["President's Office"] = rectr(131,28+16+16,49,12),
		["Administration"] = rectr(131,28+32+16,49,12),

		["FTL Control"] = rectr(131,103+16,49,12),
		["Weapons Control"] = rectr(131,103+16*2,49,12),
		["Command"] = rectr(131,103+16*3,49,12),
		["Communications"] = rectr(131,103+16*4,49,12),
		["Admiral's Quarters"] = rectr(131,103+16*5,49,12),
		["Research Lab"] = rectr(131,103+16*6,49,12),
		["Hangar Deck"] = rectr(131,103+16*7,49,12),
		["Armory"] = rectr(131,103+16*8,49,12),
		["Sickbay"] = rectr(131,103+16*9,49,12),
		["Brig"] = rectr(131,103+16*10,49,12),
		
		["Pegasus CIC"] = rectr(131,306,49,12),
		["Airlock"] = rectr(131,306+16,49,12),
		["Main Batteries"] = rectr(131,306+32,49,12),
		["Engine Room"] = rectr(131,306+48,49,12),
		
		["Bridge"] = rectr(131,397,49,12),
		["Tactical Plot"] = rectr(131,397+16,49,12),
		["Captain's Cabin"] = rectr(131,397+32,49,12),
		
		["Caprica"] = rectr(131,479,20,12),
		["Cylon Fleet"] = rectr(131,479+16,20,12),
		["Human Fleet"] = rectr(131,479+32,20,12),
		["Resurrection Ship"] = rectr(131,479+48,20,12),
		["Basestar Bridge"] = rectr(131,479+64,20,12),
	},
	damage_locations = {
		["FTL Control"] = rectr(7, 103+16, 9, 15),
		["Weapons Control"] = rectr(7, 103+16*2, 9, 15),
		["Command"] = rectr(7, 103+16*3, 9, 15),
		["Admiral's Quarters"] = rectr(7, 103+16*4, 9, 15),
		["Hangar Deck"] = rectr(7, 103+16*7, 9, 15),
		["Armory"] = rectr(7, 103+16*8, 9, 15),
		["Pegasus CIC"] = rectr(7, 290+16, 9, 15),
		["Airlock"] = rectr(7, 290+16*2, 9, 15),
		["Main Batteries"] = rectr(7, 290+16*3, 9, 15),
		["Engine Room"] = rectr(7, 290+16*4, 9, 15),
	},
	fuel_number = recta(263,27,282,42),
	food_number = recta(263,27+16,282,42+16),
	morale_number = recta(263,27+32,282,42+32),
	pop_number = recta(263,27+48,282,42+48),


	tokens = recta(418+db_ofs, 26, 425+db_ofs, 36, {stride_y=16}),
	names = recta(429+db_ofs+1, 26, 523+db_ofs, 36, {stride_y=16}),
	chars = recta(586+1, 26, 667, 36, {stride_y=16}),
	miracle = recta(711, 26, 728, 36, {stride_y=16}),
	skill_count = recta(671, 26, 688, 37, {stride_y=16}),
	mutiny_count = recta(691, 26, 708, 37, {stride_y=16}),
	admiral = recta(668+87, 26, 681+db_ofs, 36, {stride_y=16}),
	president = recta(682+87, 26, 695+db_ofs, 36, {stride_y=16}),
	cag = recta(696+87, 26, 709+db_ofs, 36, {stride_y=16}),
	nukes= recta(418,73,444,86),
	quorum = recta(418,121,444,134),
	turn = recta(418,24,444,37),
	horizontal_raptors = true,
	distance_nr = recta(445,184,464,199),
	
	jump_prep = rectr(495,161,14,14,{stride=16}),
	distance = rectr(465,184,6,14,{stride=8}),
	pursuit = rectr(682,184,14,14, {stride=16}),
	boarding = rectr(688,161,14,14, {stride=16}),
	
	civ_order = {
		{{pop1=true},{pop1=true},{pop1=true},},
		{{pop1=true},{pop1=true},{pop1=true},},
		{{empty=true},{pop2=true},{popf=true}},
		{{empty=true},{pop2=true},{popm=true}},
	},
	civs = recta(201,118,225,134,{stride=28, stride_y=20}),

	
	viper2 = recta(298, 117, 311,136,{stride=17, stride_y=141-117}),
	viper7 = recta(349,116, 362,137, {stride=17, stride_y =140-116}),
	raptor = recta(296,164,315,179, {stride=318-296}),
	araptor = recta(296,182, 315,197, {stride=318-296}),


	space = {
		offset = {7,12},
		front = {
			polygon = {
				{9,63},{102,118},{102,180},{9,234}
			},
			exclusion = {
				{9,156},{39,156},{39,143},{9,143}
			},
			cylon_prefer = "left",
			colonial_prefer = "right",
		},
		rear = {
			polygon = {
				{313,65},{313,230},{225,180},{225,116}
			},
			exclusion = {
				{293,141},{313,141},{313,155},{293,155}
			},
			cylon_prefer = "right",
			colonial_prefer = "left",
		},
		pbow = {
			polygon = {
				{8,240},{131,173},{161,187},{161,282},{8,262}
			},
			exclusion = {
				{8,273},{65,273},{65,282},{8,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		paft = {
			polygon = {
				{165,282},{165,187},{197,173},{313,238},{313,282}
			},
			exclusion = {
				{240,273},{313,273},{313,282},{240,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		sbow = {
			polygon = {
				{8,13},{162,13},{162,121},{119,121},{8,56}
			},
			exclusion = {
				{8,30},{94,30},{94,13},{8,13}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		saft = {
			polygon = {
				{166,14}, {313,14},{313,60},{203,121},{166,121},
			},
			exclusion = {
				{211,13},{313,14},{313,30},{211,30}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
	},
	cylon_fleet_board = {
		offset = {7,12},
		front = {
			polygon = {
				{328,68},{414,116},{414,181},{328,228}
			},
			exclusion = {
				{328,141},{352,141},{352,155},{328,155}
			},
			cylon_prefer = "left",
			colonial_prefer = "right",
		},
		rear = {
			polygon = {
				{542,114},{632,64},{632,233},{542,182}
			},
			exclusion = {
				{623,140},{632,140},{632,156},{623,156}
			},
			cylon_prefer = "right",
			colonial_prefer = "left",
		},
		sbow = {
			polygon = {
				{328,17},{475,17},{475,127},{328,57}
			},
			exclusion = {
				{328,17},{353,17},{353,33},{328,33}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		saft = {
			polygon = {
				{479,17},{632,17},{632,56},{479,132}
			},
			exclusion = {
				{624,17},{632,17},{632,33},{624,33}
			},
			cylon_prefer = "top",
			colonial_prefer = "bottom",
		},
		pbow = {
			polygon = {
				{328,239},{474,165},{474,282},{328,282}
			},
			exclusion = {
				{328,270},{337,270},{337,282},{328,282}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
		paft = {
			polygon = {
				{479,163},{632,241},{632,282},{479,282}
			},
			exclusion = {
				{632,271},{632,285},{624,285},{624,271}
			},
			cylon_prefer = "bottom",
			colonial_prefer = "top",
		},
	},
}, {__index = function(t,k)
	for _,j in ipairs({layout_blarney_daybreak_icons, layout_blarney_common}) do
		if j[k] then
			return j[k]
		end end end})

local layouts = {
	[3] = layout_blarney_5,
	[4] = layout_blarney_5,
	[5] = layout_blarney_5,
	[6] = layout_blarney_7, --6p currently not implemented
	[7] = layout_blarney_7,
}
local icons

function new_gfx(state)
	local t = {state = state, layout = layouts[#state.players]}
	if state.daybreak then t.layout = layout_db_7 end
	setmetatable(t, {__index=gfx_meta})
	return t
end

--[[
image library methods
load(filename) returns an image object or nil if fails

image object methods
:blit(src, dst, src, area)
:load(filename)
:copyfrom
:save(filename)
]]

local function draw_bar(img, s, d, n)
	s = copy(s)
	d = copy(d)
	for i=1,n do
		img:Blit(icons.img, d.x0, d.y0, s.x0, s.y0, d:width(), d:height())
		s:do_stride() d:do_stride()
	end
end

function gfx_meta:blit_centered(target, src, target_rect, src_rect, directions)
	local sw = src_rect:width()
	local sh = src_rect:height()
	local tw = target_rect:width()
	local th = target_rect:height()
	local ox, oy
	
	ox = math.floor((tw - sw) / 2 + 0.5)
	oy = math.floor((th - sh) / 2 + 0.5)
	
	if directions then
		if not directions.x then ox = 0 end
		if not directions.y then oy = 0 end
	end
	
	target:Blit(src, target_rect.x0+ox,target_rect.y0+oy, src_rect.x0, src_rect.y0, sw, sh)
end

function gfx_meta:blit(target, src, target_rect, src_rect)
	target:Blit(src, target_rect.x0, target_rect.y0, src_rect.x0, src_rect.y0, src_rect:width(), src_rect:height())
end

local polyfuncs = {}
function polyfuncs:init()
	self.points = {}
	self.queue = {}
	self.allocations = {}
end
function polyfuncs:add(pt)
	table.insert(self.points, copy(pt))
end
function polyfuncs:close()
	assert(#self.points > 1)
	table.insert(self.points, copy(self.points[1]))
end
function polyfuncs:exclude(ex)
	table.insert(self.allocations, ex)
end

-- From http://rosettacode.org/wiki/Ray-casting_algorithm
local function ray_intersect(pt,p0,p1)
	-- check if p0-p1 intersects ray pt.x,pt.y -> -inf,pt.y
	if p0[2] > p1[2] then p0,p1 = p1,p0 end
	
	local px,py = pt[1],pt[2]
	local p0x,p0y = p0[1],p0[2]
	local p1x,p1y = p1[1],p1[2]
	local maxx, minx
	if p0x > p1x then
		maxx, minx = p0x, p1x
	else
		minx, maxx = p0x, p1x
	end

	if py == p0y or py == p1y then py = py + 0.1 end
	if py < p0y or py > p1y then
		return false
	elseif px > maxx then
		return false
	elseif px < minx then
		return true
	else
		local r,b
		if p0x ~= p1x then
			r = (p1y-p0y) / (p1x-p0x)
		else
			r = math.huge
		end
		if p0x ~= px then
			b = (py-p0y) / (px-p0x)
		else
			b = math.huge
		end
		return b >= r
	end
end

-- From http://wiki.processing.org/w/Line-Line_intersection
local function line_line_intersect(pa0,pa1, pb0,pb1)
	local bx = pa1[1]-pa0[1]
	local by = pa1[2]-pa0[2]
	local dx = pb1[1]-pb0[1]
	local dy = pb1[2]-pb0[2]
	local dotp = bx * dy - by * dx
	if dotp == 0 then return end
	local cx,cy = pb0[1]-pa0[1], pb0[2]-pa0[2]
	local t = (cx * dy - cy * dx) / dotp
	if t < 0 or t > 1 then return end
	local u = (cx * by - cy * bx) / dotp
	if u < 0 or u > 1 then return end
	return true, pa0[1]+t*bx, pa0[2]+t*by
end

function polyfuncs:included(ptlist)
	for i=1,#ptlist-1 do
		-- Internal
		if not self:ptin(ptlist[i]) then return end
	end
	return true
end

function polyfuncs:polyintersect(ptlist, allow_internal)
	-- Quick check for internal or enclosing
	for i=1,#ptlist-1 do
		-- Internal
		if not allow_internal and self:ptin(ptlist[i]) then return true end
		
		local count = 0
		for j=1,#self.points - 1 do
			if ray_intersect(self.points[j], ptlist[i], ptlist[i+1]) then
				count = count + 1
			end
		end
		-- Enclosing
		if count % 2 == 1 then return true end
	end
	
	-- Quick check for enclosing
	for i=1,#ptlist-1 do
		for j=1,#self.points-1 do
			if line_line_intersect(ptlist[i],ptlist[i+1],self.points[j],self.points[j+1]) then
				return true
			end
		end
	end
	
	-- Non-intersecting
end

function polyfuncs:ptin(pt)
	-- is point in our main region?
	local count = 0
	for i=1, #self.points-1 do
		if ray_intersect(pt, self.points[i], self.points[i+1]) then
			count = count + 1
		end
	end
	return count % 2 == 1
end
function polyfuncs:allocate_blob(w,h, pref)
	-- find a free width/height area that is not excluded
	-- ideally on the side of preference, if possible
	local occupied = self.allocations
	local function f(x,y)
		local list = {{x,y},{x+w,y},{x+w,y+h},{x,y+h},{x,y}}
		if self:included(list) and not self:polyintersect(list, true) then
			for k,v in pairs(occupied) do
				if v:polyintersect(list) then
					return
				end
			end
			local p = setmetatable({}, {__index=polyfuncs})
			p:init()
			for i=1,4 do p:add(list[i]) end
			p:close()
			table.insert(occupied, p)
			return rectr(x,y,w,h)
		end
	end
	
	-- Decode how to iterate
	local minx, maxx, miny, maxy = self.points[1][1], self.points[1][2], self.points[1][1], self.points[1][2]
	for k,v in ipairs(self.points) do
		local x,y = v[1],v[2]
		if x < minx then minx = x elseif x > maxx then maxx = x end
		if y < miny then miny = y elseif y > maxy then maxy = y end
	end
	
	local dx,dy = maxx-minx, maxy-miny
	local dmax = dx
	if dy > dmax then dmax = dy end
	
	local cx,cy = math.floor((maxx+minx) / 2), math.floor((maxy+miny) / 2)

	local translate
	if pref == "top" then
		translate = function (x,y) return y,x end
	elseif pref == "bottom" then
		translate = function (x,y) return y,-x end
	elseif pref == "right" then
		translate = function (x,y) return -x,y end
	else
		translate = function (x,y) return x,y end
	end

	local iter
	do
		local w = math.floor(dmax / 2)
		local _x,_y,_flag,_o = -w,0,false,0
		iter = function()
			if _x >= w then return nil end
			local rx,ry = _x,_y
			if _flag then
				ry = ry - _o
				_flag = false
				_o = _o + 1
				if _o >= w then
					_o = 0
					_x = _x + 1
				end
			else
				ry = ry + _o
				_flag = true
			end
			
			return translate(rx,ry)
		end
	end

	for x,y in iter do
		x = x + cx
		y = y + cy
		if self:ptin({x,y}) then
			local r = f(x,y)
			if r then
				return r
			end
		end
	end
	return nil
end

function gfx_meta:draw_ships(img, ships, layout, offset, iconf, icons, drawoffset)
	-- things and quantities which must be drawn
	local viper2, viper7, scar, radiers, heavies, basestar, civ, araptor
	
	araptor = ships.araptor or 0
	viper2 = ships.viper or 0
	viper7 = ships.viper7 or 0
	scar = ships.scar or 0
	raiders = ships.raider or 0
	heavies = ships.heavy or 0
	basestar = ships.basestar and #ships.basestar or 0
	nciv = ships.civ and #ships.civ or 0
	civ = ships.civ
	
	if not layout.polygon then return end

	local ex
	if layout.exclusion then
		ex = setmetatable({}, {__index=polyfuncs})
		ex:init()
		for k,v in ipairs(layout.exclusion) do
			ex:add({v[1] - offset[1], v[2]-offset[2]})
		end
		ex:close()
	end
	
	local p = setmetatable({}, {__index=polyfuncs})
	p:init()
	
	for k,v in ipairs(layout.polygon) do
		p:add({v[1] - offset[1], v[2]-offset[2]})
	end
	p:close()
	if ex then p:exclude(ex) end
	local ordering = {'civ','araptor','viper','viper7','basestar','scar','raider','heavy',}
	for k,v in ipairs(ordering) do
		local stype = 'cylon'
		if v=='viper' or v=='viper7' or v=='civ' or v=='araptor' then stype = 'colonial' end
		local n = ships[v] or 0
		if type(n) == 'table' then n = #n end
		local icon = icons.space[v]
		local draw_src = icon
		local pilots = copy(ships.pilots or {})
		for i=1,n do
			local r = p:allocate_blob(icon:width(), icon:height(), layout[stype .. '_prefer'])
			if v == 'civ' then
				-- draw appropriate civilian icon here
				local tonum={A=0,B=1,C=2,D=3,E=4,F=5,G=6,H=7,I=8,J=9,K=10,L=11}
				draw_src = icon:translate(tonum[ships[v][i].label], 0)
			end
			if r then
				img:Blit(iconf, r.x0+drawoffset.x, r.y0+drawoffset.y, draw_src.x0, draw_src.y0, draw_src:width(), draw_src:height())
			else
				print("Can't find space to fit %s!", v)
			end
			
			if v == 'basestar' then
				-- draw damage tokens
			end

			for k,p in ipairs(pilots) do
				if p.what == v then
					-- draw player token
					local at = copy(r)
					local dx, dy = drawoffset.x + (at.x1 - at.x0) * 0.3, drawoffset.y + (at.y1 - at.y0) * 0.25
					at.x0 = at.x0 + dx
					at.x1 = at.x1 + dx
					at.y0 = at.y0 + dy
					at.y1 = at.y1 + dy
					self:draw_player_token(img, iconf, p.who, at)
					table.remove(pilots, k)
					break
				end
			end
		end
	end
end

function gfx_meta:draw_player_token(img, iconf, who, where, dir)
	local player_token_lookup = {
		1, 3, 5, 6, 9, 12, 10
	}
	local icon_location = get_token(icons,who.token or player_token_lookup[who.number])

	self:blit_centered(img, iconf, where, icon_location, dir)
end

function gfx_meta:dump_image(img)
	icons = self.state.daybreak and layout_blarney_daybreak_icons or layout_blarney_icons
	icons.daybreak_icons = layout_blarney_daybreak_icons
	self.src = LoadImage(string.format('%s/src.png', self.state.short_name))
	for k,v in ipairs({self.layout, layout_blarney_daybreak_icons, layout_blarney_icons}) do
		v.img = LoadImage(v.imgname)
	end
	img:CopyFrom(self.src or self.layout.img)
	
	local layout = self.layout
	local state = self.state
	local s,d
	local iconf = icons.img
	local fontf = LoadImage(icons.img2name)

	local function blit(to, from)
		self:blit(img, iconf, to, from)
	end
	local function blitc(to, from, dir)
		self:blit_centered(img, iconf, to, from, dir)
	end
	
	-- populate resource bars
	draw_bar(img, icons.res_food, layout.res_food, state.food)
	draw_bar(img, icons.res_pop, layout.res_pop, state.pop)
	draw_bar(img, icons.res_morale, layout.res_morale, state.morale)
	draw_bar(img, icons.res_fuel, layout.res_fuel, state.fuel)
	
	icons.green_font:draw(img,iconf, layout.fuel_number, state.fuel)
	icons.green_font:draw(img,iconf, layout.food_number, state.food)
	icons.green_font:draw(img,iconf, layout.morale_number, state.morale)
	icons.green_font:draw(img,iconf, layout.pop_number, state.pop)
	icons.green_font:draw(img,iconf, layout.distance_nr, state.distance)
	
	draw_bar(img, icons.jump, layout.jump_prep, state.jump_track+1)
	draw_bar(img, icons.pursuit, layout.pursuit, state.pursuit_track+1)
	draw_bar(img, icons.distance, layout.distance, state.distance)

	
	if not state.fuel_token_hit then
		blit(icons.fuel_token, layout.fuel_token)
	end
	if not state.food_token_hit then
		blit(icons.food_token, layout.food_token)
	end
	
	for k,v in pairs(state.damage) do
		local rect = layout.damage_locations[k]
		if rect then
			img:Blit(iconf, rect.x0-1, rect.y0-2, icons.damage_icon.x0-1,icons.damage_icon.y0-1, rect:width()+1, rect:height()+1)
		end
	end
	
	-- after damage, do overlays
	if state.pegasus_destroyed then
		blit(layout.pegasus_destroyed_overlay, icons.pegasus_destroyed_overlay)
	end
	if state.colonial_one_destroyed then
		blit(layout.colonial_one_destroyed_overlay, icons.colonial_one_destroyed_overlay)
	end
	
	-- boarding track
	for k,v in ipairs(state.boarding_track) do
		if v > 0 then
			local src = icons.centurions:translate(v - 1)
			local dst = layout.boarding:translate(k - 1)
			blit(dst, src)
		end
	end
	
	local player_locations = {}
	local ally_locations = {}
	
	-- render player locations & status line
	for k,v in ipairs(state.players) do
		local is_president = (v == state.president)
		local is_admiral = (v == state.admiral)
		local is_cag = (v == state.cag)
		
		local token = layout.tokens:translate(0,v.number-1)
		
		self:draw_player_token(img, iconf, v, token)


		-- draw in location area
		if v.location then
			local loc = layout.locations[v.location.name]
			if loc then
				loc = copy(loc)
				local key = v.location.name
				if player_locations[key] then
					loc:do_stride((get_token(icons,1):width() + 2) * player_locations[key])
				end
				player_locations[key] = (player_locations[key] or 0) + 1
				self:draw_player_token(img, iconf, v, loc, {y=true})
				
			end
		end
		if not state.daybreak then
			blitc(layout.opg:translate(0,v.number-1), (v.opg_used and icons.opg_used) or icons.opg_avail)
		end
		
		if state.admiral == v then
			blitc(layout.admiral:translate(0,v.number-1), icons.admiral)
		end
		if state.cag == v then
			blitc(layout.cag:translate(0,v.number-1), icons.cag)
		end
		if state.president == v then
			blitc(layout.president:translate(0,v.number-1), icons.president)
		end
		if layout.miracle then
			icons.miracle_font:draw(img,iconf, layout.miracle:translate(0,v.number-1), v.miracle)
		end
		if layout.mutiny_count and v.mutiny_hand then
			icons.mutiny_font:draw(img,iconf, layout.mutiny_count:translate(0,v.number-1), #v.mutiny_hand)
		end
		if v.trauma and state.ionian_nebula then
			local n = v.trauma.benevolent + v.trauma.antagonistic
			icons.grey_font:draw(img,iconf, layout.trauma_count:translate(0,v.number-1), n)
		end
		icons.grey_font:draw(img,iconf, layout.skill_count:translate(0,v.number-1), #v.hand)
		
		local namerect, name_icons = get_player_name_rect(icons, v.name)
		if namerect then
			self:blit_centered(img, name_icons.img, layout.chars:translate(0,k-1), namerect,{y=true})
		else
		print("no namerect! " .. v.name)
		end
		icons.full_font:draw(img,fontf, layout.names:translate(0,k-1), v.player,{align="left"})
	end

	if state.allies then
		for k,v in ipairs(state.allies) do
			local icon = get_ally_token(icons,v.token or k)
			
			blitc(layout.allies_token:translate(0,k-1), icon)
			local ally = find_ally(v.name)
			local loc = copy(layout.locations[ally.location])
			ally_locations[ally.location] = (ally_locations[ally.location] or 0) + 1
			loc.x0 = loc.x1 - (icon:width() + 4) * ally_locations[ally.location]
			blitc(loc, icon)
			
			blitc(layout.allies:translate(0,k-1), get_ally_name_rect(icons, v.name),{y=true})
		end
	end
	
	icons.brown_font:draw(img,iconf, layout.quorum, #state.quorum_hand)
	icons.red_font:draw(img,iconf, layout.nukes, state.nukes)
	icons.grey_font:draw(img,iconf, layout.turn, state.turn)
	
	-- normal state images have the new caprica board setup, but if not currently
	-- there, it makes no sense to show it, so either blit it out, or show the state info
	if state.at_new_caprica then
		-- draw new caprica state
		error('new caprica images unsupported')
	else
		if not state.daybreak then
			img:BlitEmpty(layout.main_area.x, layout.main_area.y)
		end
		
		local exodus_zero = {x=8,y=13}
		local exodus = LoadImage('BSG-CustomBoard-3-exodus.png')
		img:Blit(exodus, layout.main_area.x, layout.main_area.y, exodus_zero.x, exodus_zero.y,
			'*', '*')
	end
	
	
	-- rather than tie specific civs to images, just calculate the numbers
	local pop1, pop2, empty, popf, popm = 0, 0, 0, 0, 0
	local civs = copy(state.civ)
	
	-- pull in civvies in space areas
	for k,v in pairs(state.space) do
		for _,u in pairs(v.civ or {}) do
			table.insert(civs, u)
		end
	end
	
	for k,v in pairs(civs) do
		if not v.pop then empty = empty + 1
		elseif v.pop == 2 then pop2 = pop2 + 1
		elseif v.fuel then popf = 1
		elseif v.morale then popm = 1
		else pop1 = pop1 + 1
		end
	end
	
	local civvies = {pop1=pop1,pop2=pop2,empty=empty,popf=popf,popm=popm}
	for y,v in ipairs(layout.civ_order) do
		for x,u in ipairs(v) do
			local found = false
			for w,_ in pairs(u) do
				if civvies[w] > 0 then
					found = true
					civvies[w] = civvies[w] - 1
				end
			end
			if found then
				for _y,a in pairs(icons.civ_order) do for _x,b in pairs(a) do
					if (next(u)) == (next(b)) then
						local r = layout.civs
						local s = icons.civs
						img:Blit(icons.img, r.x0+r.stride*(x-1),r.y0+r.stride_y*(y-1),
											s.x0+s.stride*(_x-1),s.y0+s.stride_y*(_y-1),
											r:width(), r:height())
						break
					end
				end end
			end
		end
	end
	
	local raptor_icon = (layout.horizontal_raptors and icons.raptor_h) or icons.raptor_v
	local raptor = copy(layout.raptor)
	for i=1, state.raptor do
		if raptor_icon then self:blit(img,iconf, raptor, raptor_icon) end
		raptor:do_stride()
	end

	local araptor_icon = icons.araptor_h
	local flying_raptors, reserve_raptors = 0, state.araptor
	local araptor = copy(layout.araptor)
	for k,v in pairs(state.space) do flying_raptors = flying_raptors + (v.araptor or 0) end
	for i=1,4 do
		if araptor_icon then
			local icon
			if flying_raptors > 0 then
				icon = araptor_icon.active
				flying_raptors = flying_raptors - 1
			elseif reserve_raptors > 0 then
				icon = araptor_icon.reserve
				reserve_raptors = reserve_raptors - 1
			else
				break
			end
			self:blit(img,iconf, araptor, icon)
		end
		if araptor then araptor:do_stride() end
	end
	
	-- draw ships in space
	for k,v in pairs(state.space) do
		self:draw_ships(img, v, self.layout.space[k], self.layout.space.offset, iconf, icons, layout.main_area)
	end
	
	-- ship reserves / repair / flight status
	if state.exodus then
		for k,v in pairs(state.cylon_fleet_board) do
			self:draw_ships(img, v, self.layout.cylon_fleet_board[k],
				self.layout.cylon_fleet_board.offset, iconf, icons, layout.main_area)
		end
	else
		error('non-exodus ship layouts not supported')
	end

	if state.exodus then
		-- layout is 3x2 and then 2x2
		local at
		local reserve, damaged, flying = state.viper,state.damaged_viper,0
		for k,v in pairs(state.space) do flying = flying + (v.viper or 0) end
		at = layout.viper2
		for x=0,2 do
			for y=0,1 do
				local src
				if reserve > 0 then
					reserve = reserve - 1
					src = icons.viper2.reserve
				elseif flying > 0 then
					flying = flying - 1
					src = icons.viper2.active
				elseif damaged > 0 then
					damaged = damaged - 1
					src = icons.viper2.damaged
				end
				
				if src then
					self:blit(img,iconf, at:translate(x,y), src)
				end
			end
		end
		
		reserve, damaged, flying = state.viper7,state.damaged_viper7,0
		for k,v in pairs(state.space) do flying = flying + (v.viper7 or 0) end
		at = layout.viper7
		for y=0,1 do
			for x=0,1 do
				local src
				if reserve > 0 then
					reserve = reserve - 1
					src = icons.viper7.reserve
				elseif damaged > 0 then
					damaged = damaged - 1
					src = icons.viper7.damaged
				elseif flying > 0 then
					flying = flying - 1
					src = icons.viper7.active
				end
				
				if src then
					self:blit(img,iconf, at:translate(x,y), src)
				end
			end
		end
	end
end

local function FakeImageSetup()
	local str = ''
	local index = 1
	local t = {}
	local file = io.open('img_write.lua', 'w')
	local function flush()
		file:write(str)
		file:flush()
		str = ''
	end
	function t:width()
		return self.name .. ':width()'
	end
	function t:height()
		return self.name .. ':height()'
	end
	function t:Load(n)
		str = str .. string.format('%s:Load(%q)\n',self.name,n)
	end
	function t:Save(n)
		str = str .. string.format('%s:Save(%q)\n',self.name,n)
		flush()
	end
	function t:Blit(src, dx,dy,sx,sy,w,h)
		str = str .. string.format('%s:Blit(%s,',self.name, src.name)
		local s = ''
		for k,v in ipairs({dx,dy,sx,sy,w,h}) do
			if s ~= '' then s = s .. ', ' end
			local tmp
			if type(v) == "number" then tmp = tostring(v)
			else tmp = string.format('%q',v) end
			s = s .. string.format('%s', tmp)
		end
		str = str .. s .. ')\n'
	end
	function t:BlitEmpty(x,y)
		str = str .. string.format('%s:BlitEmpty(%d,%d)\n',self.name,x,y)
	end
	function t:CopyFrom(src)
		str = str .. string.format('%s:CopyFrom(%s)\n', self.name, src.name)
	end
	local function mkimg()
		local v = setmetatable({name=string.format('img%d', index)}, {__index=t})
		index = index+1
		return v
	end
	CreateEmptyImage = function ()
		local ret = mkimg()
		str = str .. ret.name ..  ' = CreateEmptyImage()\n'
		return ret
	end
	LoadImage = function (name)
		local f = io.open(name,'r')
		if not f then return end
		f:close()
		
		local ret = mkimg()
		str = str .. ret.name ..  string.format(' = LoadImage(%q)\n', name)
		return ret
	end
end

function gfx_meta:main_state(out_filename)
	if not CreateEmptyImage then
		FakeImageSetup()
	end
	local img = CreateEmptyImage()
	
	local ret,err = pcall(function () self:dump_image(img) end)
	if err then print(err) end
	img:Save(out_filename)
end
