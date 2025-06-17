local state = {}

local READY = {}
local READY_X = 160 - 95/2
local READY_Y = 200 - 35 - 8
local READY_F = V_SNAPTOBOTTOM

local REQUEST_TEAM = {}

local JOIN_TEAMS = {}

local STATES = {REQUEST_TEAM, READY, JOIN_TEAMS}

local function IsPlayerValid(p)
	if not p
	or not p.valid
	or not p.heist
	or p.heist.spectator then
		return false
	end

	return true
end

local function IsTeamFull(team)
	local teamLength = FangsHeist.CVars.team_limit.value

	return #team >= teamLength
end

local function IsPlayerEligibleForTeam(p)
	if not IsPlayerValid(p) then
		return false
	end

	local teamLength = FangsHeist.CVars.team_limit.value
	local team = p.heist:getTeam()

	if #team >= teamLength then
		return false
	end

	return true
end

local function GetPlayerList(blacklist)
	local list = {}

	for i = 1, 32 do
		if not IsPlayerValid(players[i-1]) then
			continue
		end

		if blacklist
		and blacklist(players[i-1]) then
			continue
		end

		table.insert(list, players[i-1])
	end

	return list
end

local function SetState(p, i)
	if p.heist.team.state == i then
		return
	end

	local last = p.heist.team.state

	if last ~= nil
	and STATES[last].onUnselect then
		STATES[last].onUnselect(p)
	end
	if STATES[i].onSelect then
		STATES[i].onSelect(p)
	end

	p.heist.team.state = i
end

local function DrawMenu(v, x, y, width, height, items, selected, flags)
	local black = v.cachePatch("FH_BLACK")
	local length = 8
	local i = dispoffset-length+1
	local iter = 0

	for i = i, i+length do
		local str = items[i]

		local y = y + height*iter

		local color = SKINCOLOR_CORNFLOWER
		if i == selected
		and #items then
			color = SKINCOLOR_SKY
		end

		draw_rect(v, x*FU, y*FU, width*FU, height*FU, flags, color)
		iter = $+1

		if not str
		or not #items then continue end

		if #str > 16 then
			str = string.sub($, 1, 16)
		end
		
		v.drawString(x+4, y+4, str, flags|V_ALLOWLOWERCASE, "thin")
	end

	if not #items then
		v.drawString(x+width/2, y+(height/2)-4, "No players!", flags, "thin-center")
	end
end

-- states
function READY:onSelect()
end

function READY:onUnselect()
end

function READY:tick(selected)
end

function READY:draw(selected, v, c, transparency)
	local patch = v.cachePatch("FH_READYUNSELECT")
	if selected then
		patch = v.cachePatch("FH_READYSELECT")
	end

	v.draw(READY_X, READY_Y, patch, READY_F)
end

function state:enter()
	self.heist.team = {}

	SetState(self, 2)
end

function state:exit()
end

function state:tick()
	local x, y = FangsHeist.getPressDirection(self)
	local i = self.heist.team.state

	if x
	and STATES[i+x] then
		SetState(self, i+x)
		S_StartSound(nil, sfx_menu1, self)
	end
end

function state:draw(v, c, transparency)
	for i = 1, #STATES do
		if not STATES[i].draw then
			continue
		end

		STATES[i].draw(self, i == self.heist.team.state, v, c, transparency)
	end
end

return state