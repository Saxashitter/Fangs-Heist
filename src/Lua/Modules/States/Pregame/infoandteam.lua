local state = {}
local FH = FangsHeist

local ICON_WIDTH = 16*FU
local ICON_PAD = 2*FU
local ICON_ROW = 4

local JOIN = {}
local JOIN_W = 80
local JOIN_H = 16
local JOIN_X = 6
local JOIN_Y = 24
local JOIN_L = 8
local JOIN_F = V_SNAPTOLEFT

local READY = {}
local READY_X = 160
local READY_Y = 178
local READY_F = V_SNAPTOBOTTOM
local READY_TICS = 0

local REQUEST = {}
local REQUEST_W = 80
local REQUEST_H = 16
local REQUEST_X = 320 - 6 - REQUEST_W
local REQUEST_Y = 24
local REQUEST_L = 8
local REQUEST_F = V_SNAPTORIGHT

local STATES = {JOIN, READY, REQUEST}

local function IsPlayerValid(p)
	if not p
	or not p.valid
	or not p.heist
	or p.heist.spectator then
		return false
	end

	return true
end

local function IsSpriteValid(skin, sprite, frame)
	local skin = skins[skin]
	local sprites = skin.sprites[sprite]
	local numframes = sprites.numframes

	if numframes
	and numframes > frame then -- B = 2 so, check if it has the B frame
		return true
	end

	return false
end

local function GetSkinIcon(v, skin)
	if IsSpriteValid(skin, SPR2_LIFE, A) then
		return v.getSprite2Patch(skin, SPR2_LIFE, false, A)
	end

	return v.cachePatch("CONTINS"), true
end

local function HasRequested(joiner, leader)
	for _, p in ipairs(leader.heist.invites) do
		if p == joiner then
			return true
		end
	end

	return false
end

local function IsTeamFull(team)
	local teamLength = FangsHeist.getGamemode().teamlimit

	return team and #team >= teamLength
end

local function IsPlayerEligibleToRequest(self, p)
	if not IsPlayerValid(p) then
		return false
	end

	local team = p.heist:getTeam()

	if IsTeamFull(team) then
		return false
	end

	if team[1] ~= p then
		return false
	end

	if HasRequested(self, p) then
		return false
	end

	return true
end

local function IsPlayerEligibleForTeam(self, p)
	if not IsPlayerValid(p) then
		return false
	end

	local team = p.heist:getTeam()

	return true
end

local function CanPlayerSeeMenus(p)
	if not IsPlayerValid(p) then
		return false
	end

	local team = p.heist:getTeam()

	if IsTeamFull(team) then
		return false
	end

	if team[1] ~= p then
		return false
	end

	return true
end

local function GetPlayerList(blacklist, ...)
	local list = {}

	for i = 1, 32 do
		if not IsPlayerValid(players[i-1]) then
			continue
		end

		if blacklist
		and blacklist(players[i-1], ...) then
			continue
		end

		table.insert(list, players[i-1])
	end

	return list
end

local function JoinTeam(leader, joiner)
	joiner.heist.invites = {}

	for i = #leader.heist.invites, 1, -1 do
		local p = leader.heist.invites[i]

		if p == joiner then
			table.remove(leader.heist.invites, i)
		end
	end

	leader.heist:addIntoTeam(joiner)
end

local function RequestJoin(joiner, leader)
	if leader.bot then
		JoinTeam(joiner, leader)
		return
	end

	table.insert(joiner.heist.invites, leader)
end

local function SetState(p, i)
	if p.heist.team.state == i then
		return
	end

	local last = p.heist.team.state

	if STATES[i].canSwitchTo
	and not STATES[i].canSwitchTo(p) then
		return
	end

	if last ~= nil
	and STATES[last].onUnselect then
		STATES[last].onUnselect(p)
	end
	if STATES[i].onSelect then
		STATES[i].onSelect(p)
	end

	p.heist.team.state = i
end

local rect
local function DrawRect(v, x, y, width, height, flags, color)
	if not rect
	or not rect.valid then
		rect = v.cachePatch("FH_BLACK")
	end

	local xscale = FixedDiv(width, rect.width)
	local yscale = FixedDiv(height, rect.height)

	v.drawStretched(
		x*FU, y*FU, xscale, yscale, rect, flags, color
	)
end

local function DrawMenu(v, x, y, width, height, length, items, selected, offset, flags)
	local start = offset
	if #items > length then
		offset = min($, #items-length)
	end

	for i = start, start+length do
		local str = items[i]
		local y = y + height*(i-start)
		local color = SKINCOLOR_CORNFLOWER

		if i == selected
		and #items then
			color = SKINCOLOR_SKY
		end

		DrawRect(v, x, y, width, height, flags, v.getColormap(TC_BLINK, color))

		if not str
		or not #items then continue end

		if #str > 16 then
			str = string.sub($, 1, 16)
		end
		FH.DrawString(v,(x+4)*FU,(y+4)*FU,FU,
		str,"FHTXT",nil,flags)
	end

	if not #items then
		local selcol = (selected) and v.getStringColormap(V_REDMAP) or nil
		FH.DrawString(v,(x+width/2)*FU,(y+(height*length/2)-4)*FU,FU,
		"NO PLAYERS!","FHTXT","center",flags,selcol)
	end
end

local function JoinBlacklist(p, self)
	if p == self then
		return true
	end
	if HasRequested(self, p) then
		return true
	end
	if not IsPlayerEligibleToRequest(self, p) then
		return true
	end

	return false
end

local function InviteBlacklist(p, self)
	if not HasRequested(self, p) then
		return true
	end

	return false
end

-- join
function JOIN:onSelect()
end

function JOIN:onUnselect()
end

function JOIN:canSwitchTo()
	return CanPlayerSeeMenus(self)
end

function JOIN:onAccept()
	if not CanPlayerSeeMenus(self) then return end

	local list = GetPlayerList(JoinBlacklist, self)

	if not list[self.heist.team.join_sel]
	or not list[self.heist.team.join_sel].valid then
		return
	end

	RequestJoin(self, list[self.heist.team.join_sel])
	S_StartSound(nil, sfx_strpst, self)

	if not CanPlayerSeeMenus(self) then
		SetState(self, 2)
	end
end

function JOIN:change(list, i)
	local last = self.heist.team.join_sel
	self.heist.team.join_sel = max(1, min($+i, #list))

	if last == self.heist.team.join_sel then return end

	local offset = self.heist.team.join_sel - self.heist.team.join_off

	if offset < 0 then
		self.heist.team.join_off = $+offset
	end

	if offset > JOIN_L then
		self.heist.team.join_off = $ + (offset-JOIN_L)
	end

	S_StartSound(nil, sfx_menu1, self)
end

function JOIN:tick(selected)
	if not CanPlayerSeeMenus(self) then
		if selected then
			SetState(self, 2)
		end

		return
	end
	if not selected then return end

	local x, y = FangsHeist.getPressDirection(self)
	local list = GetPlayerList(JoinBlacklist, self)

	if y then
		JOIN.change(self, list, y)
	end
end

function JOIN:draw(selected, v, c, transparency)
	if not CanPlayerSeeMenus(self) then return end
	local list = GetPlayerList(JoinBlacklist, self)
	local names = {}

	for _, p in ipairs(list) do
		table.insert(names, p.name)
	end

	DrawMenu(v,
		JOIN_X,
		JOIN_Y,
		JOIN_W,
		JOIN_H,
		JOIN_L,
		names,
		selected and self.heist.team.join_sel or 0,
		self.heist.team.join_off,
		JOIN_F|transparency)
	FH.DrawString(v,(JOIN_X+JOIN_W/2)*FU,(JOIN_Y - 8)*FU,FU,
	"Join Players","FHTXT","center",JOIN_F|transparency)
end

-- ready
function READY:onSelect()
end

function READY:onUnselect()
end

function READY:onAccept()
	S_StartSound(nil, sfx_strpst, self)
	return "waiting"
end

function READY:tick(selected)
end
FH.drawREADY = function(v,y,scale,patch,transparency,isready)
	v.drawScaled(READY_X*FU,y*FU,scale,patch,READY_F|transparency)
	if isready
		v.drawScaled(READY_X*FU+62*FU,y*FU,scale,v.cachePatch("FH_READYCHECK"),READY_F|transparency)
	end
end
function READY:draw(selected, v, c, transparency)
	--WAITING FOR THE NEW READY SPRITES!
	local color = nil
	local sel = "UNSELECT"
	if selected then
		READY_TICS = $+1
		local time = ease.linear(max(0,min(FixedDiv(READY_TICS,10),FU)),0,11)
		sel = (time&1) and "SELECT" or $
	else
		READY_TICS = 0
	end
	local patchname = "FH_READY"..sel
	local readyscale = ease.outback(max(0,min(FixedDiv(READY_TICS,10),FU)),tofixed("0.620"),FU)
	FH.drawREADY(v,READY_Y,readyscale,v.cachePatch(patchname),transparency)
	--FH.DrawString(v,READY_X*FU,READY_Y*FU,readyscale,"Ready","LTFNT","center",READY_F|transparency,color)
end


function REQUEST:onUnselect()
end

-- request
function REQUEST:onSelect()
end
function REQUEST:canSwitchTo()
	return CanPlayerSeeMenus(self)
end

function REQUEST:onAccept()
	if not CanPlayerSeeMenus(self) then return end

	local list = GetPlayerList(InviteBlacklist, self)

	if not list[self.heist.team.req_sel]
	or not list[self.heist.team.req_sel].valid then
		return
	end

	JoinTeam(self, list[self.heist.team.req_sel])
	S_StartSound(nil, sfx_strpst, self)

	if not CanPlayerSeeMenus(self) then
		SetState(self, 2)
	end
end

function REQUEST:change(list, i)
	local last = self.heist.team.req_sel
	self.heist.team.req_sel = max(1, min($+i, #list))

	if last == self.heist.team.req_sel then return end

	local offset = self.heist.team.req_sel - self.heist.team.req_off

	if offset < 0 then
		self.heist.team.req_off = $+offset
	end

	if offset > REQUEST_L then
		self.heist.team.req_off = $ + (offset-REQUEST_L)
	end

	S_StartSound(nil, sfx_menu1, self)
end

function REQUEST:tick(selected)
	if not CanPlayerSeeMenus(self) then
		if selected then
			SetState(self, 2)
		end

		return
	end
	if not selected then return end

	local x, y = FangsHeist.getPressDirection(self)
	local list = GetPlayerList(InviteBlacklist, self)

	if y then
		REQUEST.change(self, list, y)
	end
end

function REQUEST:draw(selected, v, c, transparency)
	if not CanPlayerSeeMenus(self) then return end
	local list = GetPlayerList(InviteBlacklist, self)
	local names = {}

	for _, p in ipairs(list) do
		table.insert(names, p.name)
	end

	DrawMenu(v,
		REQUEST_X,
		REQUEST_Y,
		REQUEST_W,
		REQUEST_H,
		REQUEST_L,
		names,
		selected and self.heist.team.req_sel or 0,
		self.heist.team.req_off,
		REQUEST_F|transparency)
	local duoortriobru = FangsHeist.getGamemode().name
	FH.DrawString(v,(REQUEST_X+REQUEST_W/2)*FU,(REQUEST_Y - 8)*FU,FU,
	duoortriobru.." Requests","FHTXT","center",REQUEST_F|transparency)
end

function state:enter()
	READY_TICS = 0

	self.heist.team = {}

	self.heist.team.join_sel = 1
	self.heist.team.join_off = 1

	self.heist.team.req_sel = 1
	self.heist.team.req_off = 1

	SetState(self, 2)
end

function state:exit()
	self.heist.team = nil
end

function state:tick()
	local x, y = FangsHeist.getPressDirection(self)
	local i = self.heist.team.state

	if self.heist.buttons & BT_JUMP
	and not (self.heist.lastbuttons & BT_JUMP)
	and STATES[i].onAccept then
		local result = STATES[i].onAccept(self)
		if result ~= nil then return result end
	end

	
	if self.heist.buttons & BT_SPIN
	and not (self.heist.lastbuttons & BT_SPIN) then
		S_StartSound(nil, sfx_alart, self)
		return "character"
	end
	local gamemode = FangsHeist.getGamemode()
	if gamemode.teamlimit >= 2
		if x
		and STATES[i+x] then
			SetState(self, i+x)
			S_StartSound(nil, sfx_menu1, self)
		end
	end
	for i = 1, #STATES do
		if not STATES[i].tick then
			continue
		end

		STATES[i].tick(self, i == self.heist.team.state)
	end
end
local function drawGamemodeInfo(v, y, flags)
	local gamemode = FangsHeist.getGamemode()
	local info = gamemode:info()
	local INFO_X = 160
	if not (info and #info) then return end

	for _, tbl in ipairs(info) do
		for i, info in ipairs(tbl) do
			local x,a,s,c,f = INFO_X,"center",FU,v.getStringColormap(V_YELLOWMAP),flags
			if i > 1 then
				c = nil
			else
				info = $:upper()
				local sw = v.width()/v.dupx()
				local rr = 10
				local ry = (y+3) - rr/2
				DrawRect(v, 0, ry, sw, rr, V_SNAPTOLEFT|f, v.getColormap(TC_BLINK, SKINCOLOR_LAVENDER))
			end
			FH.DrawString(v,x*FU,y*FU,s,info,"FHTXT",a,f,c)
			y = $+10
		end
	end
end
function state:draw(v, c, transparency)
	local gamemode = FangsHeist.getGamemode()
	if gamemode.teamlimit >= 2
		for i = 1, #STATES do
			if not STATES[i].draw then
				continue
			end
			STATES[i].draw(self, i == self.heist.team.state, v, c, transparency)
		end

		local team = self.heist:getTeam()
		local width = 0
		local _width = 0
		local y = 10*FU
		FH.DrawString(v,160*FU, y,FU, "Team:","FHTXT","center", V_SNAPTOTOP|transparency)
		y = $+10*FU
		for i, p in ipairs(team) do
			if not (p and p.valid) then continue end

			FH.DrawString(v,160*FU,y,FU, p.name,"FHTXT","center", V_SNAPTOTOP|transparency, v.getStringColormap(skincolors[p.skincolor].chatcolor))
			
			y = $+10*FU
		end
	else
		self.heist.team.state = 2 --Force them READY
		drawGamemodeInfo(v,50,V_SNAPTOTOP|transparency)
		STATES[2].draw(self, true, v, c, transparency)
	end
end

return state