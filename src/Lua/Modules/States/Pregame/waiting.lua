local state = {}

local INFO_X = 4
local INFO_INDENT = 6

state.ready = true

state.time_x = 0
state.time_y = FU

state.time_ox = 4*FU
state.time_oy = (0 - 12 - 4)*FU

local function DrawRoundInfo(v, y, flags)
	local gamemode = FangsHeist.getGamemode()
	local info = gamemode:info()

	if not (info and #info) then return end

	for _, tbl in ipairs(info) do
		for i, info in ipairs(tbl) do
			local x = INFO_X
			local f = flags|V_REDMAP

			if i > 1 then
				x = $ + INFO_INDENT
				f = ($|V_ALLOWLOWERCASE) & ~V_REDMAP
				info = "- "..$
			end
	
			v.drawString(x, y, info, f, "thin")
			y = $+10
		end
	end
end

function state:enter(last)
	self.heist.lastPregame = last
end

function state:exit()
	self.heist.lastPregame = nil
end

function state:tick()
	if self.heist.buttons & BT_SPIN
	and not (self.heist.lastbuttons & BT_SPIN) then
		S_StartSound(nil, sfx_alart, self)
		return self.heist.lastPregame
	end
end

function state:draw(v, c, transparency)
	--DrawRoundInfo(v, 4, V_SNAPTOTOP|V_SNAPTOLEFT|transparency)
	local team = self.heist:getTeam()
	local FH = FangsHeist
	local y = 10*FU
	FH.DrawString(v,160*FU, y,FU, "Team:","FHTXT","center", V_SNAPTOTOP|transparency)
	y = $+10*FU
	for i, p in ipairs(team) do
		if not (p and p.valid) then continue end

		FH.DrawString(v,160*FU,y,FU, p.name,"FHTXT","center", V_SNAPTOTOP|transparency, v.getStringColormap(skincolors[p.skincolor].chatcolor))
		
		y = $+10*FU
	end
	FH.DrawString(v,160*FU, 187*FU,FU, "Wating for Players...","FHTXT","center", V_SNAPTOBOTTOM|transparency, v.getStringColormap(V_YELLOWMAP))
end

return state